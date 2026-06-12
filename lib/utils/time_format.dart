/// Formatting helpers for time/duration display.
class TimeFormat {
  TimeFormat._();

  /// Formats a [Duration] as `MM:SS` (e.g. `"04:07"`).
  static String countdown(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
