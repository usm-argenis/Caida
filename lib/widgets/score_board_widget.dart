import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/game_state_model.dart';
import '../core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Marcador de puntuación para todos los jugadores
class ScoreBoardWidget extends StatelessWidget {
  final GameStateModel gameState;

  const ScoreBoardWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassDecoration,
      child: gameState.mode == GameMode.teams
          ? _buildTeamScore()
          : _buildIndividualScore(),
    );
  }

  Widget _buildIndividualScore() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: gameState.players
          .map((p) => _PlayerScoreChip(
                player: p,
                isCurrent:
                    p.id == gameState.currentPlayer.id &&
                        gameState.phase == GamePhase.playing,
              ))
          .toList(),
    );
  }

  Widget _buildTeamScore() {
    final team0 = gameState.players.where((p) => p.teamIndex == 0).toList();
    final team1 = gameState.players.where((p) => p.teamIndex == 1).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TeamScoreChip(
          players: team0,
          score: gameState.team0Score,
          label: 'Equipo 1',
          color: AppTheme.accent,
        ),
        Container(
          width: 2,
          height: 40,
          color: AppTheme.primary.withOpacity(0.3),
        ),
        _TeamScoreChip(
          players: team1,
          score: gameState.team1Score,
          label: 'Equipo 2',
          color: AppTheme.warning,
        ),
      ],
    );
  }
}

class _PlayerScoreChip extends StatelessWidget {
  final PlayerModel player;
  final bool isCurrent;

  const _PlayerScoreChip({
    required this.player,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primary
              : AppTheme.primary.withOpacity(0.2),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                player.type == PlayerType.human
                    ? Icons.person
                    : Icons.smart_toy,
                size: 14,
                color: isCurrent ? AppTheme.primary : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                player.name.length > 7
                    ? '${player.name.substring(0, 7)}...'
                    : player.name,
                style: GoogleFonts.lato(
                  color: isCurrent ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${player.score} / 24',
            style: GoogleFonts.cinzel(
              color: isCurrent ? AppTheme.primary : AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Barra de progreso
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: player.score / 24,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation(
                isCurrent ? AppTheme.primary : AppTheme.accent,
              ),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamScoreChip extends StatelessWidget {
  final List<PlayerModel> players;
  final int score;
  final String label;
  final Color color;

  const _TeamScoreChip({
    required this.players,
    required this.score,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.cinzel(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: GoogleFonts.cinzel(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          players.map((p) => p.name).join(' & '),
          style: GoogleFonts.lato(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(
            value: score / 24,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
