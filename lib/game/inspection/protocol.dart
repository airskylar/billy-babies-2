import '../../runtime/inspection/runtime_inspection.dart';
import '../domain/prototype_session.dart';

class DuelSceneSnapshot {
  const DuelSceneSnapshot({
    required this.name,
    required this.ready,
    required this.orientation,
    this.bounds,
  });

  final String name;
  final bool ready;
  final String orientation;
  final RectSnapshot? bounds;

  Map<String, Object?> toJson() => {
    'name': name,
    'ready': ready,
    'orientation': orientation,
    if (bounds case final value?) 'bounds': value.toJson(),
  };
}

class BillyBabiesSnapshot implements GameInspectionState {
  const BillyBabiesSnapshot({
    required this.status,
    required this.contractVersion,
    required this.rulesId,
    required this.contentId,
    required this.timingId,
    required this.rosterId,
    required this.strategyId,
    required this.scenarioId,
    required this.scene,
  });

  final DuelPrototypeStatus status;
  final int contractVersion;
  final String rulesId;
  final String contentId;
  final String timingId;
  final String rosterId;
  final String strategyId;
  final String? scenarioId;
  final DuelSceneSnapshot? scene;

  @override
  Map<String, Object?> toJson() => {
    'status': status.name,
    'contract': {
      'version': contractVersion,
      'rulesId': rulesId,
      'contentId': contentId,
      'timingId': timingId,
      'rosterId': rosterId,
      'strategyId': strategyId,
    },
    'scenario': {'id': scenarioId},
    if (scene case final value?) 'scene': value.toJson(),
  };
}
