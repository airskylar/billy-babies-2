import 'package:flutter/material.dart';

import '../runtime/inspection/inspectable_flame_game.dart';
import '../runtime/inspection/runtime_inspection.dart';
import 'domain/prototype_session.dart';
import 'inspection/adapter.dart';
import 'scene/scene.dart';
import 'theme/game_palette.dart';

class BillyBabiesGame extends InspectableFlameGame {
  BillyBabiesGame({DuelPrototypeSession? session})
    : session = session ?? const DuelPrototypeSession();

  final DuelPrototypeSession session;
  BillyBabiesDuelScene? _scene;

  late final BillyBabiesInspectionAdapter _inspectionAdapter =
      BillyBabiesInspectionAdapter(session: session, scene: () => _scene);

  @override
  RuntimeInspectionAdapter get inspectionAdapter => _inspectionAdapter;

  @override
  Color backgroundColor() => DuelPalette.canvas;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final scene = BillyBabiesDuelScene();
    _scene = scene;
    await add(scene);
    scene.applySafeViewport(size, safePadding);
  }

  @override
  void onSafePaddingChanged(EdgeInsets value) {
    _scene?.applySafeViewport(size, value);
  }
}
