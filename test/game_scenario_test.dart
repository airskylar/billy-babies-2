import 'package:coreflame/game/tic_tac_toe_match.dart';
import 'package:coreflame/scenarios/game_scenario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scenario IDs and launcher entries come from the enum catalog', () {
    expect(
      GameScenario.values.map((scenario) => scenario.launcherEntry.id),
      GameScenario.values.map((scenario) => scenario.id),
    );
  });

  test('X-about-to-win creates a fresh match with one winning move', () {
    final first = GameScenario.xAboutToWin.createMatch();
    final second = GameScenario.xAboutToWin.createMatch();

    expect(first, isNot(same(second)));
    expect(first.turn, Mark.x);
    expect(first.cells, [
      Mark.x,
      Mark.x,
      null,
      Mark.o,
      Mark.o,
      null,
      null,
      null,
      null,
    ]);
    expect(first.play(2), MoveOutcome.accepted);
    expect(first.result, RoundResult.xWon);
  });

  test('O-about-to-win creates a match with one winning move', () {
    final match = GameScenario.oAboutToWin.createMatch();

    expect(match.turn, Mark.o);
    expect(match.play(5), MoveOutcome.accepted);
    expect(match.result, RoundResult.oWon);
  });

  test('draw-about-to-finish creates a match with one empty cell', () {
    final match = GameScenario.drawAboutToFinish.createMatch();

    expect(match.cells.where((mark) => mark == null), hasLength(1));
    expect(match.play(8), MoveOutcome.accepted);
    expect(match.result, RoundResult.draw);
  });
}
