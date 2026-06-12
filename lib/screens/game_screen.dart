import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/ai_player.dart';
import '../models/difficulty.dart';
import '../models/game_logic.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../painters/board_painter.dart';
import '../theme/app_colors.dart';
import '../utils/game_timer.dart';
import '../utils/haptic_util.dart';
import '../utils/storage_service.dart';
import '../utils/time_format.dart';
export '../utils/storage_service.dart' show SavedGame;
import '../widgets/gradient_bg.dart';
import '../widgets/player_card.dart';

// How many history entries to pop for a full undo round (player + AI move)
const _kUndoSteps = 2;

class GameScreen extends StatefulWidget {
  final GameMode   mode;
  final Difficulty difficulty;
  final Player     humanPlayer; // which colour the human controls (VS Computer)
  final SavedGame? savedGame;   // non-null → resume a paused game
  const GameScreen({
    super.key,
    this.mode        = GameMode.twoPlayer,
    this.difficulty  = Difficulty.easy,
    this.humanPlayer = Player.blue,
    this.savedGame,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final _game = GameLogic();
  final _player = AudioPlayer();
  bool _aiThinking = false;
  bool _isPaused = false;
  bool _resultRecorded = false;

  // Hint state
  int? _hintFrom;
  int? _hintTo;

  late final GameTimer _gameTimer;
  Duration _timeLeft = GameTimer.duration;

  late AnimationController _pulse;
  late Animation<double> _pulseVal;

  bool get _vsComputer => widget.mode == GameMode.vsComputer;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseVal = Tween<double>(begin: 0.82, end: 1.18).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _gameTimer = GameTimer(
      onTick: (r) {
        if (mounted) setState(() => _timeLeft = r);
      },
      onExpired: () {
        if (mounted && _game.winner == null && !_game.isDraw) {
          setState(() => _game.declareDraw());
          _saveResult();
        }
      },
    );

    // Restore a previously paused game if one was passed in
    final saved = widget.savedGame;
    if (saved != null) {
      _game.restore(
        board:     saved.board,
        current:   saved.current,
        blueScore: saved.blueScore,
        redScore:  saved.redScore,
      );
      _timeLeft = saved.timeLeft;
      _gameTimer.startFrom(saved.timeLeft);
    } else {
      _gameTimer.start();
    }

    // If the AI moves first (human chose Red), kick off the first AI move
    if (_vsComputer && _game.current == widget.humanPlayer.opponent) {
      _scheduleAiMove();
    }
  }

  @override
  void dispose() {
    _gameTimer.dispose();
    _player.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ── Pause / Resume ────────────────────────────────

  void _pause() {
    if (_aiThinking || _game.winner != null || _game.isDraw) return;
    setState(() => _isPaused = true);
    _gameTimer.pause();
  }

  void _resume() {
    setState(() => _isPaused = false);
    _gameTimer.resume();
  }

  // ── Game actions ──────────────────────────────────

  // ── Hint & Undo ───────────────────────────────────

  void _requestHint() {
    if (_isPaused || _aiThinking) return;
    if (_game.winner != null || _game.isDraw) return;
    final (from, to) = AiPlayer.hintMove(List<Player?>.from(_game.board), widget.humanPlayer);
    if (from == -1) return;
    setState(() {
      _hintFrom = from;
      _hintTo   = to;
    });
  }

  void _clearHint() {
    if (_hintFrom == null) return;
    setState(() {
      _hintFrom = null;
      _hintTo   = null;
    });
  }

  void _undoRound() {
    if (_aiThinking || _isPaused) return;
    // Pop up to _kUndoSteps entries (player move + AI move = 1 full round)
    setState(() {
      for (int i = 0; i < _kUndoSteps; i++) {
        if (!_game.canUndo) break;
        _game.undo();
      }
      _hintFrom       = null;
      _hintTo         = null;
      _resultRecorded = false;
    });
    _gameTimer.resume(); // restart timer if it was stopped by a win
  }

  void _onTap(int node) {
    if (_isPaused || _aiThinking) return;
    if (_game.winner != null || _game.isDraw) return;
    if (_vsComputer && _game.current != widget.humanPlayer) return;

    _clearHint();
    final hadWinner = _game.winner;
    setState(() => _game.tap(node));

    if (hadWinner == null && _game.winner != null) {
      _gameTimer.stop();
      _saveResult();
      _player.play(AssetSource('sounds/cheer.mp3'));
      return;
    }

    if (_game.isDraw) {
      _saveResult();
      return;
    }

    if (_game.isWarning) {
      HapticUtil.warningPulse();
    }

    if (_vsComputer &&
        _game.winner == null &&
        !_game.isDraw &&
        _game.current == widget.humanPlayer.opponent) {
      _scheduleAiMove();
    }
  }

  void _scheduleAiMove() {
    setState(() => _aiThinking = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _isPaused) {
        setState(() => _aiThinking = false);
        return;
      }
      final board = List<Player?>.from(_game.board);
      final (from, to) = AiPlayer.bestMove(board, widget.difficulty, widget.humanPlayer.opponent);
      final hadWinner = _game.winner;
      setState(() {
        _game.aiMove(from, to);
        _aiThinking = false;
      });
      if (hadWinner == null && _game.winner != null) {
        _gameTimer.stop();
        _saveResult();
        _player.play(AssetSource('sounds/cheer.mp3'));
        return;
      }
      if (_game.isDraw) {
        _saveResult();
        return;
      }
      if (_game.isWarning) {
        HapticUtil.warningPulse();
      }
    });
  }

  /// Records the result exactly once per game round and clears any saved game.
  void _saveResult() {
    if (_resultRecorded) return;
    _resultRecorded = true;
    StorageService.clearSavedGame(); // game is over — no resuming
    if (_game.winner == widget.humanPlayer) {
      StorageService.addWin();
    } else if (_game.winner == widget.humanPlayer.opponent) {
      StorageService.addLoss();
    } else if (_game.isDraw) {
      StorageService.addDraw();
    }
  }

  /// Saves mid-game state so the player can resume from the home screen.
  Future<void> _saveGameForResume() async {
    if (_game.winner != null || _game.isDraw) return; // nothing to save
    await StorageService.saveGame(SavedGame(
      board:       List<Player?>.from(_game.board),
      current:     _game.current,
      blueScore:   _game.blueScore,
      redScore:    _game.redScore,
      timeLeft:    _gameTimer.timeLeft,
      mode:        widget.mode,
      difficulty:  widget.difficulty,
      humanPlayer: widget.humanPlayer,
    ));
  }

  void _onReset() {
    StorageService.clearSavedGame(); // fresh start — discard any paused game
    setState(() {
      _game.reset();
      _aiThinking     = false;
      _isPaused       = false;
      _resultRecorded = false;
      _timeLeft       = GameTimer.duration;
      _hintFrom       = null;
      _hintTo         = null;
    });
    _gameTimer.start();
    // If human plays Red, AI (Blue) goes first
    if (_vsComputer && _game.current == widget.humanPlayer.opponent) {
      _scheduleAiMove();
    }
  }

  // ── Build ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveGameForResume();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        body: GradientBg(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildScoreRow(),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildBoard(),
                          if (_isPaused) _buildPauseOverlay(),
                        ],
                      ),
                    ),
                    _buildStatusBar(),
                    if (_vsComputer) _buildUndoHintRow(),
                    _buildResetButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final isLow =
        _timeLeft.inMinutes < 5 && !_game.isDraw && _game.winner == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.goldPale, size: 20),
            onPressed: () async {
              await _saveGameForResume();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              'KISIMA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.goldLight,
                letterSpacing: 3,
              ),
            ),
          ),
          // Pause button
          if (_game.winner == null && !_game.isDraw)
            IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: AppColors.midBrown,
                size: 30,
              ),
              onPressed: _isPaused ? _resume : _pause,
            )
          else
            const SizedBox(width: 48),
          // Countdown clock
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TimeFormat.countdown(_timeLeft),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLow ? AppColors.red : AppColors.goldPale,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                'TIME',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.midBrown,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Score row ─────────────────────────────────────

  Widget _buildScoreRow() {
    final g = _game;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: PlayerCard(
              player: Player.blue,
              isActive: g.current == Player.blue && g.winner == null,
              isWinner: g.winner == Player.blue,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _scoreLabel(),
          ),
          Expanded(
            child: PlayerCard(
              player: Player.red,
              isActive: g.current == Player.red && g.winner == null,
              isWinner: g.winner == Player.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreLabel() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_game.blueScore} : ${_game.redScore}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.cream,
            ),
          ),
          const Text(
            'SCORE',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.gold,
              letterSpacing: 2,
            ),
          ),
        ],
      );

  // ── Board ─────────────────────────────────────────

  Widget _buildBoard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _homeLabel('BLUE HOME', AppColors.blue),
        const SizedBox(height: 4),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(builder: (_, bc) {
                return GestureDetector(
                  onTapUp: (d) {
                    final node = _game.hitTest(d.localPosition, bc.maxWidth);
                    if (node != null) _onTap(node);
                  },
                  child: AnimatedBuilder(
                    animation: _pulseVal,
                    builder: (_, __) => CustomPaint(
                      size: Size.square(bc.maxWidth),
                      painter: BoardPainter(
                        board: _game.board,
                        current: _game.current,
                        selected: _game.selected,
                        validMoves: _game.validMoves,
                        winner: _game.winner,
                        winLine: _game.winLine,
                        pulse: _pulseVal.value,
                        hintFrom: _hintFrom,
                        hintTo: _hintTo,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _homeLabel('RED HOME', AppColors.red),
      ],
    );
  }

  Widget _homeLabel(String text, Color color) => Text(
        text,
        style: TextStyle(
          color: color.withValues(alpha: 0.75),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.5,
        ),
      );

  // ── Pause overlay ─────────────────────────────────

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pause_circle_outline,
                color: AppColors.goldLight, size: 56),
            const SizedBox(height: 14),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: AppColors.goldLight,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 32),
            _overlayButton(
              label: 'RESUME',
              icon: Icons.play_arrow,
              color: AppColors.gold,
              onTap: _resume,
            ),
            const SizedBox(height: 14),
            _overlayButton(
              label: 'NEW GAME',
              icon: Icons.refresh,
              color: AppColors.midBrown,
              onTap: _onReset,
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(letterSpacing: 2)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: const Color(0xFF1E0B02),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ── Status bar ────────────────────────────────────

  Widget _buildStatusBar() {
    final isOver = _game.winner != null || _game.isDraw;
    final message = _aiThinking ? 'Computer is thinking…' : _game.message;
    final dotColor = _game.isDraw
        ? AppColors.goldPale
        : _game.winner == Player.blue
            ? AppColors.blue
            : _game.winner == Player.red
                ? AppColors.red
                : _game.current == Player.blue
                    ? AppColors.blue
                    : AppColors.red;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: const Color(0x445A2C0E)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isOver ? 16 : 13,
                fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                color: AppColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Undo / Hint row (VS Computer only) ───────────

  Widget _buildUndoHintRow() {
    final gameOver  = _game.winner != null || _game.isDraw;
    final canUndo   = _game.canUndo && !_aiThinking && !_isPaused && !gameOver;
    final canHint   = !_aiThinking && !_isPaused && !gameOver &&
                      _game.current == widget.humanPlayer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconActionButton(
            icon:    Icons.undo,
            label:   'Undo',
            color:   AppColors.goldPale,
            enabled: canUndo,
            onTap:   _undoRound,
          ),
          const SizedBox(width: 24),
          _iconActionButton(
            icon:    Icons.lightbulb_outline,
            label:   _hintFrom != null ? 'Clear hint' : 'Hint',
            color:   AppColors.gold,
            enabled: canHint || _hintFrom != null,
            onTap:   _hintFrom != null ? _clearHint : _requestHint,
          ),
        ],
      ),
    );
  }

  Widget _iconActionButton({
    required IconData     icon,
    required String       label,
    required Color        color,
    required bool         enabled,
    required VoidCallback onTap,
  }) {
    final c = enabled ? color : color.withValues(alpha: 0.28);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 26),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Reset button ──────────────────────────────────

  Widget _buildResetButton() {
    return ElevatedButton.icon(
      onPressed: _onReset,
      icon: const Icon(Icons.refresh, size: 18),
      label: Text(
          (_game.winner != null || _game.isDraw) ? 'Play Again' : 'New Game'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF1E0B02),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
