import 'package:coreflame/app/coreflame_app.dart';
import 'package:coreflame/game/domain/prototype_session.dart';
import 'package:coreflame/game/game_root.dart';
import 'package:coreflame/runtime/inspection/inspection_surface.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hosts the non-playable Billy Babies Flame shell', (
    tester,
  ) async {
    await tester.pumpWidget(const CoreflameApp());
    await tester.pump();

    final game = _currentGame(tester);
    expect(
      find.byType(InspectableGameSurface<BillyBabiesGame>),
      findsOneWidget,
    );
    expect(game.session.status, DuelPrototypeStatus.setupNotStarted);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(game.isRemoved, isTrue);
  });

  testWidgets('propagates safe padding into the game root', (tester) async {
    const padding = EdgeInsets.fromLTRB(10, 20, 30, 40);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(800, 400), viewPadding: padding),
          child: GameScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(_currentGame(tester).safePadding, padding);
  });

  testWidgets('launches, restarts, and clears with fresh game roots', (
    tester,
  ) async {
    await tester.pumpWidget(const CoreflameApp());
    await tester.pump();
    final normalGame = _currentGame(tester);

    await _openLauncherWithGesture(tester);
    await tester.tap(find.text('Duel shell'));
    await _pumpTransition(tester);
    final scenarioGame = _currentGame(tester);
    expect(scenarioGame, isNot(same(normalGame)));
    expect(normalGame.isRemoved, isTrue);
    expect(scenarioGame.session.scenarioId, 'shell.default');

    await _openLauncherWithGesture(tester);
    await tester.tap(find.byKey(const ValueKey('state-launcher-restart')));
    await _pumpTransition(tester);
    final restartedGame = _currentGame(tester);
    expect(restartedGame, isNot(same(scenarioGame)));
    expect(scenarioGame.isRemoved, isTrue);
    expect(restartedGame.session.scenarioId, 'shell.default');

    await _openLauncherWithGesture(tester);
    await tester.tap(find.byKey(const ValueKey('state-launcher-clear')));
    await tester.pump();
    final clearedGame = _currentGame(tester);
    expect(clearedGame, isNot(same(restartedGame)));
    expect(restartedGame.isRemoved, isTrue);
    expect(clearedGame.session.scenarioId, isNull);
  });

  testWidgets('survives background and resume lifecycle transitions', (
    tester,
  ) async {
    await tester.pumpWidget(const CoreflameApp());
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(_currentGame(tester).isRemoved, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the launcher through the public function', (tester) async {
    await tester.pumpWidget(const CoreflameApp());
    await tester.pump();

    final gameContext = tester.element(
      find.byType(InspectableGameSurface<BillyBabiesGame>),
    );
    final result = showScenarioLauncher(gameContext);
    await _pumpTransition(tester);

    expect(find.text('Scenarios'), findsOneWidget);

    Navigator.of(gameContext).pop();
    await _pumpTransition(tester);
    expect(await result, isNull);
  });
}

BillyBabiesGame _currentGame(WidgetTester tester) => tester
    .widget<InspectableGameSurface<BillyBabiesGame>>(
      find.byType(InspectableGameSurface<BillyBabiesGame>),
    )
    .game;

Future<void> _openLauncherWithGesture(WidgetTester tester) async {
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
  await _pumpTransition(tester);
}

Future<void> _pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
