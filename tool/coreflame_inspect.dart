import 'dart:convert';
import 'dart:io';

import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> arguments) async {
  try {
    final invocation = _Invocation.parse(arguments);
    if (invocation.command == 'help') {
      stdout.writeln(_usage);
      return;
    }

    final serviceUrl =
        invocation.options['uri'] ??
        Platform.environment['COREFLAME_VM_SERVICE_URL'];
    if (serviceUrl == null) {
      throw const FormatException(
        'Provide --uri or set COREFLAME_VM_SERVICE_URL',
      );
    }

    final call = invocation.serviceCall;
    final webSocketUrl = convertToWebSocketUrl(
      serviceProtocolUrl: Uri.parse(serviceUrl),
    );
    final service = await vmServiceConnectUri(webSocketUrl.toString());
    try {
      final isolateId = await _findIsolate(
        service,
        call.extension,
        invocation.options['isolate'],
      );
      final response = await service.callServiceExtension(
        call.extension,
        isolateId: isolateId,
        args: call.arguments,
      );
      if (call.cleanupExtension case final cleanupExtension?) {
        await service.callServiceExtension(
          cleanupExtension,
          isolateId: isolateId,
          args: call.cleanupArguments,
        );
      }
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(response.json ?? const {}),
      );
    } finally {
      await service.dispose();
    }
  } on FormatException catch (error) {
    stderr.writeln('coreflame_inspect: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  } on RPCError catch (error) {
    stderr.writeln('coreflame_inspect: $error');
    exitCode = 1;
  } on SocketException catch (error) {
    stderr.writeln('coreflame_inspect: ${error.message}');
    exitCode = 1;
  }
}

Future<String> _findIsolate(
  VmService service,
  String requiredExtension,
  String? requestedIsolate,
) async {
  final vm = await service.getVM();
  for (final isolateRef in vm.isolates ?? const <IsolateRef>[]) {
    final id = isolateRef.id;
    if (id == null) continue;
    if (requestedIsolate != null &&
        requestedIsolate != id &&
        requestedIsolate != isolateRef.name) {
      continue;
    }
    final isolate = await service.getIsolate(id);
    if (isolate.extensionRPCs?.contains(requiredExtension) ?? false) {
      return id;
    }
  }

  final qualifier = requestedIsolate == null
      ? ''
      : ' in isolate "$requestedIsolate"';
  throw FormatException(
    'No isolate$qualifier exposes $requiredExtension. '
    'Run Coreflame in debug mode and wait for the game to attach.',
  );
}

class _ServiceCall {
  const _ServiceCall(
    this.extension, [
    this.arguments = const {},
    this.cleanupExtension,
    this.cleanupArguments = const {},
  ]);

  final String extension;
  final Map<String, dynamic> arguments;
  final String? cleanupExtension;
  final Map<String, dynamic> cleanupArguments;
}

class _Invocation {
  const _Invocation({
    required this.command,
    required this.positionals,
    required this.options,
  });

  final String command;
  final List<String> positionals;
  final Map<String, String> options;

  static _Invocation parse(List<String> arguments) {
    if (arguments.isEmpty || arguments.first == '--help') {
      return const _Invocation(command: 'help', positionals: [], options: {});
    }

    final command = arguments.first;
    final positionals = <String>[];
    final options = <String, String>{};
    for (var index = 1; index < arguments.length; index += 1) {
      final argument = arguments[index];
      if (!argument.startsWith('--')) {
        positionals.add(argument);
        continue;
      }
      final name = argument.substring(2);
      if (name.isEmpty || index + 1 >= arguments.length) {
        throw FormatException('Missing value for $argument');
      }
      final value = arguments[index + 1];
      if (value.startsWith('--')) {
        throw FormatException('Missing value for $argument');
      }
      if (options.containsKey(name)) {
        throw FormatException('Duplicate option: $argument');
      }
      options[name] = value;
      index += 1;
    }

    final invocation = _Invocation(
      command: command,
      positionals: List.unmodifiable(positionals),
      options: Map.unmodifiable(options),
    );
    invocation._validateCommonOptions();
    return invocation;
  }

  _ServiceCall get serviceCall => switch (command) {
    'capabilities' => _capabilitiesCall(),
    'snapshot' => _snapshotCall(),
    'events' => _eventsCall(),
    'dispatch' => _dispatchCall(),
    'tree' => _treeCall(),
    'widget-tree' => _widgetTreeCall(),
    'pause' => _pausedCall(true),
    'resume' => _pausedCall(false),
    'step' => _stepCall(),
    _ => throw FormatException('Unknown command: $command'),
  };

  _ServiceCall _capabilitiesCall() {
    _expectPositionals(0);
    _expectOptions(const {'uri', 'isolate'});
    return const _ServiceCall('ext.coreflame.getCapabilities');
  }

  _ServiceCall _snapshotCall() {
    _expectPositionals(0);
    _expectOptions(const {'uri', 'isolate', 'detail'});
    final detail = options['detail'] ?? 'semantic';
    if (detail != 'semantic' && detail != 'visual') {
      throw FormatException('Unknown snapshot detail: $detail');
    }
    return _ServiceCall('ext.coreflame.getSnapshot', {'detail': detail});
  }

  _ServiceCall _eventsCall() {
    _expectPositionals(0);
    _expectOptions(const {'uri', 'isolate', 'after'});
    final after = _nonNegativeIntegerOption('after') ?? 0;
    return _ServiceCall('ext.coreflame.getEvents', {'after': after});
  }

  _ServiceCall _dispatchCall() {
    _expectAtLeastPositionals(1);
    _expectOptions(const {'uri', 'isolate', 'expected-revision'});
    final commandName = positionals.first;
    final arguments = <String, dynamic>{'command': commandName};
    if (options['expected-revision'] case final revision?) {
      final parsed = int.tryParse(revision);
      if (parsed == null || parsed < 0) {
        throw const FormatException(
          'Expected --expected-revision to be a non-negative integer',
        );
      }
      arguments['expected_revision'] = parsed;
    }

    for (final argument in positionals.skip(1)) {
      final separator = argument.indexOf('=');
      if (separator <= 0) {
        throw FormatException(
          'Command arguments must use NAME=VALUE: $argument',
        );
      }
      final name = argument.substring(0, separator);
      final value = argument.substring(separator + 1);
      if (name == 'command' || name == 'expected_revision') {
        throw FormatException('Reserved command argument: $name');
      }
      if (arguments.containsKey(name)) {
        throw FormatException('Duplicate command argument: $name');
      }
      arguments[name] = value;
    }
    return _ServiceCall('ext.coreflame.dispatch', arguments);
  }

  _ServiceCall _treeCall() {
    _expectPositionals(0);
    _expectOptions(const {'uri', 'isolate'});
    return const _ServiceCall('ext.flame_devtools.getComponentTree');
  }

  _ServiceCall _widgetTreeCall() {
    _expectPositionals(0);
    _expectOptions(const {'uri', 'isolate'});
    final objectGroup =
        'coreflame-inspect-${DateTime.now().microsecondsSinceEpoch}';
    return _ServiceCall(
      'ext.flutter.inspector.getRootWidgetSummaryTree',
      {'objectGroup': objectGroup},
      'ext.flutter.inspector.disposeGroup',
      {'objectGroup': objectGroup},
    );
  }

  _ServiceCall _pausedCall(bool paused) {
    _expectPositionals(0);
    _expectOptions(const {'uri', 'isolate'});
    return _ServiceCall('ext.flame_devtools.setPaused', {'paused': paused});
  }

  _ServiceCall _stepCall() {
    _expectPositionals(0);
    _expectOptions(const {'uri', 'isolate', 'seconds'});
    final rawSeconds = options['seconds'] ?? '${1 / 60}';
    final seconds = double.tryParse(rawSeconds);
    if (seconds == null || !seconds.isFinite || seconds < 0) {
      throw const FormatException(
        'Expected --seconds to be a finite non-negative number',
      );
    }
    return _ServiceCall('ext.flame_devtools.step', {'step_time': seconds});
  }

  int? _nonNegativeIntegerOption(String name) {
    final value = options[name];
    if (value == null) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      throw FormatException('Expected --$name to be a non-negative integer');
    }
    return parsed;
  }

  void _validateCommonOptions() {
    if (options['uri'] case final value?) {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme) {
        throw const FormatException('--uri must be an absolute URI');
      }
    }
  }

  void _expectPositionals(int count) {
    if (positionals.length != count) {
      throw FormatException(
        '$command expects $count positional argument(s), '
        'received ${positionals.length}',
      );
    }
  }

  void _expectAtLeastPositionals(int count) {
    if (positionals.length < count) {
      throw FormatException(
        '$command expects at least $count positional argument(s), '
        'received ${positionals.length}',
      );
    }
  }

  void _expectOptions(Set<String> allowed) {
    final unexpected = options.keys
        .where((option) => !allowed.contains(option))
        .toList(growable: false);
    if (unexpected.isNotEmpty) {
      throw FormatException(
        'Unexpected option(s): ${unexpected.map((key) => '--$key').join(', ')}',
      );
    }
  }
}

const _usage = '''
Usage:
  dart run tool/coreflame_inspect.dart capabilities --uri URL
  dart run tool/coreflame_inspect.dart snapshot [--detail semantic|visual] --uri URL
  dart run tool/coreflame_inspect.dart events [--after SEQUENCE] --uri URL
  dart run tool/coreflame_inspect.dart dispatch COMMAND [NAME=VALUE ...]
    [--expected-revision REVISION] --uri URL
  dart run tool/coreflame_inspect.dart tree|widget-tree --uri URL
  dart run tool/coreflame_inspect.dart pause|resume --uri URL
  dart run tool/coreflame_inspect.dart step [--seconds NUMBER] --uri URL

Use capabilities to discover the active game's commands and their parameters.
Command arguments use NAME=VALUE and remain game-defined. Set
COREFLAME_VM_SERVICE_URL instead of passing --uri on every call. Use --isolate
with an isolate ID or name when the VM contains multiple matching isolates.
''';
