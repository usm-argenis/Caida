import 'package:flutter/foundation.dart';

/// Palos del mazo español
enum Suit { oros, copas, espadas, bastos }

/// Modelo de carta del juego Caída
@immutable
class CardModel {
  final String id;
  final int value;
  final Suit suit;

  const CardModel({
    required this.id,
    required this.value,
    required this.suit,
  });

  /// Nombre del palo en español
  String get suitName => switch (suit) {
        Suit.oros => 'Oros',
        Suit.copas => 'Copas',
        Suit.espadas => 'Espadas',
        Suit.bastos => 'Bastos',
      };

  /// Emoji/símbolo del palo
  String get suitSymbol => switch (suit) {
        Suit.oros => '🪙',
        Suit.copas => '🍷',
        Suit.espadas => '⚔️',
        Suit.bastos => '🪵',
      };

  /// Color del palo (oros y copas = rojo, espadas y bastos = negro)
  bool get isRed => suit == Suit.oros || suit == Suit.copas;

  /// Representación visual del valor
  String get displayValue => switch (value) {
        10 => '10', // Sota
        11 => '11', // Caballo
        12 => '12', // Rey
        _ => value.toString(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CardModel($value $suitName)';

  CardModel copyWith({
    String? id,
    int? value,
    Suit? suit,
  }) {
    return CardModel(
      id: id ?? this.id,
      value: value ?? this.value,
      suit: suit ?? this.suit,
    );
  }
}
