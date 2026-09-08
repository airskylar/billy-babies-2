enum DuelPrototypeStatus { setupNotStarted }

final class DuelPrototypeSession {
  const DuelPrototypeSession({this.scenarioId});

  final String? scenarioId;
  DuelPrototypeStatus get status => DuelPrototypeStatus.setupNotStarted;
}
