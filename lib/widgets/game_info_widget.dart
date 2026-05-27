import 'package:flutter/material.dart';
import '../models/game_state_model.dart';
import '../core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Panel de información del estado del turno y cantos
class GameInfoWidget extends StatelessWidget {
  final GameStateModel gameState;

  const GameInfoWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppTheme.glassDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Estado del turno y ro
          // Mensaje del juego
          if (gameState.message != null) ...[
            const SizedBox(height: 8),
            Text(
              gameState.message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          // Cantos de la ronda
          if (gameState.cantos.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCantosRow(),
          ],
          // Mesa limpia indicator
          if (gameState.mesaLimpia) ...[
            const SizedBox(height: 8),
            _buildMesaLimpiaChip(),
          ],
        ],
      ),
    );
  }



  Widget _buildCantosRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: gameState.cantos.map((canto) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
          ),
          child: Text(
            '${canto.typeName} (${canto.points} pts)',
            style: GoogleFonts.lato(
              color: AppTheme.warning,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMesaLimpiaChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🎉 ¡MESA LIMPIA!',
        style: GoogleFonts.cinzel(
          color: AppTheme.background,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
