import 'dart:async';

/// Manages the 30-minute draw countdown for a single game round.
///
/// Usage:
/// ```dart
/// final timer = GameTimer(
///   onTick:    (remaining) => setState(() => _timeLeft = remaining),
///   onExpired: ()          => setState(() => _game.declareDraw()),
/// );
/// timer.start();   // call in initState / on reset
/// timer.pause();   // call when the game is paused
/// timer.resume();  // call when the game is resumed
/// timer.stop();    // call when the game ends with a winner
/// timer.dispose(); // call in dispose()
/// ```
class GameTimer {
  static const duration = Duration(minutes: 30);

  /// Called every second with the remaining [Duration].
  final void Function(Duration remaining) onTick;

  /// Called once when the 30-minute limit is reached.
  final void Function() onExpired;

  Timer?   _countdownTimer;
  Timer?   _tickTimer;
  Duration _timeLeft = duration;
  bool     _paused   = false;

  Duration get timeLeft => _timeLeft;
  bool     get isPaused => _paused;

  GameTimer({required this.onTick, required this.onExpired});

  /// Starts (or restarts) the timer from 30:00.
  void start() {
    _cancel();
    _timeLeft = duration;
    _paused   = false;
    _startInternal();
  }

  /// Starts the timer from a specific [remaining] duration (used when
  /// restoring a saved game).
  void startFrom(Duration remaining) {
    _cancel();
    _timeLeft = remaining;
    _paused   = false;
    _startInternal();
  }

  /// Pauses the countdown without resetting it.
  void pause() {
    if (_paused) return;
    _paused = true;
    _cancel();
  }

  /// Resumes from wherever the countdown left off.
  void resume() {
    if (!_paused) return;
    _paused = false;
    _startInternal();
  }

  /// Cancels the timer permanently (e.g. when the game ends with a winner).
  void stop() {
    _paused = false;
    _cancel();
  }

  /// Releases resources. Call from the widget's [dispose].
  void dispose() => stop();

  // ── Internal ──────────────────────────────────────

  void _startInternal() {
    _countdownTimer = Timer(_timeLeft, onExpired);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeLeft = _timeLeft - const Duration(seconds: 1);
      onTick(_timeLeft);
    });
  }

  void _cancel() {
    _countdownTimer?.cancel();
    _tickTimer?.cancel();
    _countdownTimer = null;
    _tickTimer      = null;
  }
}
