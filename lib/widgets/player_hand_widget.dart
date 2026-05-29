import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../core/app_theme.dart';
import 'card_widget.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mano del jugador humano - cartas en abanico geométrico real
/// emanando desde el centro-abajo (el avatar del jugador)
class PlayerHandWidget extends StatefulWidget {
  final PlayerModel player;
  final bool isActive;
  final bool isAnimating; // Bug 3: bloquea taps durante animación
  final Function(CardModel) onCardTap;

  const PlayerHandWidget({
    super.key,
    required this.player,
    required this.isActive,
    this.isAnimating = false,
    required this.onCardTap,
  });

  @override
  State<PlayerHandWidget> createState() => _PlayerHandWidgetState();
}

class _PlayerHandWidgetState extends State<PlayerHandWidget> {
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenW < 480 || screenH < 750;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Canto del jugador
        if (widget.player.currentCanto != null)
          AnimatedSlide(
            offset: Offset.zero,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 10)
                ],
              ),
              child: Text(
                widget.player.currentCanto!,
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

        // Abanico de cartas
        if (widget.player.hand.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Sin cartas',
              style: GoogleFonts.lato(
                color: Colors.white38,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          )
        else
          _HumanFanWidget(
            cards: widget.player.hand,
            isActive: widget.isActive && !widget.isAnimating, // Bug 3: desactivar si hay animación
            selectedCard: null,
            isSmall: isSmall,
            onCardTap: (card) {
              if (!widget.isActive) return;
              if (widget.isAnimating) return; // Bug 3: bloqueo adicional en UI
              widget.onCardTap(card);
            },
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ABANICO HUMANO — cartas apuntando hacia ARRIBA desde el centro
// ────────────────────────────────────────────────────────────────
class _HumanFanWidget extends StatelessWidget {
  final List<CardModel> cards;
  final bool isActive;
  final CardModel? selectedCard;
  final bool isSmall;
  final Function(CardModel) onCardTap;

  const _HumanFanWidget({
    required this.cards,
    required this.isActive,
    required this.selectedCard,
    this.isSmall = false,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = cards.length;
    if (count == 0) return const SizedBox.shrink();

    final cardW = isSmall ? 46.0 : 54.0;
    final cardH = isSmall ? 70.0 : 82.0;
    final fanH = isSmall ? 100.0 : 120.0;
    final fanW = isSmall ? 240.0 : 280.0;

    // Punto de origen: centro-abajo del widget
    final originX = fanW / 2;
    final originY = isSmall ? 145.0 : 175.0;
    final radius = isSmall ? 80.0 : 100.0;

    final totalAngle = math.min((count - 1) * 16.0, 64.0) * math.pi / 180;
    final startAngle = -totalAngle / 2;
    // Apunta hacia ARRIBA (-math.pi/2)
    const baseAngle = -math.pi / 2;

    final widgets = <Widget>[];

    for (int i = 0; i < count; i++) {
      final card = cards[i];
      final isSelected = selectedCard?.id == card.id;
      final t = count == 1 ? 0.0 : i / (count - 1);
      final angle = startAngle + t * totalAngle;
      final cardAngle = baseAngle + angle;

      final dx = originX + radius * math.cos(cardAngle) - cardW / 2;
      // Seleccionada sube 18px extra
      final dy = originY + radius * math.sin(cardAngle) - cardH / 2 -
          (isSelected ? 18.0 : 0.0);

      widgets.add(
        Positioned(
          left: dx,
          top: dy,
          child: GestureDetector(
            onTap: () => onCardTap(card),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              child: Transform.rotate(
                angle: angle,
                child: CardWidget(
                  card: card,
                  isSelected: isSelected,
                  isPlayable: isActive,
                  width: cardW,
                  height: cardH,
                  onTap: isActive ? () => onCardTap(card) : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: fanW,
      height: fanH,
      child: Stack(
        clipBehavior: Clip.none,
        children: widgets,
      ),
    );
  }
}


