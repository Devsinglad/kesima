import 'package:shared_preferences/shared_preferences.dart';
import '../models/difficulty.dart';
import '../models/game_mode.dart';
import '../models/player.dart';

/// Persists game stats and saved game state across sessions.
class StorageService {
  StorageService._();

  // ── Stats keys ────────────────────────────────────
  static const _kWins   = 'total_wins';
  static const _kLosses = 'total_losses';
  static const _kDraws  = 'total_draws';

  static Future<void> addWin()  async => _increment(_kWins);
  static Future<void> addLoss() async => _increment(_kLosses);
  static Future<void> addDraw() async => _increment(_kDraws);

  static Future<GameStats> loadStats() async {
    final p = await SharedPreferences.getInstance();
    return GameStats(
      wins:   p.getInt(_kWins)   ?? 0,
      losses: p.getInt(_kLosses) ?? 0,
      draws:  p.getInt(_kDraws)  ?? 0,
    );
  }

  // ── Saved game keys ───────────────────────────────
  static const _kHasSaved    = 'has_saved_game';
  static const _kBoard       = 'saved_board';        // "0,1,2,0,..." 0=empty 1=blue 2=red
  static const _kCurrent     = 'saved_current';      // 0=blue 1=red
  static const _kBlueScore   = 'saved_blue_score';
  static const _kRedScore    = 'saved_red_score';
  static const _kTimeLeft    = 'saved_time_left_sec';
  static const _kMode        = 'saved_mode';         // 0=twoPlayer 1=vsComputer
  static const _kDifficulty  = 'saved_difficulty';   // 0=easy 1=medium 2=hard
  static const _kHumanPlayer = 'saved_human_player'; // 0=blue 1=red

  /// Saves the current game state so it can be resumed later.
  static Future<void> saveGame(SavedGame game) async {
    final p = await SharedPreferences.getInstance();
    final boardEncoded = game.board
        .map((cell) => cell == null ? 0 : cell == Player.blue ? 1 : 2)
        .join(',');
    await p.setBool  (_kHasSaved,    true);
    await p.setString(_kBoard,       boardEncoded);
    await p.setInt   (_kCurrent,     game.current == Player.blue ? 0 : 1);
    await p.setInt   (_kBlueScore,   game.blueScore);
    await p.setInt   (_kRedScore,    game.redScore);
    await p.setInt   (_kTimeLeft,    game.timeLeft.inSeconds);
    await p.setInt   (_kMode,        game.mode == GameMode.twoPlayer ? 0 : 1);
    await p.setInt   (_kDifficulty,  game.difficulty.index);
    await p.setInt   (_kHumanPlayer, game.humanPlayer == Player.blue ? 0 : 1);
  }

  /// Returns the saved game, or null if none exists.
  static Future<SavedGame?> loadSavedGame() async {
    final p = await SharedPreferences.getInstance();
    if (!(p.getBool(_kHasSaved) ?? false)) return null;

    final boardRaw = p.getString(_kBoard) ?? '';
    if (boardRaw.isEmpty) return null;

    final board = boardRaw.split(',').map((s) {
      return switch (s) {
        '1' => Player.blue,
        '2' => Player.red,
        _   => null,
      };
    }).toList();

    return SavedGame(
      board:       board,
      current:     (p.getInt(_kCurrent) ?? 0) == 0 ? Player.blue : Player.red,
      blueScore:   p.getInt(_kBlueScore)  ?? 0,
      redScore:    p.getInt(_kRedScore)   ?? 0,
      timeLeft:    Duration(seconds: p.getInt(_kTimeLeft) ?? 1800),
      mode:        (p.getInt(_kMode) ?? 1) == 0
                     ? GameMode.twoPlayer
                     : GameMode.vsComputer,
      difficulty:  Difficulty.values[
                     (p.getInt(_kDifficulty) ?? 0).clamp(0, 2)],
      humanPlayer: (p.getInt(_kHumanPlayer) ?? 0) == 0
                     ? Player.blue
                     : Player.red,
    );
  }

  /// Removes any saved game (called when the game finishes or is abandoned).
  static Future<void> clearSavedGame() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kHasSaved, false);
  }

  // ── Helpers ───────────────────────────────────────
  static Future<void> _increment(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(key, (p.getInt(key) ?? 0) + 1);
  }
}

// ── Models ────────────────────────────────────────

/// Immutable snapshot of the player's lifetime stats.
class GameStats {
  final int wins;
  final int losses;
  final int draws;
  const GameStats({
    required this.wins,
    required this.losses,
    required this.draws,
  });
  int get total => wins + losses + draws;
}

/// Snapshot of a mid-game state used to resume later.
class SavedGame {
  final List<Player?> board;
  final Player        current;
  final int           blueScore;
  final int           redScore;
  final Duration      timeLeft;
  final GameMode      mode;
  final Difficulty    difficulty;
  final Player        humanPlayer;

  const SavedGame({
    required this.board,
    required this.current,
    required this.blueScore,
    required this.redScore,
    required this.timeLeft,
    required this.mode,
    required this.difficulty,
    this.humanPlayer = Player.blue,
  });
}
