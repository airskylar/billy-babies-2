import 'package:coreflame/game/scenarios/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scenario IDs and launcher entries come from the enum catalog', () {
    expect(
      GameScenario.values.map((scenario) => scenario.launcherEntry.id),
      GameScenario.values.map((scenario) => scenario.id),
    );
  });

  test('catalog exposes only the non-playable foundation shell', () {
    expect(GameScenario.values, [GameScenario.shell]);
    expect(GameScenario.findById('shell.default'), GameScenario.shell);
    expect(GameScenario.findById('missing'), isNull);
  });
}
