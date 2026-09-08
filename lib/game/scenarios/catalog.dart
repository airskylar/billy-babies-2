import 'package:state_launcher_flutter/state_launcher_flutter.dart';

enum GameScenario {
  shell(
    id: 'shell.default',
    label: 'Duel shell',
    description: 'Opens the non-playable Billy Babies foundation shell.',
    tags: ['foundation', 'not playable'],
  );

  const GameScenario({
    required this.id,
    required this.label,
    required this.description,
    required this.tags,
  });

  final String id;
  final String label;
  final String description;
  final List<String> tags;

  StateLauncherEntry get launcherEntry => StateLauncherEntry(
    id: id,
    label: label,
    description: description,
    tags: tags,
  );

  static GameScenario? findById(String id) {
    for (final scenario in values) {
      if (scenario.id == id) return scenario;
    }
    return null;
  }
}
