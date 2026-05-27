import 'package:flutter/foundation.dart';
import 'card_model.dart';

/// Tipos de canto posibles
/// El orden de los valores en el enum define la jerarquía (mayor index = mayor prioridad)
enum CantoType {
  none,
  ronda,
  patrulla,
  vigia,
  registro,
  tribilin, // 3 cartas del mismo número — mayor jerarquía de todos
}

/// Modelo de un canto realizado por un jugador
@immutable
class CantoModel {
  final CantoType type;
  final int points;
  final List<CardModel> cards;
  final String playerId;

  const CantoModel({
    required this.type,
    required this.points,
    required this.cards,
    required this.playerId,
  });

  String get typeName => switch (type) {
        CantoType.none => 'Ninguno',
        CantoType.ronda => 'Ronda',
        CantoType.patrulla => 'Patrulla',
        CantoType.vigia => 'Vigía',
        CantoType.registro => 'Registro',
        CantoType.tribilin => 'Tribilín',
      };

  /// Si el Tribilín gana la partida automáticamente (ronda 1 o 3)
  bool get isTribilin => type == CantoType.tribilin;

  String get description => switch (type) {
        CantoType.none => '',
        CantoType.ronda => 'Ronda ($points pto${points > 1 ? 's' : ''})',
        CantoType.patrulla => 'Patrulla (6 pts)',
        CantoType.vigia => 'Vigía (7 pts)',
        CantoType.registro => 'Registro (8 pts)',
        CantoType.tribilin => 'Tribilín (¡Gana la partida!)',
      };

  @override
  String toString() => 'CantoModel($typeName, $points pts)';
}
