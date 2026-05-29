import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../core/app_theme.dart';

/// Widget que muestra una carta del juego Caída
class CardWidget extends StatefulWidget {
  static final Map<String, GlobalKey> cardKeys = {};

  final CardModel? card;
  final bool isSelected;
  final bool isPlayable;
  final bool faceDown;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const CardWidget({
    super.key,
    this.card,
    this.isSelected = false,
    this.isPlayable = true,
    this.faceDown = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverEnter(_) {
    if (widget.isPlayable && widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onHoverExit(_) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? 55.0;
    final h = widget.height ?? 85.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: _onHoverEnter,
        onExit: _onHoverExit,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: () => _showLargePreview(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: w,
            height: h,
            margin: EdgeInsets.only(
              bottom: widget.isSelected ? 12 : 0,
            ),
            decoration: widget.faceDown
                ? _backDecoration(w, h)
                : _frontDecoration(),
            child: widget.faceDown ? _buildBack() : _buildFront(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _frontDecoration() {
    final isSelected = widget.isSelected;
    return BoxDecoration(
      gradient: AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isSelected
            ? AppTheme.primary
            : (widget.card != null && widget.card!.isRed
                ? AppTheme.cardRed.withOpacity(0.4)
                : AppTheme.cardBlack.withOpacity(0.3)),
        width: isSelected ? 2.5 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.6)
              : Colors.black.withOpacity(0.4),
          blurRadius: isSelected ? 15 : 6,
          offset: const Offset(0, 3),
          spreadRadius: isSelected ? 2 : 0,
        ),
      ],
    );
  }

  BoxDecoration _backDecoration(double w, double h) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF1A237E)],
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildFront() {
    if (widget.card == null) return const SizedBox.shrink();
    
    final w = widget.width ?? 55.0;
    final h = widget.height ?? 85.0;
    
    final color = widget.card!.isRed ? AppTheme.cardRed : AppTheme.cardBlack;
    final displayVal = widget.card!.displayValue;
    final symbol = widget.card!.suitSymbol;

    // Intentar cargar la imagen personalizada para cualquier carta (1-7, 10-12)
    String suitKey = switch(widget.card!.suit) {
      Suit.oros => 'oro',
      Suit.copas => 'copa',
      Suit.espadas => 'espada',
      Suit.bastos => 'basto',
    };
    
    String path = 'lib/image/${widget.card!.value}_$suitKey.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        path,
        width: w,
        height: h,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => 
            _buildStandardFront(color, displayVal, symbol, w, h),
      ),
    );
  }

  Widget _buildStandardFront(Color color, String displayVal, String symbol, double w, double h) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Esquina superior izquierda
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayVal,
                style: TextStyle(
                  color: color,
                  fontSize: h * 0.16,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              Text(
                symbol,
                style: TextStyle(fontSize: h * 0.1),
              ),
            ],
          ),
          // Centro
          Center(
            child: Text(
              symbol,
              style: TextStyle(fontSize: h * 0.25),
            ),
          ),
          // Esquina inferior derecha (rotada)
          RotatedBox(
            quarterTurns: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayVal,
                  style: TextStyle(
                    color: color,
                    fontSize: h * 0.16,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Text(
                  symbol,
                  style: TextStyle(fontSize: h * 0.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          ),
        ),
        child: const Center(
          child: Text(
            '♠',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _showLargePreview(BuildContext context) {
    if (widget.card == null || widget.faceDown) return;

    showDialog(
      context: context,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CardWidget(
              card: widget.card,
              width: 240,
              height: 360,
              isPlayable: false,
            ),
          ),
        ),
      ),
    );
  }
}
