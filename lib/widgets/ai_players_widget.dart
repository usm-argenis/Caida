import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../core/app_theme.dart';
import 'card_widget.dart';
import 'package:google_fonts/google_fonts.dart';

/// Posición del jugador en la mesa
enum PlayerPosition { north, west, east }

/// Panel para un jugador IA — avatar + abanico de cartas emanando del avatar
class AiPlayerPanel extends StatelessWidget {
  final PlayerModel player;
  final bool isCurrent;
  final PlayerPosition position;
  final Widget? deckWidget;
  final Widget? capturedWidget;
  final Widget? lastPlayedCardWidget;
  final String? speechBubbleText;

  const AiPlayerPanel({
    super.key,
    required this.player,
    required this.isCurrent,
    this.position = PlayerPosition.north,
    this.deckWidget,
    this.capturedWidget,
    this.lastPlayedCardWidget,
    this.speechBubbleText,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenW < 480 || screenH < 750;

    switch (position) {
      case PlayerPosition.north:
        return _buildNorth(context, isSmall);
      case PlayerPosition.west:
        return _buildWest(context, isSmall);
      case PlayerPosition.east:
        return _buildEast(context, isSmall);
    }
  }

  // ── NORTE: avatar en top-center, cartas en abanico hacia abajo ──
  Widget _buildNorth(BuildContext context, bool isSmall) {
    return SizedBox(
      width: isSmall ? 130 : 160,
      height: isSmall ? 105 : 130,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cartas en abanico — se extienden HACIA ABAJO desde el avatar (top center)
          Positioned.fill(
            child: _NorthFanWidget(
              count: player.hand.length,
              isFaceDown: true,
              isSmall: isSmall,
            ),
          ),
          // Avatar centrado en la parte superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(size: isSmall ? 40 : 48),
                  const SizedBox(height: 2),
                  _buildNameTag(),
                ],
              ),
            ),
          ),
          if (speechBubbleText != null)
            Positioned(
              top: isSmall ? -32 : -38,
              left: 0,
              right: 0,
              child: Center(
                child: SpeechBubble(text: speechBubbleText!),
              ),
            ),
          // Pilas de mazo/capturas a la izquierda del avatar (fuera del SizedBox)
          if (deckWidget != null || capturedWidget != null)
            Positioned(
              right: isSmall ? 136 : 166,
              top: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (deckWidget != null) deckWidget!,
                  if (deckWidget != null && capturedWidget != null) const SizedBox(height: 4),
                  if (capturedWidget != null) capturedWidget!,
                ],
              ),
            ),
          // Última carta jugada a la derecha del avatar (fuera del SizedBox)
          if (lastPlayedCardWidget != null)
            Positioned(
              left: isSmall ? 138 : 168,
              top: 8,
              child: lastPlayedCardWidget!,
            ),
        ],
      ),
    );
  }

  // ── OESTE: avatar en la izquierda, cartas en abanico hacia la derecha ──
  Widget _buildWest(BuildContext context, bool isSmall) {
    return SizedBox(
      width: isSmall ? 80 : 110,
      height: isSmall ? 140 : 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cartas en abanico — se extienden hacia la DERECHA (hacia el centro)
          Positioned.fill(
            child: _WestFanWidget(
              count: player.hand.length,
              isFaceDown: true,
              isSmall: isSmall,
            ),
          ),
          // Avatar centrado verticalmente
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(size: isSmall ? 36 : 44),
                  const SizedBox(height: 2),
                  _buildNameTag(maxWidth: isSmall ? 55 : 70),
                ],
              ),
            ),
          ),
          if (speechBubbleText != null)
            Positioned(
              bottom: isSmall ? 100 : 130, // por encima del avatar centrado
              left: 0,
              right: 0,
              child: Center(
                child: SpeechBubble(text: speechBubbleText!),
              ),
            ),
          // Pilas de mazo/capturas debajo del avatar centrado
          if (deckWidget != null || capturedWidget != null)
            Positioned(
              top: isSmall ? 100 : 130, // por debajo del avatar centrado
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (deckWidget != null) deckWidget!,
                    if (deckWidget != null && capturedWidget != null) const SizedBox(height: 4),
                    if (capturedWidget != null) capturedWidget!,
                  ],
                ),
              ),
            ),
          if (lastPlayedCardWidget != null)
            Positioned(
              right: isSmall ? -45 : -55,
              top: isSmall ? 50 : 66, // alineado con el centro del avatar
              child: lastPlayedCardWidget!,
            ),
        ],
      ),
    );
  }

  // ── ESTE: avatar en la derecha, cartas en abanico hacia la izquierda ──
  Widget _buildEast(BuildContext context, bool isSmall) {
    return SizedBox(
      width: isSmall ? 80 : 110,
      height: isSmall ? 140 : 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cartas en abanico — se extienden hacia la IZQUIERDA (hacia el centro)
          Positioned.fill(
            child: _EastFanWidget(
              count: player.hand.length,
              isFaceDown: true,
              isSmall: isSmall,
            ),
          ),
          // Avatar centrado verticalmente
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(size: isSmall ? 36 : 44),
                  const SizedBox(height: 2),
                  _buildNameTag(maxWidth: isSmall ? 55 : 70),
                ],
              ),
            ),
          ),
          if (speechBubbleText != null)
            Positioned(
              bottom: isSmall ? 100 : 130, // por encima del avatar centrado
              left: 0,
              right: 0,
              child: Center(
                child: SpeechBubble(text: speechBubbleText!),
              ),
            ),
          // Pilas de mazo/capturas debajo del avatar centrado
          if (deckWidget != null || capturedWidget != null)
            Positioned(
              top: isSmall ? 100 : 130, // por debajo del avatar centrado
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (deckWidget != null) deckWidget!,
                    if (deckWidget != null && capturedWidget != null) const SizedBox(height: 4),
                    if (capturedWidget != null) capturedWidget!,
                  ],
                ),
              ),
            ),
          if (lastPlayedCardWidget != null)
            Positioned(
              left: isSmall ? -45 : -55,
              top: isSmall ? 50 : 66, // alineado con el centro del avatar
              child: lastPlayedCardWidget!,
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({double size = 52}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A2050),
        border: Border.all(
          color: isCurrent ? AppTheme.primary : Colors.white30,
          width: isCurrent ? 3 : 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.6),
                  blurRadius: 14,
                  spreadRadius: 3,
                )
              ]
            : [],
      ),
      child: ClipOval(
        child: Icon(
          Icons.person,
          size: size * 0.58,
          color: isCurrent ? AppTheme.primary : Colors.white54,
        ),
      ),
    );
  }

  Widget _buildNameTag({double? maxWidth}) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth ?? 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withOpacity(0.9)
            : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.currentCanto != null)
            Text(
              player.currentCanto!,
              style: GoogleFonts.cinzel(
                color: isCurrent ? AppTheme.background : AppTheme.primary,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            player.name,
            style: GoogleFonts.lato(
              color: isCurrent ? AppTheme.background : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ABANICO NORTE — cartas apuntando hacia abajo desde el avatar
// ────────────────────────────────────────────────────────────────
class _NorthFanWidget extends StatelessWidget {
  final int count;
  final bool isFaceDown;
  final bool isSmall;
  const _NorthFanWidget({required this.count, required this.isFaceDown, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final cardW = isSmall ? 26.0 : 32.0;
    final cardH = isSmall ? 38.0 : 48.0;
    final originX = isSmall ? 65.0 : 80.0; // centro horizontal del SizedBox
    final originY = isSmall ? 20.0 : 24.0; // justo en el centro del avatar
    final radius = isSmall ? 42.0 : 56.0;  // muy cerca del círculo del avatar
    final totalAngle = math.min((count - 1) * 18.0, 80.0) * math.pi / 180;
    final startAngle = -totalAngle / 2;
    // Norte: apunta hacia abajo (math.pi/2)
    const baseAngle = math.pi / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(count, (i) {
        final t = count == 1 ? 0.0 : i / (count - 1);
        final angle = startAngle + t * totalAngle;
        final cardAngle = baseAngle + angle;
        final dx = originX + radius * math.cos(cardAngle) - cardW / 2;
        final dy = originY + radius * math.sin(cardAngle) - cardH / 2;

        return Positioned(
          left: dx,
          top: dy,
          child: Transform.rotate(
            angle: angle + math.pi,
            child: CardWidget(
              faceDown: isFaceDown,
              width: cardW,
              height: cardH,
              isPlayable: false,
            ),
          ),
        );
      }),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ABANICO OESTE — cartas apuntando hacia la DERECHA desde el avatar
// ────────────────────────────────────────────────────────────────
class _WestFanWidget extends StatelessWidget {
  final int count;
  final bool isFaceDown;
  final bool isSmall;
  const _WestFanWidget({required this.count, required this.isFaceDown, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final cardW = isSmall ? 26.0 : 32.0;
    final cardH = isSmall ? 38.0 : 48.0;
    final originX = isSmall ? 40.0 : 55.0; // centro del avatar
    final originY = isSmall ? 70.0 : 90.0; // centro del avatar
    final radius = isSmall ? 42.0 : 56.0;  // muy cerca del círculo del avatar
    final totalAngle = math.min((count - 1) * 18.0, 70.0) * math.pi / 180;
    final startAngle = -totalAngle / 2;
    // Oeste: apunta hacia la derecha (0 radianes)
    const baseAngle = 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(count, (i) {
        final t = count == 1 ? 0.0 : i / (count - 1);
        final angle = startAngle + t * totalAngle;
        final cardAngle = baseAngle + angle;
        final dx = originX + radius * math.cos(cardAngle) - cardW / 2;
        final dy = originY + radius * math.sin(cardAngle) - cardH / 2;

        return Positioned(
          left: dx,
          top: dy,
          child: Transform.rotate(
            angle: angle + math.pi / 2,
            child: CardWidget(
              faceDown: isFaceDown,
              width: cardW,
              height: cardH,
              isPlayable: false,
            ),
          ),
        );
      }),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ABANICO ESTE — cartas apuntando hacia la IZQUIERDA desde el avatar
// ────────────────────────────────────────────────────────────────
class _EastFanWidget extends StatelessWidget {
  final int count;
  final bool isFaceDown;
  final bool isSmall;
  const _EastFanWidget({required this.count, required this.isFaceDown, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final cardW = isSmall ? 26.0 : 32.0;
    final cardH = isSmall ? 38.0 : 48.0;
    final originX = isSmall ? 40.0 : 55.0; // centro del avatar
    final originY = isSmall ? 70.0 : 90.0; // centro del avatar
    final radius = isSmall ? 42.0 : 56.0;  // muy cerca del círculo del avatar
    final totalAngle = math.min((count - 1) * 18.0, 70.0) * math.pi / 180;
    final startAngle = -totalAngle / 2;
    // Este: apunta hacia la izquierda (math.pi radianes)
    const baseAngle = math.pi;

    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(count, (i) {
        final t = count == 1 ? 0.0 : i / (count - 1);
        final angle = startAngle + t * totalAngle;
        final cardAngle = baseAngle + angle;
        final dx = originX + radius * math.cos(cardAngle) - cardW / 2;
        final dy = originY + radius * math.sin(cardAngle) - cardH / 2;

        return Positioned(
          left: dx,
          top: dy,
          child: Transform.rotate(
            angle: angle - math.pi / 2,
            child: CardWidget(
              faceDown: isFaceDown,
              width: cardW,
              height: cardH,
              isPlayable: false,
            ),
          ),
        );
      }),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// GLOBITO DE DIÁLOGO PARA EL CANTADO DE CARTAS
// ────────────────────────────────────────────────────────────────
class SpeechBubble extends StatefulWidget {
  final String text;

  const SpeechBubble({required this.text});

  @override
  State<SpeechBubble> createState() => SpeechBubbleState();
}

class SpeechBubbleState extends State<SpeechBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFFB300)], // Oro cálido y brillante
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Text(
            widget.text,
            style: GoogleFonts.cinzel(
              color: const Color(0xFF1E1E24),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.white60,
                  offset: Offset(0, 1),
                  blurRadius: 1,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
