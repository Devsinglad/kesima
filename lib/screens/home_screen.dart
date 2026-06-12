import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../painters/mini_board_painter.dart';
import '../theme/app_colors.dart';
import '../utils/storage_service.dart';
import '../widgets/gradient_bg.dart';
import '../widgets/home_chips.dart';
import '../widgets/rules_sheet.dart';
import '../widgets/stats_panel.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameMode   _mode        = GameMode.vsComputer;
  Difficulty _difficulty  = Difficulty.easy;
  Player     _humanPlayer = Player.blue;
  GameStats  _stats       = const GameStats(wins: 0, losses: 0, draws: 0);
  SavedGame? _savedGame;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final results = await Future.wait([
      StorageService.loadStats(),
      StorageService.loadSavedGame(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats     = results[0] as GameStats;
      _savedGame = results[1] as SavedGame?;
    });
  }

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode:        _mode,
          difficulty:  _difficulty,
          humanPlayer: _mode == GameMode.vsComputer ? _humanPlayer : Player.blue,
        ),
      ),
    ).then((_) => _refresh());
  }

  void _resumeGame() {
    final saved = _savedGame;
    if (saved == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode:        saved.mode,
          difficulty:  saved.difficulty,
          humanPlayer: saved.humanPlayer,
          savedGame:   saved,
        ),
      ),
    ).then((_) => _refresh());
  }

  // ── Build ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBg(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
              children: [
                _title(),
                const SizedBox(height: 10),
                StatsPanel(stats: _stats),
                const SizedBox(height: 10),
                _miniBoard(),
                const SizedBox(height: 12),
                _vsRow(),
                const SizedBox(height: 18),
                _modeSelector(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _mode == GameMode.vsComputer
                      ? _difficultySelector()
                      : const SizedBox.shrink(),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _mode == GameMode.vsComputer
                      ? _colorSelector()
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),
                if (_savedGame != null) ...[
                  _resumeButton(),
                  const SizedBox(height: 10),
                ],
                _playButton(context),
                const SizedBox(height: 10),
                _howToPlayButton(context),
                const SizedBox(height: 12),
                _footer(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }

  // ── Static section widgets ────────────────────────

  Widget _title() => const Column(
        children: [
          Text(
            'KISIMA',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.goldLight,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Shisima  ·  Traditional Kenyan Game',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.goldPale,
              letterSpacing: 1.5,
            ),
          ),
        ],
      );

  Widget _miniBoard() => SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(painter: MiniBoardPainter()),
      );

  Widget _vsRow() => const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZoneChip(color: AppColors.blue, label: 'BLUE', sub: 'Top row'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'VS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.goldPale,
              ),
            ),
          ),
          ZoneChip(color: AppColors.red, label: 'RED', sub: 'Bottom row'),
        ],
      );

  // ── Selectors ─────────────────────────────────────

  Widget _modeSelector() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            ModeChip(
              label: 'VS COMPUTER',
              icon: Icons.smart_toy_outlined,
              selected: _mode == GameMode.vsComputer,
              onTap: () => setState(() => _mode = GameMode.vsComputer),
            ),
            const SizedBox(width: 12),
            ModeChip(
              label: '2 PLAYERS',
              icon: Icons.people_outline,
              selected: _mode == GameMode.twoPlayer,
              onTap: () => setState(() => _mode = GameMode.twoPlayer),
            ),
          ],
        ),
      );

  Widget _difficultySelector() => Padding(
        padding: const EdgeInsets.fromLTRB(40, 12, 40, 0),
        child: Row(
          children: Difficulty.values.map((d) {
            final sel   = _difficulty == d;
            final color = _difficultyColor(d);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: d != Difficulty.values.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _difficulty = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? color : color.withValues(alpha: 0.25),
                        width: sel ? 2 : 1,
                      ),
                      color: sel
                          ? color.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    child: Text(
                      d.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: sel ? color : color.withValues(alpha: 0.50),
                        fontSize: 11,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _colorSelector() => Padding(
        padding: const EdgeInsets.fromLTRB(40, 12, 40, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                'YOU PLAY',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.goldPale,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                ColorChip(
                  color: AppColors.blue,
                  label: 'BLUE',
                  sub: 'Goes first',
                  selected: _humanPlayer == Player.blue,
                  onTap: () => setState(() => _humanPlayer = Player.blue),
                ),
                const SizedBox(width: 12),
                ColorChip(
                  color: AppColors.red,
                  label: 'RED',
                  sub: 'Goes second',
                  selected: _humanPlayer == Player.red,
                  onTap: () => setState(() => _humanPlayer = Player.red),
                ),
              ],
            ),
          ],
        ),
      );

  Color _difficultyColor(Difficulty d) => switch (d) {
        Difficulty.easy   => const Color(0xFF4CAF50),
        Difficulty.medium => AppColors.gold,
        Difficulty.hard   => AppColors.red,
      };

  // ── Action buttons ────────────────────────────────

  Widget _resumeButton() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _resumeGame,
            icon: const Icon(Icons.play_arrow, size: 20),
            label: Text(
              _savedGame?.mode == GameMode.vsComputer
                  ? 'RESUME  VS  COMPUTER'
                  : 'RESUME  2  PLAYERS',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E6B3E),
              foregroundColor: const Color(0xFFD4F1DE),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      );

  Widget _playButton(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF1E0B02),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'P  L  A  Y',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
      );

  Widget _howToPlayButton(BuildContext context) => TextButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const RulesSheet(),
        ),
        child: const Text(
          'HOW TO PLAY',
          style: TextStyle(
            color: AppColors.goldPale,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
      );

  Widget _footer() {
    if (_mode == GameMode.twoPlayer) {
      return const Text(
        '2 PLAYERS  ·  LOCAL  ·  NO ACCOUNT NEEDED',
        style: TextStyle(fontSize: 10, color: Color(0xFF8B6020), letterSpacing: 1.5),
      );
    }
    final colorLabel = _humanPlayer == Player.blue ? 'BLUE' : 'RED';
    return Text(
      'VS COMPUTER  ·  ${_difficulty.label.toUpperCase()}  ·  YOU PLAY $colorLabel',
      style: const TextStyle(fontSize: 10, color: Color(0xFF8B6020), letterSpacing: 1.5),
    );
  }
}
