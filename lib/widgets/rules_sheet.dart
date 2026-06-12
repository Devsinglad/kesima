import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RulesSheet extends StatelessWidget {
  const RulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      maxChildSize: 0.95,
      minChildSize: 0.40,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A1008),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.midBrown,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Center(
              child: Text(
                'HOW TO PLAY',
                style: TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Shisima  ·  Traditional Kenyan Game',
                style: TextStyle(
                  color: AppColors.goldPale,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),

            const _RuleItem(
              icon: Icons.grid_on,
              title: 'The Board',
              body:
                  '11 nodes connected by lines. The top row (3 nodes) is '
                  'Blue\'s home. The bottom row (3 nodes) is Red\'s home. '
                  'Between them sits a circle with a center hub — pieces '
                  'travel through here to reach the other side.',
            ),

            const _RuleItem(
              icon: Icons.sports_soccer,
              title: 'Starting Positions',
              body:
                  'Blue starts with all 3 pieces on the top row.\n'
                  'Red starts with all 3 pieces on the bottom row.\n'
                  'The 5 middle nodes (circle + hub) begin empty.',
            ),

            const _RuleItem(
              icon: Icons.touch_app_outlined,
              title: 'How to Move',
              body:
                  '1. Tap one of your pieces — it glows and valid destination '
                  'nodes light up in amber.\n'
                  '2. Tap a highlighted node to slide your piece there.\n'
                  '3. Tap your selected piece again to cancel the selection.\n\n'
                  'You can only move one step at a time along the lines. '
                  'You cannot jump over another piece.',
            ),

            const _RuleItem(
              icon: Icons.emoji_events_outlined,
              title: 'How to Win',
              body:
                  'Move all 3 of your pieces into the opponent\'s home row:\n\n'
                  '• Blue wins by filling the bottom row (Red\'s home).\n'
                  '• Red wins by filling the top row (Blue\'s home).\n\n'
                  'The first player to place all 3 pieces in the opponent\'s '
                  'home wins the round and earns a point.',
            ),

            const _RuleItem(
              icon: Icons.lock_outline,
              title: 'Blocked = You Lose',
              body:
                  'If it is your turn and none of your pieces have a valid '
                  'move, you are completely trapped and you lose the round '
                  'immediately.\n\n'
                  'This is the official Shisima rule — blocking your opponent '
                  'is a legitimate winning strategy, so always keep an escape '
                  'route open!',
            ),

            const _RuleItem(
              icon: Icons.vibration,
              title: 'Danger Warning',
              body:
                  'When you are one move away from being completely trapped, '
                  'the board shows a danger message and your device vibrates '
                  'three times as an alert. Heed the warning — rethink your '
                  'next move carefully.',
            ),

            const _RuleItem(
              icon: Icons.timer_outlined,
              title: '30-Minute Draw',
              body:
                  'A countdown timer runs in the top-right corner. If neither '
                  'player wins within 30 minutes, the game is declared a draw. '
                  'The timer turns red when under 5 minutes remain.',
            ),

            const _RuleItem(
              icon: Icons.smart_toy_outlined,
              title: 'VS Computer Mode',
              body:
                  'You always play as Blue (top row). The computer plays as '
                  'Red and thinks automatically after your move. '
                  'It uses a strategic AI, so it will not make easy mistakes — '
                  'plan your invasion carefully!',
            ),

            const _RuleItem(
              icon: Icons.lightbulb_outline,
              title: 'Strategy Tips',
              body:
                  '• The center hub connects to every direction — whoever '
                  'controls it controls the board.\n'
                  '• Do not leave all your pieces on one side of the circle; '
                  'spread them so you always have moves available.\n'
                  '• Watch the opponent\'s pieces: if you can force them into '
                  'a corner, they lose without needing to reach home.',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rule item ─────────────────────────────────────

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   body;
  const _RuleItem({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              body,
              style: const TextStyle(
                color: Color(0xFFD4C4A0),
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
