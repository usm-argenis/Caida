/// Constantes del juego Caída
class GameConstants {
  GameConstants._();

  /// Valores válidos del mazo (no hay 8 ni 9)
  static const List<int> validValues = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

  /// Secuencia numérica válida para el juego
  static const List<int> sequence = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

  /// Total de cartas en el mazo
  static const int deckSize = 40; // 10 valores × 4 palos

  /// Cartas por mano
  static const int handSize = 3;

  /// Número de jugadores
  static const int playerCount = 4;

  /// Puntos para ganar
  static const int winScore = 24;

  /// Puntos de canto por tipo de Ronda (pares)
  static const Map<int, int> rondaPoints = {
    1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, // Pares de 1 al 7 = 1 punto
    10: 2, // Par de sotas = 2 puntos
    11: 3, // Par de caballos = 3 puntos
    12: 4, // Par de reyes = 4 puntos
  };

  static const int patrullaPoints = 6;
  static const int vigiaPoints = 7;
  static const int registroPoints = 8;
  static const int tribilinPoints = 5; // En ronda del medio; en ronda 1/3 gana la partida

  /// Secuencias válidas de patrulla (secuencias de 3 consecutivas, considerando que después del 7 viene el 10)
  static const List<List<int>> patrullaSequences = [
    [1, 2, 3],
    [2, 3, 4],
    [3, 4, 5],
    [4, 5, 6],
    [5, 6, 7],
    [6, 7, 10],
    [7, 10, 11],
    [10, 11, 12],
  ];

  /// Obtiene el índice de un valor en la secuencia
  static int sequenceIndex(int value) => sequence.indexOf(value);

  /// Obtiene el siguiente valor en la secuencia
  static int? nextInSequence(int value) {
    final idx = sequenceIndex(value);
    if (idx == -1 || idx == sequence.length - 1) return null;
    return sequence[idx + 1];
  }

  /// Obtiene el valor anterior en la secuencia
  static int? prevInSequence(int value) {
    final idx = sequenceIndex(value);
    if (idx <= 0) return null;
    return sequence[idx - 1];
  }

  /// ¿Son consecutivos?
  static bool areConsecutive(int a, int b) {
    return nextInSequence(a) == b || nextInSequence(b) == a;
  }
}
