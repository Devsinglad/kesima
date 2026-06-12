import 'dart:math';
import 'player.dart';
import 'difficulty.dart';
import '../constants/game_constants.dart';

/// Minimax AI with alpha-beta pruning.
/// Works for either player — [bestMove] plays as Red, [hintMove] plays as Blue.
class AiPlayer {
  static final _rng = Random();

  /// Returns the best (fromNode, toNode) for [aiPlayer] at the given [difficulty].
  static (int, int) bestMove(
    List<Player?> board,
    Difficulty difficulty,
    Player aiPlayer,
  ) {
    return _search(board, aiPlayer, difficulty.depth, difficulty.randomChance);
  }

  /// Returns a suggested (fromNode, toNode) for [humanPlayer] using a shallow search.
  /// Used by the hint button.
  static (int, int) hintMove(List<Player?> board, Player humanPlayer) {
    return _search(board, humanPlayer, 2, 0);
  }

  // ── Core search ───────────────────────────────────

  static (int, int) _search(
    List<Player?> board,
    Player ai,
    int depth,
    int randomChance,
  ) {
    final moves = _generateMoves(board, ai);
    if (moves.isEmpty) return (-1, -1);

    // Random move path
    if (randomChance > 0 && _rng.nextInt(100) < randomChance) {
      return moves[_rng.nextInt(moves.length)];
    }

    int bestScore = -999999;
    (int, int) best = moves.first;

    for (final move in moves) {
      final (from, to) = move;
      _applyMove(board, from, to);
      final score = _minimax(board, depth - 1, false, -999999, 999999, ai);
      _undoMove(board, from, to);

      if (score > bestScore) {
        bestScore = score;
        best      = move;
      }
    }
    return best;
  }

  // ── Minimax ───────────────────────────────────────

  static int _minimax(
    List<Player?> board,
    int depth,
    bool maximizing,
    int alpha,
    int beta,
    Player ai,
  ) {
    final opponent    = ai.opponent;
    final aiTarget    = ai       == Player.red ? kBlueHome : kRedHome;
    final oppTarget   = opponent == Player.red ? kBlueHome : kRedHome;

    // Terminal: AI wins by invasion
    if (aiTarget.where((n) => board[n] == ai).length >= kWinCount) {
      return 1000 + depth;
    }
    // Terminal: opponent wins by invasion
    if (oppTarget.where((n) => board[n] == opponent).length >= kWinCount) {
      return -1000 - depth;
    }

    if (depth == 0) return _evaluate(board, ai);

    final current = maximizing ? ai : opponent;
    final moves   = _generateMoves(board, current);

    // No moves → current player is blocked → they lose
    if (moves.isEmpty) return maximizing ? -1000 - depth : 1000 + depth;

    if (maximizing) {
      int best = -999999;
      for (final (from, to) in moves) {
        _applyMove(board, from, to);
        final score = _minimax(board, depth - 1, false, alpha, beta, ai);
        _undoMove(board, from, to);
        if (score > best)  best  = score;
        if (best  > alpha) alpha = best;
        if (beta <= alpha) break;
      }
      return best;
    } else {
      int best = 999999;
      for (final (from, to) in moves) {
        _applyMove(board, from, to);
        final score = _minimax(board, depth - 1, true, alpha, beta, ai);
        _undoMove(board, from, to);
        if (score < best) best = score;
        if (best  < beta) beta = best;
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  // ── Evaluation (invasion-first) ───────────────────

  static int _evaluate(List<Player?> board, Player ai) {
    final opponent  = ai.opponent;
    final aiTarget  = ai       == Player.red ? kBlueHome : kRedHome;
    final oppTarget = opponent == Player.red ? kBlueHome : kRedHome;

    int score = 0;

    // Primary: pieces in opponent's home
    score += aiTarget .where((n) => board[n] == ai      ).length * 150;
    score -= oppTarget.where((n) => board[n] == opponent).length * 150;

    // Secondary: forward progress toward opponent's home
    for (int i = 0; i < kNodePos.length; i++) {
      if (board[i] == ai) {
        score += ai == Player.red
            ? ((1.0 - kNodePos[i].dy) * 30).round() // red goes up (low Y)
            : (kNodePos[i].dy * 30).round();          // blue goes down (high Y)
      } else if (board[i] == opponent) {
        score -= opponent == Player.red
            ? ((1.0 - kNodePos[i].dy) * 30).round()
            : (kNodePos[i].dy * 30).round();
      }
    }

    // Tertiary: mobility
    int aiMob = 0, oppMob = 0;
    for (int i = 0; i < kNodePos.length; i++) {
      final e = kAdj[i].where((n) => board[n] == null).length;
      if (board[i] == ai)       aiMob  += e;
      if (board[i] == opponent) oppMob += e;
    }
    score += (aiMob - oppMob) * 2;

    // Center hub
    if (board[5] == ai)       score += 10;
    if (board[5] == opponent) score -= 10;

    return score;
  }

  // ── Helpers ───────────────────────────────────────

  static List<(int, int)> _generateMoves(List<Player?> board, Player p) {
    final moves = <(int, int)>[];
    for (int from = 0; from < kNodePos.length; from++) {
      if (board[from] != p) continue;
      for (final to in kAdj[from]) {
        if (board[to] == null) moves.add((from, to));
      }
    }
    return moves;
  }

  static void _applyMove(List<Player?> board, int from, int to) {
    board[to]   = board[from];
    board[from] = null;
  }

  static void _undoMove(List<Player?> board, int from, int to) {
    board[from] = board[to];
    board[to]   = null;
  }
}
