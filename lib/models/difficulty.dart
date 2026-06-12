enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.easy   => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard   => 'Hard',
      };

  /// Minimax search depth for this difficulty.
  int get depth => switch (this) {
        Difficulty.easy   => 1,
        Difficulty.medium => 2,
        Difficulty.hard   => 7,
      };

  /// Chance (0–100) that the AI picks a random move instead of the best one.
  int get randomChance => switch (this) {
        Difficulty.easy   => 90,
        Difficulty.medium => 45,
        Difficulty.hard   => 0,
      };
}
