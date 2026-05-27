import '../models/card_model.dart';
import '../models/game_state_model.dart';
import '../core/game_constants.dart';

/// Motor de validación de reglas del juego
class RulesEngine {
  RulesEngine._();

  /// ¿Puede el jugador actual jugar esta carta?
  static bool canPlayCard(GameStateModel state, CardModel card) {
    if (state.phase != GamePhase.playing) return false;
    if (!state.currentPlayer.hand.contains(card) && state.animatingPlayCard?.id != card.id) {
      return false;
    }
    return true;
  }

  /// ¿El juego ha terminado? (alguien llegó a 24 puntos)
  static bool isGameOver(GameStateModel state) {
    return state.winner != null;
  }

  /// ¿Hay que comenzar nueva ronda? (todos vaciaron la mano)
  static bool shouldStartNewRound(GameStateModel state) {
    return state.players.every((p) => p.hand.isEmpty) &&
        state.deck.isNotEmpty;
  }

  /// ¿Hay que iniciar la fase de canto?
  /// Solo en la primera ronda (roundNumber == 1)
  static bool shouldStartCantoPhase(GameStateModel state) {
    return state.roundNumber == 1 && !state.cantoPhaseComplete;
  }

  /// Valida que el mazo tenga los valores correctos (sin 8 ni 9) y que no haya duplicados
  static bool validateDeck(List<CardModel> deck) {
    if (deck.length != GameConstants.deckSize) return false;

    // Verificar que no haya duplicados de palo y valor
    final seen = <String>{};
    for (final card in deck) {
      final key = '${card.value}_${card.suit}';
      if (seen.contains(key)) return false;
      seen.add(key);
    }

    final invalidCards =
        deck.where((c) => !GameConstants.validValues.contains(c.value));
    return invalidCards.isEmpty;
  }

  /// ¿Es una jugada válida de lanzar a la mesa sin capturar?
  static bool isValidPlay(CardModel card, List<CardModel> mesa) {
    // Siempre se puede lanzar una carta a la mesa
    return true;
  }

  /// Verifica si hay condición de victoria
  static String? checkVictoryCondition(GameStateModel state) {
    if (state.mode == GameMode.individual) {
      for (final player in state.players) {
        if (player.score >= GameConstants.winScore) {
          return '¡${player.name} ha ganado con ${player.score} puntos!';
        }
      }
    } else {
      if (state.team0Score >= GameConstants.winScore) {
        final teamPlayers =
            state.players.where((p) => p.teamIndex == 0).toList();
        return '¡Equipo ${teamPlayers.map((p) => p.name).join(' & ')} ha ganado!';
      }
      if (state.team1Score >= GameConstants.winScore) {
        final teamPlayers =
            state.players.where((p) => p.teamIndex == 1).toList();
        return '¡Equipo ${teamPlayers.map((p) => p.name).join(' & ')} ha ganado!';
      }
    }
    return null;
  }
}
