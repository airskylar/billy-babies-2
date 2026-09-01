import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime modules do not depend on the active game', () {
    final packageRoot = Directory.current.absolute;
    final runtimeRoot = Directory.fromUri(
      packageRoot.uri.resolve('lib/runtime/'),
    );
    final gameRoot = packageRoot.uri.resolve('lib/game/');
    final directives = RegExp(
      r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    final violations = <String>[];
    final runtimeFiles =
        runtimeRoot
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));

    for (final file in runtimeFiles) {
      final source = file.readAsStringSync();
      for (final match in directives.allMatches(source)) {
        final importUri = match.group(1)!;
        final target = switch (importUri) {
          final uri when uri.startsWith('package:coreflame/') =>
            packageRoot.uri.resolve(
              'lib/${uri.substring('package:coreflame/'.length)}',
            ),
          final uri when Uri.parse(uri).scheme.isEmpty => file.uri.resolve(uri),
          _ => null,
        };
        if (target != null &&
            target.toString().startsWith(gameRoot.toString())) {
          violations.add(
            '${file.path.substring(packageRoot.path.length + 1)} imports '
            '$importUri',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Reusable runtime code must not import the active game:\n'
          '${violations.join('\n')}',
    );
  });
}
