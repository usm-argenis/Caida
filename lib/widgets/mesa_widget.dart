import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state_model.dart';
import '../models/card_model.dart';
import '../providers/game_provider.dart';
import 'card_widget.dart';

/// Mesa central del juego - muestra las cartas en mesa sobre el tapete
class MesaWidget extends ConsumerWidget {
  final GameStateModel gameState;
  final Widget? child;

  const MesaWidget({super.key, required this.gameState, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenW < 480 || screenH < 750;
    final hiddenIds = ref.watch(hiddenMesaCardsProvider);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cartas en la mesa o placeholder
          gameState.mesa.isEmpty
              ? const SizedBox.shrink()
              : _buildCardsOnMesa(isSmall, hiddenIds),

          if (child != null) child!,
        ],
      ),
    );
  }

  List<int> _getRowSizes(int n, bool isSmall) {
    if (n <= 0) return [];
    if (n >= 7) {
      return [3, 2, 2, n - 7];
    }
    if (n == 6) {
      return [2, 2, 2];
    }
    // n < 6
    if (isSmall) {
      if (n <= 2) return [n];
      if (n == 3) return [2, 1];
      if (n == 4) return [2, 2];
      if (n == 5) return [2, 2, 1];
    } else {
      if (n <= 3) return [n];
      if (n == 4) return [2, 2];
      if (n == 5) return [3, 2];
    }
    return [n];
  }

  List<List<CardModel>> _chunkCards(List<CardModel> cards, List<int> sizes) {
    List<List<CardModel>> rows = [];
    int index = 0;
    for (final size in sizes) {
      if (size <= 0) continue;
      final end = math.min(index + size, cards.length);
      if (index < end) {
        rows.add(cards.sublist(index, end));
        index = end;
      }
    }
    if (index < cards.length) {
      rows.add(cards.sublist(index));
    }
    return rows;
  }

  Widget _buildCardsOnMesa(bool isSmall, Set<String> hiddenIds) {
    final cardW = isSmall ? 60.0 : 70.0;
    final cardH = isSmall ? 90.0 : 105.0;

    final sizes = _getRowSizes(gameState.mesa.length, isSmall);
    final rows = _chunkCards(gameState.mesa, sizes);

    // Layout simétrico en Column + Row para máxima precisión geométrica
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: rows.map((rowCards) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rowCards.map((card) {
              final key = CardWidget.cardKeys.putIfAbsent(card.id, () => GlobalKey());
              final isHidden = hiddenIds.contains(card.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Opacity(
                  opacity: isHidden ? 0.0 : 1.0,
                  child: CardWidget(
                    key: key,
                    card: card,
                    width: cardW,
                    height: cardH,
                    isPlayable: false,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
