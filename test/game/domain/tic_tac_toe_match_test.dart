import 'package:coreflame/game/domain/tic_tac_toe_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicTacToeMatch', () {
    test('starts with an empty board and X to play', () {
      final match = TicTacToeMatch();

      expect(match.cells, everyElement(isNull));
      expect(match.turn, Mark.x);
      expect(match.result, RoundResult.playing);
    });

    test('rejects a move in an occupied cell', () {
      final match = TicTacToeMatch();

      expect(match.play(4), MoveOutcome.accepted);
      expect(match.play(4), MoveOutcome.occupied);
      expect(match.markAt(4), Mark.x);
      expect(match.turn, Mark.o);
    });

    test('detects a win, awards a point, and closes the round', () {
      final match = TicTacToeMatch();

      for (final move in [0, 3, 1, 4, 2]) {
        expect(match.play(move), MoveOutcome.accepted);
      }

      expect(match.result, RoundResult.xWon);
      expect(match.winningCells, [0, 1, 2]);
      expect(match.xScore, 1);
      expect(match.play(5), MoveOutcome.roundFinished);
    });

    test('detects a draw', () {
      final match = TicTacToeMatch();

      for (final move in [0, 1, 2, 4, 3, 5, 7, 6, 8]) {
        match.play(move);
      }

      expect(match.result, RoundResult.draw);
      expect(match.draws, 1);
    });

    test('clears the board and alternates starters for a fresh round', () {
      final match = TicTacToeMatch();
      match.play(0);

      match.startNextRound();

      expect(match.cells, everyElement(isNull));
      expect(match.turn, Mark.o);
      expect(match.result, RoundResult.playing);
    });
  });
}
