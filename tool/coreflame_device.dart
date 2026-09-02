import 'dart:convert';
import 'dart:io';

const _usage = '''
Coreflame device and migration utilities

Usage:
  dart run tool/coreflame_device.dart devices
  dart run tool/coreflame_device.dart install --device DEVICE_ID
  dart run tool/coreflame_device.dart screenshot --platform ios|android --device DEVICE_ID --out FILE.png
  dart run tool/coreflame_device.dart icons --source SOURCE.png
  dart run tool/coreflame_device.dart doctor
''';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty ||
      arguments.first == '--help' ||
      arguments.first == '-h') {
    stdout.write(_usage);
    return;
  }

  try {
    final options = _Options(arguments.skip(1));
    switch (arguments.first) {
      case 'devices':
        options.rejectAll();
        exitCode = await _runInherited('flutter', const [
          'devices',
          '--machine',
        ]);
      case 'install':
        final device = options.require('device');
        options.rejectAll();
        exitCode = await _runInherited('flutter', ['install', '-d', device]);
      case 'screenshot':
        final platform = options.require('platform');
        final device = options.require('device');
        final output = options.require('out');
        options.rejectAll();
        await _captureScreenshot(
          platform: platform,
          device: device,
          output: output,
        );
      case 'icons':
        final source = options.require('source');
        options.rejectAll();
        await _generateIcons(source);
      case 'doctor':
        options.rejectAll();
        exitCode = await _doctor() ? 0 : 1;
      default:
        throw FormatException('Unknown command: ${arguments.first}');
    }
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.write(_usage);
    exitCode = 64;
  } on ProcessException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

Future<void> _captureScreenshot({
  required String platform,
  required String device,
  required String output,
}) async {
  final file = File(output);
  await file.parent.create(recursive: true);
  switch (platform) {
    case 'ios':
      final result = await Process.run('xcrun', [
        'simctl',
        'io',
        device,
        'screenshot',
        file.path,
      ]);
      _forwardResult(result);
      if (result.exitCode != 0) exitCode = result.exitCode;
    case 'android':
      final process = await Process.start('adb', [
        '-s',
        device,
        'exec-out',
        'screencap',
        '-p',
      ]);
      final sink = file.openWrite();
      await process.stdout.pipe(sink);
      await stderr.addStream(process.stderr);
      final result = await process.exitCode;
      if (result != 0) {
        await file.delete().catchError((_) => file);
        exitCode = result;
      }
    default:
      throw FormatException('Platform must be ios or android');
  }
  if (exitCode == 0) stdout.writeln(file.path);
}

Future<void> _generateIcons(String sourcePath) async {
  if (!Platform.isMacOS) {
    throw const FormatException(
      'Icon generation currently requires macOS sips',
    );
  }
  final source = File(sourcePath);
  if (!source.existsSync()) {
    throw FormatException('Icon source does not exist: $sourcePath');
  }
  final dimensions = await Process.run('sips', [
    '-g',
    'format',
    '-g',
    'pixelWidth',
    '-g',
    'pixelHeight',
    source.path,
  ]);
  if (dimensions.exitCode != 0) {
    _forwardResult(dimensions);
    throw const FormatException('Could not inspect the icon source');
  }
  final description = dimensions.stdout as String;
  if (!RegExp(r'format:\s+png', caseSensitive: false).hasMatch(description)) {
    throw const FormatException('Icon source must be a PNG');
  }
  final values = RegExp(r'pixel(?:Width|Height):\s+(\d+)')
      .allMatches(description)
      .map((match) => int.parse(match.group(1)!))
      .toList(growable: false);
  if (values.length != 2 || values[0] != values[1] || values[0] < 1024) {
    throw const FormatException(
      'Icon source must be a square PNG at least 1024×1024',
    );
  }

  const androidSizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  for (final entry in androidSizes.entries) {
    await _resizeIcon(
      source.path,
      'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      entry.value,
    );
  }

  final catalog = File(
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
  );
  final contents =
      jsonDecode(await catalog.readAsString()) as Map<String, Object?>;
  final images = contents['images'] as List<Object?>;
  for (final item in images.cast<Map<String, Object?>>()) {
    final filename = item['filename'];
    final size = item['size'];
    final scale = item['scale'];
    if (filename is! String || size is! String || scale is! String) continue;
    final points = double.parse(size.split('x').first);
    final multiplier = double.parse(scale.replaceAll('x', ''));
    await _resizeIcon(
      source.path,
      '${catalog.parent.path}/$filename',
      (points * multiplier).round(),
    );
  }
  stdout.writeln('Updated Android and iOS launcher icons.');
}

Future<void> _resizeIcon(String source, String output, int size) async {
  final result = await Process.run('sips', [
    '-z',
    '$size',
    '$size',
    source,
    '--out',
    output,
  ]);
  if (result.exitCode != 0) {
    _forwardResult(result);
    throw FormatException('Failed to create $output');
  }
}

Future<bool> _doctor() async {
  var healthy = true;
  for (final tool in const ['flutter', 'xcrun', 'adb', 'sips']) {
    final result = await Process.run('which', [tool]);
    final available = result.exitCode == 0;
    stdout.writeln('${available ? '✓' : '✗'} $tool');
    healthy = healthy && available;
  }
  return healthy;
}

Future<int> _runInherited(String executable, List<String> arguments) async {
  final process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

void _forwardResult(ProcessResult result) {
  if ((result.stdout as String).isNotEmpty) stdout.write(result.stdout);
  if ((result.stderr as String).isNotEmpty) stderr.write(result.stderr);
}

final class _Options {
  _Options(Iterable<String> arguments) {
    final values = arguments.toList(growable: false);
    for (var index = 0; index < values.length; index += 1) {
      final option = values[index];
      if (!option.startsWith('--')) {
        throw FormatException('Unexpected argument: $option');
      }
      if (index + 1 >= values.length || values[index + 1].startsWith('--')) {
        throw FormatException('Missing value for $option');
      }
      final name = option.substring(2);
      if (_values.containsKey(name)) {
        throw FormatException('Duplicate option: $option');
      }
      _values[name] = values[++index];
    }
  }

  final Map<String, String> _values = {};

  String require(String name) {
    final value = _values.remove(name);
    if (value == null) throw FormatException('Missing --$name');
    return value;
  }

  void rejectAll() {
    if (_values.isNotEmpty) {
      throw FormatException(
        'Unexpected option(s): ${_values.keys.map((key) => '--$key').join(', ')}',
      );
    }
  }
}
