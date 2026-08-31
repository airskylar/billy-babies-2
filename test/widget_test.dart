import 'package:coreflame/game/coreflame_game.dart';
import 'package:coreflame/game/services/fake_game_platform_services.dart';
import 'package:coreflame/game/services/game_platform_services.dart';
import 'package:coreflame/game/tic_tac_toe_match.dart';
import 'package:coreflame/main.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('hosts the Flame game without owning injected services', (
    tester,
  ) async {
    final gameServices = FakeGamePlatformServices();

    await tester.pumpWidget(CoreflameApp(gameServices: gameServices));
    await tester.pump();

    expect(find.byType(GameWidget<CoreflameGame>), findsOneWidget);
    expect(gameServices.isAuthenticated, isTrue);
    expect(
      gameServices.calls.map((call) => call.operation),
      contains(GameServiceOperation.authenticate),
    );
    expect(find.byTooltip('Open scenarios'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(gameServices.isDisposed, isFalse);
  });

  testWidgets('launches, restarts, and clears a scenario with fresh games', (
    tester,
  ) async {
    final gameServices = FakeGamePlatformServices();
    await tester.pumpWidget(CoreflameApp(gameServices: gameServices));
    await tester.pump();
    final normalGame = _currentGame(tester);

    await tester.tap(find.byTooltip('Open scenarios'));
    await tester.pumpAndSettle();
    expect(find.text('Scenarios'), findsOneWidget);

    await tester.tap(find.text('X about to win'));
    await tester.pumpAndSettle();
    final scenarioGame = _currentGame(tester);
    expect(scenarioGame, isNot(same(normalGame)));
    expect(scenarioGame.platformServices, same(gameServices));
    expect(scenarioGame.match.turn, Mark.x);
    expect(scenarioGame.match.markAt(0), Mark.x);
    expect(scenarioGame.match.markAt(2), isNull);

    await tester.tap(find.byTooltip('Open scenarios'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('state-launcher-restart')));
    await tester.pumpAndSettle();
    final restartedGame = _currentGame(tester);
    expect(restartedGame, isNot(same(scenarioGame)));
    expect(restartedGame.match.markAt(0), Mark.x);

    await tester.tap(find.byTooltip('Open scenarios'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('state-launcher-clear')));
    await tester.pump();
    final clearedGame = _currentGame(tester);
    expect(clearedGame, isNot(same(restartedGame)));
    expect(clearedGame.match.cells, everyElement(isNull));
  });

  testWidgets('opens the launcher with a mobile three-finger upward swipe', (
    tester,
  ) async {
    final gameServices = FakeGamePlatformServices();
    await tester.pumpWidget(CoreflameApp(gameServices: gameServices));
    await tester.pump();

    final gestures = <TestGesture>[];
    for (var index = 0; index < 3; index += 1) {
      final gesture = await tester.createGesture(
        pointer: index + 1,
        kind: PointerDeviceKind.touch,
      );
      gestures.add(gesture);
      await gesture.down(Offset(120 + (index * 24), 300));
    }
    for (var index = 0; index < gestures.length; index += 1) {
      await gestures[index].moveTo(Offset(120 + (index * 24), 220));
    }
    for (final gesture in gestures) {
      await gesture.up();
    }
    await tester.pumpAndSettle();

    expect(find.text('Scenarios'), findsOneWidget);
  });
}

CoreflameGame _currentGame(WidgetTester tester) => tester
    .widget<GameWidget<CoreflameGame>>(find.byType(GameWidget<CoreflameGame>))
    .game!;
