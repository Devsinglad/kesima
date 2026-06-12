import 'package:vibration/vibration.dart';

/// Device feedback helpers for the game.
class HapticUtil {
  HapticUtil._();

  /// Three strong pulses — warns the player they are one move from being trapped.
  /// Falls back gracefully if the device has no vibrator.
  static Future<void> warningPulse() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

    // Pattern: [delay, vibrate, delay, vibrate, delay, vibrate] in ms
    await Vibration.vibrate(pattern: [0, 250, 120, 250, 120, 250]);
  }
}
