import 'package:state_launcher_flutter/state_launcher_flutter.dart';

import '../game/tic_tac_toe_match.dart';

enum GameScenario {
  empty(
    id: 'round.empty',
    label: 'Empty round',
    description: 'Starts a fresh round with X to play.',
    tags: ['baseline'],
    moves: [],
  ),
  xAboutToWin(
    id: 'round.x-about-to-win',
    label: 'X about to win',
    description: 'X can complete the top row with one move.',
    tags: ['victory', 'one move'],
    moves: [0, 3, 1, 4],
  ),
  oAboutToWin(
    id: 'round.o-about-to-win',
    label: 'O about to win',
    description: 'O can complete the middle row with one move.',
    tags: ['victory', 'one move'],
    moves: [0, 3, 8, 4, 6],
  ),
  drawAboutToFinish(
    id: 'round.draw-about-to-finish',
    label: 'Draw about to finish',
    description: 'Only one non-winning move remains.',
    tags: ['draw', 'edge case'],
    moves: [0, 1, 2, 4, 3, 5, 7, 6],
  );

  const GameScenario({
    required this.id,
    required this.label,
    required this.description,
    required this.tags,
    required this.moves,
  });

  final String id;
  final String label;
  final String description;
  final List<String> tags;
  final List<int> moves;

  StateLauncherEntry get launcherEntry => StateLauncherEntry(
    id: id,
    label: label,
    description: description,
    tags: tags,
  );

  TicTacToeMatch createMatch() {
    final match = TicTacToeMatch();
    for (final move in moves) {
      final outcome = match.play(move);
      if (outcome != MoveOutcome.accepted) {
        throw StateError('Invalid move $move in scenario $id.');
      }
    }
    return match;
  }

  static GameScenario? findById(String id) {
    for (final scenario in values) {
      if (scenario.id == id) return scenario;
    }
    return null;
  }
}
