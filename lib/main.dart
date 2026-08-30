import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show DisplayFeatureType;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/coreflame_game.dart';
import 'game/services/coreflame_game_services_config.dart';
import 'game/services/game_platform_services.dart';
import 'game/services/mobile_game_platform_services.dart';
import 'game/theme/game_palette.dart';

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
  late final CoreflameGame _game;

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
    _game = CoreflameGame(platformServices: _gameServices);

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
    if (_ownsGameServices) unawaited(_gameServices.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _game.safePadding = _safePaddingFor(MediaQuery.of(context));
    return Scaffold(body: GameWidget<CoreflameGame>(game: _game));
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
