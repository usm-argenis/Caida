import '../models/card_model.dart';
import '../core/game_constants.dart';

/// Resultado de un intento de captura
class CaptureResult {
  final bool success;
  final List<CardModel> capturedCards;
  final bool mesaLimpia; // Si se capturó la última carta de la mesa

  const CaptureResult({
    required this.success,
    required this.capturedCards,
    this.mesaLimpia = false,
  });
}

/// Motor de capturas del juego Caída
class CaptureEngine {
  CaptureEngine._();

  /// Intenta capturar cartas de la mesa lanzando una carta
  /// Devuelve CaptureResult con las cartas capturadas
  static CaptureResult tryCapture(
    CardModel playedCard,
    List<CardModel> mesa,
  ) {
    if (mesa.isEmpty) {
      return const CaptureResult(success: false, capturedCards: []);
    }

    final captured = <CardModel>[];
    var currentMesa = List<CardModel>.from(mesa);

    // 1. Empezamos buscando la carta de igual valor
    final match = _findAndRemove(playedCard.value, currentMesa);
    if (match != null) {
      captured.add(match);
      
      // 2. Captura en cadena: Seguimos buscando las consecutivas
      int? nextValue = GameConstants.nextInSequence(playedCard.value);
      while (nextValue != null) {
        final nextMatch = _findAndRemove(nextValue, currentMesa);
        if (nextMatch != null) {
          captured.add(nextMatch);
          nextValue = GameConstants.nextInSequence(nextValue);
        } else {
          // Si falta un eslabón en la cadena, se detiene la captura
          break;
        }
      }

      return CaptureResult(
        success: true,
        capturedCards: captured,
        mesaLimpia: currentMesa.isEmpty,
      );
    }

    return const CaptureResult(success: false, capturedCards: []);
  }

  /// Busca una carta de cierto valor en la mesa y la remueve de la lista temporal
  static CardModel? _findAndRemove(int value, List<CardModel> mesa) {
    for (int i = 0; i < mesa.length; i++) {
      if (mesa[i].value == value) {
        return mesa.removeAt(i);
      }
    }
    return null;
  }

  /// ¿Puede esta carta capturar alguna de la mesa?
  static bool canCapture(CardModel playedCard, List<CardModel> mesa) {
    for (final card in mesa) {
      if (card.value == playedCard.value) return true;
    }
    return false;
  }
}
