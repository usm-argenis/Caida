import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state_model.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';
import '../core/app_theme.dart';
import 'home_screen.dart';
import 'game_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla de fin de juego
class GameOverScreen extends ConsumerStatefulWidget {
  final GameStateModel gameState;

  const GameOverScreen({super.key, required this.gameState});

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PlayerModel? _getWinner() {
    return widget.gameState.winner;
  }

  @override
  Widget build(BuildContext context) {
    final winner = _getWinner();
    final isTeamMode = widget.gameState.mode == GameMode.teams;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Trophy animation
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Column(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 80)),
                          const SizedBox(height: 16),
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppTheme.goldGradient.createShader(bounds),
                            child: Text(
                              '¡GANADOR!',
                              style: GoogleFonts.cinzel(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Winner info
                    if (winner != null)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.2),
                              AppTheme.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isTeamMode ? Icons.people : Icons.person,
                              color: AppTheme.primary,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isTeamMode
                                  ? 'Equipo ${winner.teamIndex + 1}'
                                  : winner.name,
                              style: GoogleFonts.cinzel(
                                color: AppTheme.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isTeamMode) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.gameState.players
                                    .where(
                                        (p) => p.teamIndex == winner.teamIndex)
                                    .map((p) => p.name)
                                    .join(' & '),
                                style: GoogleFonts.lato(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                isTeamMode
                                    ? '${winner.teamIndex == 0 ? widget.gameState.team0Score : widget.gameState.team1Score} PUNTOS'
                                    : '${winner.score} PUNTOS',
                                style: GoogleFonts.cinzel(
                                  color: AppTheme.background,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Score table
                    _buildScoreTable(),

                    const SizedBox(height: 40),

                    // Action buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ref.read(gameProvider.notifier).rematch();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const GameScreen()),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('REVANCHA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ).copyWith(
                              backgroundColor:
                                  WidgetStateProperty.all(AppTheme.primary),
                              foregroundColor:
                                  WidgetStateProperty.all(AppTheme.background),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref.read(gameProvider.notifier).resetGame();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const HomeScreen()),
                                (_) => false,
                              );
                            },
                            icon: const Icon(Icons.home),
                            label: const Text('MENÚ PRINCIPAL'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PUNTUACIÓN FINAL',
            style: GoogleFonts.cinzel(
              color: AppTheme.primary,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.gameState.players.map((player) {
            final isWinner = player.id == widget.gameState.winner?.id ||
                (widget.gameState.mode == GameMode.teams &&
                    player.teamIndex == widget.gameState.winner?.teamIndex);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (isWinner)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text('🏆', style: TextStyle(fontSize: 16)),
                    )
                  else
                    const SizedBox(width: 28),
                  Icon(
                    player.type == PlayerType.human
                        ? Icons.person
                        : Icons.smart_toy,
                    color: isWinner ? AppTheme.primary : AppTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.name,
                      style: GoogleFonts.lato(
                        color: isWinner
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                        fontWeight: isWinner
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${player.score} pts',
                    style: GoogleFonts.cinzel(
                      color: isWinner ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
