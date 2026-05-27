import '../models/card_model.dart';
import '../core/game_constants.dart';
import 'package:uuid/uuid.dart';

/// Manejador del mazo de cartas
class DeckManager {
  static final _uuid = Uuid();

  /// Crea el mazo completo de 40 cartas (4 palos × 10 valores)
  /// Valores: 1,2,3,4,5,6,7,10,11,12 (NO hay 8 ni 9)
  static List<CardModel> createDeck() {
    final deck = <CardModel>[];

    for (final suit in Suit.values) {
      for (final value in GameConstants.validValues) {
        deck.add(CardModel(
          id: _uuid.v4(),
          value: value,
          suit: suit,
        ));
      }
    }

    assert(deck.length == GameConstants.deckSize,
        'El mazo debe tener ${GameConstants.deckSize} cartas, tiene ${deck.length}');

    return deck;
  }

  /// Baraja el mazo usando Fisher-Yates
  static List<CardModel> shuffle(List<CardModel> deck) {
    final shuffled = List<CardModel>.from(deck);
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = (shuffled.length * (DateTime.now().microsecondsSinceEpoch / 1e9 % 1)).toInt() % (i + 1);
      // Usar dart:math para mejor aleatoriedad
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  /// Baraja el mazo usando dart:math Random
  static List<CardModel> shuffleRandom(List<CardModel> deck) {
    final shuffled = List<CardModel>.from(deck);
    shuffled.shuffle();
    return shuffled;
  }

  /// Reparte n cartas del mazo, devuelve (cartas, mazo restante)
  static (List<CardModel>, List<CardModel>) deal(
      List<CardModel> deck, int count) {
    if (deck.length < count) {
      throw StateError(
          'No hay suficientes cartas en el mazo. Quedan ${deck.length}, se necesitan $count');
    }
    final dealtCards = deck.take(count).toList();
    final remaining = deck.skip(count).toList();
    return (dealtCards, remaining);
  }

  /// Toma la primera carta del mazo
  static (CardModel, List<CardModel>) takeOne(List<CardModel> deck) {
    if (deck.isEmpty) throw StateError('El mazo está vacío');
    return (deck.first, deck.skip(1).toList());
  }
}
