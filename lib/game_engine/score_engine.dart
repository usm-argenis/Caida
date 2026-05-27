import '../models/player_model.dart';
import '../models/game_state_model.dart';
import '../models/canto_model.dart';

/// Motor de puntuación del juego
class ScoreEngine {
  ScoreEngine._();

  /// Aplica los puntos del canto ganador al jugador correspondiente
  static GameStateModel applyCantoScore(
      GameStateModel state, CantoModel winnerCanto) {
    final players = state.players.map((player) {
      if (player.id == winnerCanto.playerId) {
        return player.copyWith(score: player.score + winnerCanto.points);
      }
      // En modo parejas, el compañero también recibe puntos
      if (state.mode == GameMode.teams) {
        final winner =
            state.players.firstWhere((p) => p.id == winnerCanto.playerId);
        if (player.teamIndex == winner.teamIndex &&
            player.id != winner.id) {
          // Los puntos van al jugador que cantó, no repartidos
        }
      }
      return player;
    }).toList();

    return state.copyWith(
      players: players,
      message:
          '${state.players.firstWhere((p) => p.id == winnerCanto.playerId).name} gana el canto: ${winnerCanto.description}',
    );
  }

  /// Al final de la ronda, otorga 1 punto al jugador con más cartas capturadas
  static GameStateModel applyRoundScore(GameStateModel state) {
    if (state.mode == GameMode.individual) {
      return _applyIndividualRoundScore(state);
    } else {
      return _applyTeamRoundScore(state);
    }
  }

  static GameStateModel _applyIndividualRoundScore(GameStateModel state) {
    List<PlayerModel> updated = state.players.map((player) {
      // Regla: Después de 10 cartas, cada carta es 1 punto
      int points = 0;
      if (player.capturedCount > 10) {
        points = player.capturedCount - 10;
      }

      return player.copyWith(
        score: player.score + points,
        // No reseteamos capturedCount aquí para mostrarlo en el panel de fin de ronda
      );
    }).toList();

    final buffer = StringBuffer('Conteo de cartas reunidas:\n');
    for (final p in state.players) {
      final points = p.capturedCount > 10 ? p.capturedCount - 10 : 0;
      buffer.write('• ${p.name}: ${p.capturedCount} cartas (+$points pts)\n');
    }

    return state.copyWith(
      players: updated,
      message: buffer.toString().trim(),
    );
  }

  static GameStateModel _applyTeamRoundScore(GameStateModel state) {
    final team0Count = state.players
        .where((p) => p.teamIndex == 0)
        .fold(0, (sum, p) => sum + p.capturedCount);

    final team1Count = state.players
        .where((p) => p.teamIndex == 1)
        .fold(0, (sum, p) => sum + p.capturedCount);

    // Regla: Después de 20 cartas por equipo, cada carta es 1 punto
    int team0Points = team0Count > 20 ? team0Count - 20 : 0;
    int team1Points = team1Count > 20 ? team1Count - 20 : 0;

    final updated = state.players.map((player) {
      int pointsToAdd = (player.teamIndex == 0) ? team0Points : team1Points;
      final firstInTeamId = state.players.firstWhere((p) => p.teamIndex == player.teamIndex).id;
      
      return player.copyWith(
        score: player.id == firstInTeamId ? player.score + pointsToAdd : player.score,
        // No reseteamos capturedCount aquí para mostrarlo en el panel de fin de ronda
      );
    }).toList();

    return state.copyWith(
      players: updated,
      message: 'Tarjetas reunidas por equipo:\n'
          '• Equipo A (Tú/Compañero): $team0Count cartas (+$team0Points pts)\n'
          '• Equipo B (Rivales): $team1Count cartas (+$team1Points pts)',
    );
  }

  /// Añade puntos de mesa limpia (1 punto extra)
  static GameStateModel applyMesaLimpiaBonus(
      GameStateModel state, String playerId) {
    final updated = state.players.map((player) {
      if (player.id == playerId) {
        return player.copyWith(score: player.score + 4);
      }
      return player;
    }).toList();

    final playerName =
        state.players.firstWhere((p) => p.id == playerId).name;

    return state.copyWith(
      players: updated,
      message: '¡MESA LIMPIA! $playerName gana +4 puntos extra',
    );
  }
}
