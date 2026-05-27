import '../models/card_model.dart';
import '../models/canto_model.dart';
import '../core/game_constants.dart';

/// Motor de evaluación de cantos
class CantoEngine {
  CantoEngine._();

  /// Evalúa el mejor canto posible para una mano de 3 cartas
  static CantoModel? evaluateBestCanto(
      List<CardModel> hand, String playerId) {
    if (hand.length != 3) return null;

    // Evaluar en orden descendente de prioridad
    // Tribilín es el más alto de todos
    final tribilin = _checkTribilin(hand, playerId);
    if (tribilin != null) return tribilin;

    final registro = _checkRegistro(hand, playerId);
    if (registro != null) return registro;

    final vigia = _checkVigia(hand, playerId);
    if (vigia != null) return vigia;

    final patrulla = _checkPatrulla(hand, playerId);
    if (patrulla != null) return patrulla;

    final ronda = _checkRonda(hand, playerId);
    if (ronda != null) return ronda;

    return null;
  }

  /// Verifica si hay TRIBILÍN: las 3 cartas tienen el mismo número
  static CantoModel? _checkTribilin(List<CardModel> hand, String playerId) {
    if (hand.length != 3) return null;
    final values = hand.map((c) => c.value).toList();
    if (values[0] == values[1] && values[1] == values[2]) {
      return CantoModel(
        type: CantoType.tribilin,
        points: GameConstants.tribilinPoints,
        cards: hand,
        playerId: playerId,
      );
    }
    return null;
  }


  /// Verifica si hay REGISTRO: 1, 11, 12 (en cualquier palo)
  static CantoModel? _checkRegistro(
      List<CardModel> hand, String playerId) {
    final values = hand.map((c) => c.value).toSet();
    if (values.containsAll({1, 11, 12})) {
      return CantoModel(
        type: CantoType.registro,
        points: GameConstants.registroPoints,
        cards: hand,
        playerId: playerId,
      );
    }
    return null;
  }

  /// Verifica si hay VIGÍA: par + una consecutiva
  /// Ej: 2,2,1 o 7,7,10 o 2,2,3
  static CantoModel? _checkVigia(
      List<CardModel> hand, String playerId) {
    final values = hand.map((c) => c.value).toList();

    // Encontrar el par
    for (int i = 0; i < values.length; i++) {
      for (int j = i + 1; j < values.length; j++) {
        if (values[i] == values[j]) {
          final pairValue = values[i];
          // Encontrar índice de la carta que NO es el par
          int? thirdValue;
          for (int k = 0; k < values.length; k++) {
            if (k != i && k != j) {
              thirdValue = values[k];
              break;
            }
          }

          if (thirdValue != null) {
            final prevVal = GameConstants.prevInSequence(pairValue);
            final nextVal = GameConstants.nextInSequence(pairValue);
            if (thirdValue == prevVal || thirdValue == nextVal) {
              return CantoModel(
                type: CantoType.vigia,
                points: GameConstants.vigiaPoints,
                cards: hand,
                playerId: playerId,
              );
            }
          }
          break;
        }
      }
    }
    return null;
  }

  /// Verifica si hay PATRULLA: 3 consecutivas según las secuencias válidas (considerando que no hay 8 ni 9)
  static CantoModel? _checkPatrulla(
      List<CardModel> hand, String playerId) {
    if (hand.length != 3) return null;
    final values = hand.map((c) => c.value).toList();

    // Obtener los índices de los valores de las cartas en la secuencia numérica del juego
    final indices = values.map((val) => GameConstants.sequence.indexOf(val)).toList();
    if (indices.any((idx) => idx == -1)) return null;

    // Ordenar los índices para comprobar consecutividad
    indices.sort();

    if (indices[0] + 1 == indices[1] && indices[1] + 1 == indices[2]) {
      return CantoModel(
        type: CantoType.patrulla,
        points: GameConstants.patrullaPoints,
        cards: hand,
        playerId: playerId,
      );
    }
    return null;
  }

  /// Verifica si hay RONDA: par de 2, 10, 11, o 12
  static CantoModel? _checkRonda(
      List<CardModel> hand, String playerId) {
    final values = hand.map((c) => c.value).toList();

    for (final entry in GameConstants.rondaPoints.entries) {
      final targetValue = entry.key;
      final points = entry.value;

      int count = values.where((v) => v == targetValue).length;
      if (count >= 2) {
        return CantoModel(
          type: CantoType.ronda,
          points: points,
          cards: hand,
          playerId: playerId,
        );
      }
    }
    return null;
  }

  /// Determina el ganador del canto entre varios cantos
  /// En empate de puntos, gana el de mayor valor de cartas
  static CantoModel? determineBestCanto(List<CantoModel> cantos) {
    if (cantos.isEmpty) return null;

    CantoModel best = cantos.first;
    for (final canto in cantos.skip(1)) {
      if (canto.points > best.points) {
        best = canto;
      } else if (canto.points == best.points) {
        // Desempate por mayor valor
        final cantoMaxVal = canto.cards.map((c) => c.value).reduce(
            (a, b) => a > b ? a : b);
        final bestMaxVal = best.cards.map((c) => c.value).reduce(
            (a, b) => a > b ? a : b);
        if (cantoMaxVal > bestMaxVal) {
          best = canto;
        }
      }
    }
    return best;
  }
}
