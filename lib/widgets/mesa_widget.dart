import 'package:flutter/material.dart';
import '../models/game_state_model.dart';
import 'card_widget.dart';

/// Mesa central del juego - muestra las cartas en mesa sobre el tapete
class MesaWidget extends StatelessWidget {
  final GameStateModel gameState;
  final Widget? child;

  const MesaWidget({super.key, required this.gameState, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cartas en la mesa o placeholder
          gameState.mesa.isEmpty
              ? const SizedBox.shrink()
              : _buildCardsOnMesa(),

          if (child != null) child!,
        ],
      ),
    );
  }

  Widget _buildCardsOnMesa() {
    // Layout en grid/wrap centrado sobre el tapete
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: gameState.mesa.map((card) {
        final key = CardWidget.cardKeys.putIfAbsent(card.id, () => GlobalKey());
        return CardWidget(
          key: key,
          card: card,
          width: 55,
          height: 85,
          isPlayable: false,
        );
      }).toList(),
    );
  }
}
