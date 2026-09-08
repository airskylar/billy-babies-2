import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:state_launcher_flutter/state_launcher_flutter.dart';

import '../game/domain/prototype_session.dart';
import '../game/game_root.dart';
import '../game/scenarios/catalog.dart';
import '../game/theme/game_palette.dart';
import '../runtime/inspection/inspection_surface.dart';

const _scenarioLauncherEnabled = bool.fromEnvironment(
  'STATE_LAUNCHER_ENABLED',
  defaultValue: !kReleaseMode,
);
const _initialScenarioId = String.fromEnvironment('STATE_LAUNCHER_SCENARIO');

Future<String?> showScenarioLauncher(BuildContext context) {
  final host = context.getInheritedWidgetOfExactType<_ScenarioLauncherHost>();
  if (host == null) {
    throw StateError('No enabled scenario launcher exists above this context.');
  }
  return host.showLauncher();
}

class CoreflameApp extends StatelessWidget {
  const CoreflameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billy Babies Duel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DuelPalette.violet,
          surface: DuelPalette.panel,
        ),
        scaffoldBackgroundColor: DuelPalette.canvas,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BillyBabiesGame _game;
  late final StateLauncherController _scenarioLauncher;
  var _gameGeneration = 0;
  var _safePadding = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    final initialScenario = _resolveInitialScenario();
    _game = _createGame(initialScenario);
    _scenarioLauncher = StateLauncherController(
      entries: [
        for (final scenario in GameScenario.values) scenario.launcherEntry,
      ],
      activeEntryId: initialScenario?.id,
      onLaunch: (entry) {
        final scenario = GameScenario.findById(entry.id);
        if (scenario == null) {
          throw StateError('Unknown game scenario: ${entry.id}');
        }
        _replaceGame(_createGame(scenario));
      },
      onClear: () => _replaceGame(_createGame(null)),
    );
  }

  @override
  void dispose() {
    _scenarioLauncher.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _safePadding = _safePaddingFor(MediaQuery.of(context));
    _game.safePadding = _safePadding;
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      body: InspectableGameSurface<BillyBabiesGame>(
        key: ValueKey(_gameGeneration),
        game: _game,
      ),
    );
    if (!_scenarioLauncherEnabled) return scaffold;
    return _ScenarioLauncherHost(
      showLauncher: _showScenarioLauncher,
      child: StateLauncherTrigger(
        onOpen: () => unawaited(_showScenarioLauncher()),
        child: scaffold,
      ),
    );
  }

  GameScenario? _resolveInitialScenario() {
    if (!_scenarioLauncherEnabled || _initialScenarioId.isEmpty) return null;
    final scenario = GameScenario.findById(_initialScenarioId);
    if (scenario == null) {
      throw ArgumentError.value(
        _initialScenarioId,
        'STATE_LAUNCHER_SCENARIO',
        'No game scenario has this ID.',
      );
    }
    return scenario;
  }

  BillyBabiesGame _createGame(GameScenario? scenario) =>
      BillyBabiesGame(session: DuelPrototypeSession(scenarioId: scenario?.id));

  void _replaceGame(BillyBabiesGame game) {
    game.safePadding = _safePadding;
    setState(() {
      _game = game;
      _gameGeneration += 1;
    });
  }

  Future<String?> _showScenarioLauncher() =>
      showStateLauncher(context: context, controller: _scenarioLauncher);
}

class _ScenarioLauncherHost extends InheritedWidget {
  const _ScenarioLauncherHost({
    required this.showLauncher,
    required super.child,
  });

  final Future<String?> Function() showLauncher;

  @override
  bool updateShouldNotify(_ScenarioLauncherHost oldWidget) => false;
}

EdgeInsets _safePaddingFor(MediaQueryData mediaQuery) {
  var safePadding = mediaQuery.viewPadding;

  for (final feature in mediaQuery.displayFeatures) {
    if (feature.type != DisplayFeatureType.cutout || feature.bounds.isEmpty) {
      continue;
    }

    final bounds = feature.bounds;
    final distances = <double>[
      bounds.top,
      mediaQuery.size.width - bounds.right,
      mediaQuery.size.height - bounds.bottom,
      bounds.left,
    ];
    final nearestEdge = distances.indexOf(distances.reduce(math.min));

    safePadding = switch (nearestEdge) {
      0 => safePadding.copyWith(top: math.max(safePadding.top, bounds.bottom)),
      1 => safePadding.copyWith(
        right: math.max(safePadding.right, mediaQuery.size.width - bounds.left),
      ),
      2 => safePadding.copyWith(
        bottom: math.max(
          safePadding.bottom,
          mediaQuery.size.height - bounds.top,
        ),
      ),
      _ => safePadding.copyWith(left: math.max(safePadding.left, bounds.right)),
    };
  }

  return safePadding;
}
