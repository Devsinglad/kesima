import 'package:flutter/material.dart';
import 'package:flutter_balloons/flutter_balloons.dart';
import '../constants/player_titles.dart';
import '../theme/app_colors.dart';
import '../utils/storage_service.dart';

/// Displays the player's lifetime stats: hail title, wins (with balloon
/// animation), losses, and draws.
class StatsPanel extends StatelessWidget {
  final GameStats stats;
  const StatsPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final hasPlayed = stats.total > 0;
    final title     = playerTitle(stats.wins);

    return Column(
      children: [
        // Hail title
        Text(
          hasPlayed ? title : 'Play to earn your title',
          style: TextStyle(
            fontSize: 20,
            fontWeight: hasPlayed ? FontWeight.bold : FontWeight.normal,
            color: hasPlayed
                ? AppColors.goldLight
                : AppColors.goldPale.withValues(alpha: 0.40),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        // Wins box with floating balloons
        SizedBox(
          width: 200,
          height: 160,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasPlayed)
                  const BalloonOverlay(
                    totalBalloons: null,
                    spawnInterval: Duration(milliseconds: 900),
                    colors: [
                      Color(0xFFE53935),
                      Color(0xFF1E88E5),
                      Color(0xFFFFB300),
                      Color(0xFF43A047),
                      Color(0xFFE040FB),
                      Color(0xFFFF7043),
                    ],
                    minSize: 18,
                    maxSize: 32,
                    minDuration: Duration(seconds: 3),
                    maxDuration: Duration(seconds: 6),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasPlayed ? '${stats.wins}' : '-',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: hasPlayed
                            ? AppColors.goldLight
                            : AppColors.goldPale.withValues(alpha: 0.4),
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'YOUR WINS',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Losses + Draws side by side
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              label: 'LOSSES',
              value: hasPlayed ? '${stats.losses}' : '-',
              color: AppColors.red,
            ),
            const SizedBox(width: 24),
            _StatChip(
              label: 'DRAWS',
              value: hasPlayed ? '${stats.draws}' : '-',
              color: AppColors.goldPale,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Stat chip ──────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: color.withValues(alpha: 0.70),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
