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
    _expectPositionals(1);
    final action = positionals.single;
    final arguments = <String, dynamic>{};
    if (options['expected-revision'] case final revision?) {
      final parsed = int.tryParse(revision);
      if (parsed == null || parsed < 0) {
        throw const FormatException(
          'Expected --expected-revision to be a non-negative integer',
        );
      }
      arguments['expected_revision'] = parsed;
    }

    switch (action) {
      case 'play-cell':
        _expectOptions(const {'uri', 'isolate', 'expected-revision', 'cell'});
        arguments['command'] = 'playCell';
        arguments['cell'] = _requiredIntegerOption('cell');
      case 'start-next-round':
        _expectOptions(const {'uri', 'isolate', 'expected-revision'});
        arguments['command'] = 'startNextRound';
      case 'reset-match':
        _expectOptions(const {'uri', 'isolate', 'expected-revision'});
        arguments['command'] = 'resetMatch';
      case 'open-settings':
      case 'close-settings':
        _expectOptions(const {'uri', 'isolate', 'expected-revision'});
        arguments['command'] = 'setSettingsOpen';
        arguments['open'] = action == 'open-settings';
      case 'set-sound':
      case 'set-music':
      case 'set-vibration':
        _expectOptions(const {
          'uri',
          'isolate',
          'expected-revision',
          'enabled',
        });
        arguments['command'] = 'setFeedbackSetting';
        arguments['setting'] = action.substring('set-'.length);
        arguments['enabled'] = _requiredBooleanOption('enabled');
      default:
        throw FormatException('Unknown dispatch action: $action');
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

  int _requiredIntegerOption(String name) {
    final value = options[name];
    final parsed = value == null ? null : int.tryParse(value);
    if (parsed == null) {
      throw FormatException('Expected --$name to be an integer');
    }
    return parsed;
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

  bool _requiredBooleanOption(String name) {
    return switch (options[name]) {
      'true' => true,
      'false' => false,
      _ => throw FormatException('Expected --$name to be true or false'),
    };
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
  dart run tool/coreflame_inspect.dart snapshot [--detail semantic|visual] --uri URL
  dart run tool/coreflame_inspect.dart events [--after SEQUENCE] --uri URL
  dart run tool/coreflame_inspect.dart dispatch ACTION [options] --uri URL
  dart run tool/coreflame_inspect.dart tree|widget-tree --uri URL
  dart run tool/coreflame_inspect.dart pause|resume --uri URL
  dart run tool/coreflame_inspect.dart step [--seconds NUMBER] --uri URL

Dispatch actions:
  play-cell --cell INDEX
  start-next-round
  reset-match
  open-settings
  close-settings
  set-sound|set-music|set-vibration --enabled true|false

All dispatch actions accept --expected-revision REVISION. Set
COREFLAME_VM_SERVICE_URL instead of passing --uri on every call. Use --isolate
with an isolate ID or name when the VM contains multiple matching isolates.
''';
