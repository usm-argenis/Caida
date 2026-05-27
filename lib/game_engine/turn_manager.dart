import '../models/player_model.dart';
import '../models/game_state_model.dart';

/// Motor de manejo de turnos
class TurnManager {
  TurnManager._();

  /// Avanza al siguiente jugador
  static GameStateModel nextTurn(GameStateModel state) {
    int next = (state.currentPlayerIndex + 1) % state.players.length;
    return state.copyWith(
      currentPlayerIndex: next,
      message: '${state.players[next].name} - Tu turno',
    );
  }

  /// Determina si es el turno del jugador humano
  static bool isHumanTurn(GameStateModel state) {
    return state.currentPlayer.type == PlayerType.human;
  }

  /// Verifica si todos los jugadores han jugado en esta ronda
  static bool allPlayersPlayed(GameStateModel state) {
    return state.players.every((p) => p.hand.isEmpty);
  }

  /// Obtiene el siguiente jugador en orden desde el repartidor
  static int getFirstPlayerIndex(int dealerIndex, int playerCount) {
    return (dealerIndex + 1) % playerCount;
  }
}
