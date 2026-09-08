import '../../runtime/inspection/runtime_inspection.dart';
import '../domain/prototype_session.dart';
import '../prototype_contract.dart';
import '../scene/scene.dart';
import 'protocol.dart';

class BillyBabiesInspectionAdapter implements RuntimeInspectionAdapter {
  BillyBabiesInspectionAdapter({required this.session, required this.scene});

  final DuelPrototypeSession session;
  final BillyBabiesDuelScene? Function() scene;

  @override
  String get gameId => BillyBabiesPrototypeContract.gameId;

  @override
  int get schemaVersion => BillyBabiesPrototypeContract.gameSchemaVersion;

  @override
  final RuntimeCommandRegistry commandRegistry = RuntimeCommandRegistry([]);

  @override
  BillyBabiesSnapshot snapshot(SnapshotDetail detail) => BillyBabiesSnapshot(
    status: session.status,
    contractVersion: BillyBabiesPrototypeContract.contractVersion,
    rulesId: BillyBabiesPrototypeContract.rulesId,
    contentId: BillyBabiesPrototypeContract.contentId,
    timingId: BillyBabiesPrototypeContract.timingId,
    rosterId: BillyBabiesPrototypeContract.rosterId,
    strategyId: BillyBabiesPrototypeContract.strategyId,
    scenarioId: session.scenarioId,
    scene: scene()?.snapshot(detail),
  );
}
