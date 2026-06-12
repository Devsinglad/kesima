/// Hail titles awarded to the player based on their total win count.
/// Titles are listed in ascending order — the highest matching title is used.
const List<(int minWins, String title)> kPlayerTitles = [
  (0,   'Rookie'),
  (1,   'First Blood'),
  (3,   'Warming Up'),
  (5,   'Street Baller'),
  (8,   'Sharp Sharp'),
  (11,  'No Slack'),
  (14,  'Odogwu'),        // Igbo — great one / champion
  (18,  'Agba Gamer'),    // Yoruba pidgin — veteran gamer
  (22,  'The Oga'),       // pidgin — the boss
  (27,  'HIM'),
  (33,  'The GOAT'),
  (40,  'Untouchable'),
  (50,  'Born Winner'),
  (60,  'Legend'),
  (75,  'Gbogbo Nnkan'), // Yoruba — everything / all-round great
  (90,  'Oni Baje'),     // Yoruba — one who does not fail
  (110, 'The One'),
  (130, 'Immortal'),
  (999, 'God of the Board'),
];

/// Returns the hail title for a given [wins] count.
String playerTitle(int wins) {
  String title = kPlayerTitles.first.$2;
  for (final (minWins, name) in kPlayerTitles) {
    if (wins >= minWins) title = name;
  }
  return title;
}
