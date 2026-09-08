import 'package:coreflame/game/domain/prototype_session.dart';
import 'package:coreflame/game/game_root.dart';
import 'package:coreflame/game/inspection/protocol.dart';
import 'package:coreflame/game/prototype_contract.dart';
import 'package:coreflame/runtime/inspection/runtime_inspection.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillyBabiesGame foundation observability', () {
    testWithGame<BillyBabiesGame>(
      'reports an honest not-started state and stable shell component',
      BillyBabiesGame.new,
      (game) async {
        await game.ready();

        final semantic = game.snapshot(SnapshotDetail.semantic);
        final visual = game.snapshot(SnapshotDetail.visual);
        final semanticGame = semantic.game.state as BillyBabiesSnapshot;
        final visualGame = visual.game.state as BillyBabiesSnapshot;

        expect(semantic.game.id, BillyBabiesPrototypeContract.gameId);
        expect(
          semantic.game.schemaVersion,
          BillyBabiesPrototypeContract.gameSchemaVersion,
        );
        expect(semanticGame.status, DuelPrototypeStatus.setupNotStarted);
        expect(semanticGame.scenarioId, isNull);
        expect(semanticGame.scene?.name, 'Billy Babies Duel Shell');
        expect(semanticGame.scene?.ready, isTrue);
        expect(semanticGame.scene?.bounds, isNull);
        expect(visualGame.scene?.bounds, isNotNull);
        expect(game.capabilities().commands, isEmpty);
        expect(
          semantic.components.map((component) => component.id),
          containsAll(const {'game', 'duel-shell'}),
        );
        expect(
          semantic.components
              .singleWhere((component) => component.id == 'duel-shell')
              .parentId,
          'game',
        );
      },
    );

    testWithGame<BillyBabiesGame>(
      'applies safe padding to the shell viewport',
      BillyBabiesGame.new,
      (game) async {
        await game.ready();
        const padding = EdgeInsets.fromLTRB(11, 13, 17, 19);
        game.safePadding = padding;

        final state = game.snapshot(SnapshotDetail.visual).game.state;
        final scene = (state as BillyBabiesSnapshot).scene!;

        expect(scene.bounds!.width, game.size.x - padding.horizontal);
        expect(scene.bounds!.height, game.size.y - padding.vertical);
      },
    );
  });
}
