import 'package:coreflame/game/domain/prototype_session.dart';
import 'package:coreflame/game/inspection/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('semantic shell snapshots omit visual bounds', () {
    const snapshot = BillyBabiesSnapshot(
      status: DuelPrototypeStatus.setupNotStarted,
      contractVersion: 1,
      rulesId: 'rules',
      contentId: 'content',
      timingId: 'timing',
      rosterId: 'roster',
      strategyId: 'strategy',
      scenarioId: null,
      scene: DuelSceneSnapshot(
        name: 'Billy Babies Duel Shell',
        ready: true,
        orientation: 'landscape',
      ),
    );

    final json = snapshot.toJson();
    expect(json['status'], 'setupNotStarted');
    expect(json['scenario'], {'id': null});
    expect(json['scene'], isNot(contains('bounds')));
  });
}
