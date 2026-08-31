import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show DisplayFeatureType;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:state_launcher_flutter/state_launcher_flutter.dart';

import 'game/coreflame_game.dart';
import 'game/services/coreflame_game_services_config.dart';
import 'game/services/game_platform_services.dart';
import 'game/services/mobile_game_platform_services.dart';
import 'game/theme/game_palette.dart';
import 'scenarios/coreflame_scenario.dart';

const _scenarioLauncherEnabled = bool.fromEnvironment(
  'COREFLAME_SCENARIOS',
  defaultValue: !kReleaseMode,
);
const _initialScenarioId = String.fromEnvironment('COREFLAME_SCENARIO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CoreflameApp());
}

class CoreflameApp extends StatelessWidget {
  const CoreflameApp({super.key, this.gameServices});

  final GamePlatformServices? gameServices;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coreflame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Gluten',
        colorScheme: ColorScheme.fromSeed(
          seedColor: GamePalette.berry,
          surface: GamePalette.cream,
        ),
        scaffoldBackgroundColor: GamePalette.cream,
      ),
      home: CoreflameGameScreen(gameServices: gameServices),
    );
  }
}

class CoreflameGameScreen extends StatefulWidget {
  const CoreflameGameScreen({super.key, this.gameServices});

  final GamePlatformServices? gameServices;

  @override
  State<CoreflameGameScreen> createState() => _CoreflameGameScreenState();
}

class _CoreflameGameScreenState extends State<CoreflameGameScreen> {
  late final bool _ownsGameServices;
  late final GamePlatformServices _gameServices;
  late CoreflameGame _game;
  late final StateLauncherController _scenarioLauncher;
  var _gameGeneration = 0;
  var _safePadding = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    final injectedGameServices = widget.gameServices;
    _ownsGameServices = injectedGameServices == null;
    _gameServices =
        injectedGameServices ??
        MobileGamePlatformServices(
          configuration: coreflameGameServicesConfiguration,
        );
    final initialScenario = _resolveInitialScenario();
    _game = _createGame(initialScenario);
    _scenarioLauncher = StateLauncherController(
      entries: [
        for (final scenario in CoreflameScenario.values) scenario.launcherEntry,
      ],
      activeEntryId: initialScenario?.id,
      onLaunch: (entry) {
        final scenario = CoreflameScenario.findById(entry.id);
        if (scenario == null) {
          throw StateError('Unknown Coreflame scenario: ${entry.id}');
        }
        _replaceGame(_createGame(scenario));
      },
      onClear: () => _replaceGame(_createGame(null)),
    );

    if (_gameServices.capabilities.contains(
      GameServiceCapability.authentication,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_gameServices.authenticate());
      });
    }
  }

  @override
  void dispose() {
    _scenarioLauncher.dispose();
    if (_ownsGameServices) unawaited(_gameServices.dispose());
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
      body: GameWidget<CoreflameGame>(
        key: ValueKey(_gameGeneration),
        game: _game,
      ),
      floatingActionButton: _scenarioLauncherEnabled
          ? FloatingActionButton.small(
              key: const ValueKey('open-scenario-launcher'),
              tooltip: 'Open scenarios',
              onPressed: _openScenarioLauncher,
              child: const Icon(Icons.developer_mode),
            )
          : null,
    );
    if (!_scenarioLauncherEnabled) return scaffold;
    return StateLauncherTrigger(onOpen: _openScenarioLauncher, child: scaffold);
  }

  CoreflameScenario? _resolveInitialScenario() {
    if (!_scenarioLauncherEnabled || _initialScenarioId.isEmpty) return null;
    final scenario = CoreflameScenario.findById(_initialScenarioId);
    if (scenario == null) {
      throw ArgumentError.value(
        _initialScenarioId,
        'COREFLAME_SCENARIO',
        'No Coreflame scenario has this ID.',
      );
    }
    return scenario;
  }

  CoreflameGame _createGame(CoreflameScenario? scenario) => CoreflameGame(
    platformServices: _gameServices,
    match: scenario?.createMatch(),
  );

  void _replaceGame(CoreflameGame game) {
    game.safePadding = _safePadding;
    setState(() {
      _game = game;
      _gameGeneration += 1;
    });
  }

  void _openScenarioLauncher() {
    unawaited(
      showStateLauncher(context: context, controller: _scenarioLauncher),
    );
  }
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
