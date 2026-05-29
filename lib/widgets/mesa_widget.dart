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
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenW < 480 || screenH < 750;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cartas en la mesa o placeholder
          gameState.mesa.isEmpty
              ? const SizedBox.shrink()
              : _buildCardsOnMesa(isSmall),

          if (child != null) child!,
        ],
      ),
    );
  }

  Widget _buildCardsOnMesa(bool isSmall) {
    final cardW = isSmall ? 60.0 : 70.0;
    final cardH = isSmall ? 90.0 : 105.0;

    // Layout en grid/wrap centrado sobre el tapete
    return Container(
      constraints: BoxConstraints(
        maxWidth: isSmall ? 135.0 : 235.0,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: gameState.mesa.map((card) {
          final key = CardWidget.cardKeys.putIfAbsent(card.id, () => GlobalKey());
          return CardWidget(
            key: key,
            card: card,
            width: cardW,
            height: cardH,
            isPlayable: false,
          );
        }).toList(),
      ),
    );
  }
}
