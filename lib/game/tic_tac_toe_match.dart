enum Mark { x, o }

extension MarkDetails on Mark {
  Mark get other => this == Mark.x ? Mark.o : Mark.x;

  String get symbol => this == Mark.x ? 'X' : 'O';

  String get nickname => this == Mark.x ? 'Berry' : 'Peach';
}

enum RoundResult { playing, xWon, oWon, draw }

class TicTacToeMatch {
  TicTacToeMatch({Mark firstPlayer = Mark.x})
    : _turn = firstPlayer,
      _starter = firstPlayer;

  static const _winningLines = <List<int>>[
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  final List<Mark?> _cells = List<Mark?>.filled(9, null);
  Mark _turn;
  Mark _starter;
  RoundResult _result = RoundResult.playing;
  List<int> _winningCells = const [];

  int xScore = 0;
  int oScore = 0;
  int draws = 0;

  Mark get turn => _turn;
  RoundResult get result => _result;
  bool get isFinished => _result != RoundResult.playing;
  List<Mark?> get cells => List<Mark?>.unmodifiable(_cells);
  List<int> get winningCells => List<int>.unmodifiable(_winningCells);

  Mark? markAt(int index) {
    RangeError.checkValidIndex(index, _cells, 'index');
    return _cells[index];
  }

  bool play(int index) {
    RangeError.checkValidIndex(index, _cells, 'index');
    if (isFinished || _cells[index] != null) {
      return false;
    }

    final playedMark = _turn;
    _cells[index] = playedMark;
    _resolveRound(playedMark);
    if (!isFinished) {
      _turn = _turn.other;
    }
    return true;
  }

  void startNextRound() {
    _starter = _starter.other;
    _turn = _starter;
    _clearBoard();
  }

  void resetMatch() {
    xScore = 0;
    oScore = 0;
    draws = 0;
    _starter = Mark.x;
    _turn = Mark.x;
    _clearBoard();
  }

  void _resolveRound(Mark playedMark) {
    for (final line in _winningLines) {
      if (line.every((index) => _cells[index] == playedMark)) {
        _winningCells = line;
        if (playedMark == Mark.x) {
          _result = RoundResult.xWon;
          xScore += 1;
        } else {
          _result = RoundResult.oWon;
          oScore += 1;
        }
        return;
      }
    }

    if (_cells.every((mark) => mark != null)) {
      _result = RoundResult.draw;
      draws += 1;
    }
  }

  void _clearBoard() {
    for (var index = 0; index < _cells.length; index += 1) {
      _cells[index] = null;
    }
    _result = RoundResult.playing;
    _winningCells = const [];
  }
}
