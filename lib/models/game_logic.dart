import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import 'player.dart';

/// Pure game logic — no Flutter widgets.
/// Screens call [tap] then call setState themselves.
class GameLogic {
  // ── State ────────────────────────────────────────
  late List<Player?> board;      // length = kNodePos.length (11)
  late Player        current;
  int?       selected;
  List<int>  validMoves = [];
  Player?    winner;
  List<int>? winLine;            // nodes of the winning (invaded) pieces
  bool       isDraw     = false;
  bool       isWarning  = false; // true when current player is one move from being trapped
  int        blueScore  = 0;
  int        redScore   = 0;
  String     message    = '';

  // ── Undo history ─────────────────────────────────
  // Each entry is a snapshot saved *before* a move executes.
  final List<_Snapshot> _history = [];
  bool get canUndo => _history.isNotEmpty;

  GameLogic() { reset(); }

  // ── Public API ───────────────────────────────────

  void reset() {
    board = List.filled(kNodePos.length, null);
    for (final n in kBlueStart) {
      board[n] = Player.blue;
    }
    for (final n in kRedStart) {
      board[n] = Player.red;
    }
    current    = Player.blue;
    selected   = null;
    validMoves = [];
    winner     = null;
    winLine    = null;
    isDraw     = false;
    isWarning  = false;
    message    = "Blue's turn — tap a piece";
    _history.clear();
  }

  /// Restores a previously saved mid-game state.
  void restore({
    required List<Player?> board,
    required Player        current,
    required int           blueScore,
    required int           redScore,
  }) {
    this.board     = List<Player?>.from(board);
    this.current   = current;
    this.blueScore = blueScore;
    this.redScore  = redScore;
    selected       = null;
    validMoves     = [];
    winner         = null;
    winLine        = null;
    isDraw         = false;
    isWarning      = false;
    message        = "${current.label}'s turn — tap a piece";
    _history.clear();
  }

  /// Undoes the most recent move, restoring the board to its previous state.
  /// Call twice from the screen to undo a full player+AI round.
  void undo() {
    if (_history.isEmpty) return;
    final snap = _history.removeLast();
    board      = List<Player?>.from(snap.board);
    current    = snap.current;
    winner     = null;
    winLine    = null;
    isDraw     = false;
    selected   = null;
    validMoves = [];
    isWarning  = _isOneStepFromTrapped(current);
    message    = "${current.label}'s turn — tap a piece";
  }

  /// Called by the screen when the 30-minute timer fires with no winner.
  void declareDraw() {
    if (winner != null || isDraw) return;
    isDraw     = true;
    isWarning  = false;
    selected   = null;
    validMoves = [];
    message    = "This game has been dragging for over 30 mins — let's call it a draw!";
  }

  /// Directly executes a move from [from] to [to] (used by the AI).
  void aiMove(int from, int to) {
    if (winner != null || isDraw) return;
    _execute(from, to);
  }

  /// Called when the player taps a board node.
  void tap(int node) {
    if (winner != null || isDraw) return;

    if (selected == null) {
      _trySelect(node);
    } else if (node == selected) {
      _deselect();
    } else if (validMoves.contains(node)) {
      _execute(selected!, node);
    } else if (board[node] == current) {
      _trySelect(node); // switch selection to another own piece
    }
  }

  /// Convert a screen [pos] to a node index (null if no node nearby).
  int? hitTest(Offset pos, double boardSize) {
    double best = double.infinity;
    int?   hit;
    for (int i = 0; i < kNodePos.length; i++) {
      final d = (pos - _scaled(i, boardSize)).distance;
      if (d < kHitR * boardSize && d < best) {
        best = d;
        hit  = i;
      }
    }
    return hit;
  }

  // ── Private helpers ──────────────────────────────

  void _trySelect(int node) {
    if (board[node] != current) return;
    final mv = _movesFor(node);
    if (mv.isEmpty) return;
    selected   = node;
    validMoves = mv;
    message    = 'Tap a lit node to move  ·  tap piece again to cancel';
  }

  void _deselect() {
    selected   = null;
    validMoves = [];
    message    = "${current.label}'s turn — tap a piece";
  }

  void _execute(int from, int to) {
    // Save snapshot before the move so it can be undone
    _history.add(_Snapshot(List<Player?>.from(board), current));

    board[to]   = board[from];
    board[from] = null;
    selected    = null;
    validMoves  = [];
    isWarning   = false;

    // 1. Win: current player has all kWinCount pieces in opponent's home
    final opponentHome = current == Player.blue ? kRedHome : kBlueHome;
    final invaded = opponentHome.where((n) => board[n] == current).toList();
    if (invaded.length >= kWinCount) {
      _declareWin(current, invaded);
      message = '${current.label} wins — all pieces reached opponent\'s base!';
      return;
    }

    // 2. Switch turn
    current = current.opponent;

    // 3. Check if new current player is fully blocked → previous player wins
    final canMove = List.generate(kNodePos.length, (i) => i)
        .any((i) => board[i] == current && _movesFor(i).isNotEmpty);
    if (!canMove) {
      _declareWin(current.opponent, null);
      message = '${current.opponent.label} wins — '
                '${current.label} is completely trapped with no moves!';
      return;
    }

    // 4. Lookahead: warn if current player could be trapped after their next move
    isWarning = _isOneStepFromTrapped(current);

    // 5. Status message
    final myHome     = current == Player.blue ? kBlueHome : kRedHome;
    final threatened = myHome.where((n) => board[n] == current.opponent).length;

    if (isWarning) {
      message = "${current.label}'s turn — "
                "⚠ DANGER: You could be completely trapped next move!";
    } else if (threatened > 0) {
      message = "${current.label}'s turn — ⚠ ${current.opponent.label} has "
                "$threatened piece(s) in your base!";
    } else {
      message = "${current.label}'s turn — tap a piece";
    }
  }

  /// Returns true if there exists any sequence:
  ///   [p] makes a move → opponent responds → [p] has no moves left.
  bool _isOneStepFromTrapped(Player p) {
    final opponent = p.opponent;

    for (int from = 0; from < kNodePos.length; from++) {
      if (board[from] != p) continue;
      for (final to in kAdj[from]) {
        if (board[to] != null) continue;

        // Simulate p's move
        board[to]   = board[from];
        board[from] = null;

        // Try every opponent response
        for (int of = 0; of < kNodePos.length; of++) {
          if (board[of] != opponent) continue;
          for (final ot in kAdj[of]) {
            if (board[ot] != null) continue;

            // Simulate opponent's response
            board[ot] = board[of];
            board[of] = null;

            // Check if p is now blocked
            final blocked = !List.generate(kNodePos.length, (i) => i)
                .any((i) => board[i] == p && _movesFor(i).isNotEmpty);

            // Undo opponent's move
            board[of] = board[ot];
            board[ot] = null;

            if (blocked) {
              // Undo p's move before returning
              board[from] = board[to];
              board[to]   = null;
              return true;
            }
          }
        }

        // Undo p's move
        board[from] = board[to];
        board[to]   = null;
      }
    }
    return false;
  }

  void _declareWin(Player p, List<int>? line) {
    winner  = p;
    winLine = line;
    if (p == Player.blue) { blueScore++; }
    else                  { redScore++; }
  }

  List<int> _movesFor(int node) =>
      kAdj[node].where((n) => board[n] == null).toList();

  Offset _scaled(int i, double s) =>
      Offset(kNodePos[i].dx * s, kNodePos[i].dy * s);
}

// ── Snapshot ──────────────────────────────────────

class _Snapshot {
  final List<Player?> board;
  final Player        current;
  const _Snapshot(this.board, this.current);
}
