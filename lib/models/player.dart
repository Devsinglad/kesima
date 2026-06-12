enum Player { blue, red }

extension PlayerX on Player {
  Player get opponent => this == Player.blue ? Player.red : Player.blue;
  String get label    => this == Player.blue ? 'Blue' : 'Red';
  bool   get isBlue   => this == Player.blue;
}
