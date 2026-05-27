import 'package:flutter/foundation.dart';
import 'card_model.dart';

/// Tipo de jugador (humano o IA)
enum PlayerType { human, ai }

/// Modelo del jugador
@immutable
class PlayerModel {
  final String id;
  final String name;
  final List<CardModel> hand;
  final int score;
  final int capturedCount; // cartas capturadas en esta ronda
  final PlayerType type;
  final int teamIndex; // 0 o 1 para parejas
  final String? currentCanto; // Mensaje de canto actual (ej: ¡VIGIA!)

  const PlayerModel({
    required this.id,
    required this.name,
    this.hand = const [],
    this.score = 0,
    this.capturedCount = 0,
    this.type = PlayerType.human,
    this.teamIndex = 0,
    this.currentCanto,
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    List<CardModel>? hand,
    int? score,
    int? capturedCount,
    PlayerType? type,
    int? teamIndex,
    String? currentCanto,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      score: score ?? this.score,
      capturedCount: capturedCount ?? this.capturedCount,
      type: type ?? this.type,
      teamIndex: teamIndex ?? this.teamIndex,
      currentCanto: currentCanto ?? this.currentCanto,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PlayerModel($name, score: $score)';
}
