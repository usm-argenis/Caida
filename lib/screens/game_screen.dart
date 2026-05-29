import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state_model.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../providers/game_provider.dart';
import '../core/app_theme.dart';
import '../widgets/mesa_widget.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/ai_players_widget.dart';
import '../widgets/card_widget.dart';
import 'game_over_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla principal del juego - Tablero de juego
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isSmallScreen = screenW < 480 || screenH < 750;

    if (gameState == null) {
      return Scaffold(
        backgroundColor: AppTheme.mesaBlue,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    // Navegación a game over
    if (gameState.phase == GamePhase.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) =>
                GameOverScreen(gameState: gameState),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      });
    }



    return Scaffold(
      body: Container(
        // Toda la pantalla es el tapete azul
        color: AppTheme.mesaBlue,
        child: SafeArea(
          child: Stack(
            children: [
              // ── FONDO AZUL COMPLETO ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _FeltPatternPainter(),
                ),
              ),

              // ── JUGADOR NORTE (compañero - index 2) ──
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: AiPlayerPanel(
                    player: gameState.players[2],
                    isCurrent: gameState.currentPlayerIndex == 2,
                    position: PlayerPosition.north,
                    deckWidget: _getDeckWidget(gameState, 2),
                    capturedWidget: _getCapturedWidget(gameState, 2),
                    speechBubbleText: _getSpeechBubble(gameState, 2),
                  ),
                ),
              ),

              // ── JUGADOR OESTE (oponente - index 1) ──
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AiPlayerPanel(
                    player: gameState.players[1],
                    isCurrent: gameState.currentPlayerIndex == 1,
                    position: PlayerPosition.west,
                    deckWidget: _getDeckWidget(gameState, 1),
                    capturedWidget: _getCapturedWidget(gameState, 1),
                    speechBubbleText: _getSpeechBubble(gameState, 1),
                  ),
                ),
              ),

              // ── JUGADOR ESTE (oponente - index 3) ──
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AiPlayerPanel(
                    player: gameState.players[3],
                    isCurrent: gameState.currentPlayerIndex == 3,
                    position: PlayerPosition.east,
                    deckWidget: _getDeckWidget(gameState, 3),
                    capturedWidget: _getCapturedWidget(gameState, 3),
                    speechBubbleText: _getSpeechBubble(gameState, 3),
                  ),
                ),
              ),

              // ── CARTAS EN MESA (centro) ──
              Positioned(
                top: isSmallScreen ? 100 : 130,
                left: isSmallScreen ? 70 : 80,
                right: isSmallScreen ? 70 : 80,
                bottom: isSmallScreen ? 145 : 200,
                child: Center(
                  child: IgnorePointer(
                    child: MesaWidget(gameState: gameState),
                  ),
                ),
              ),

              // ── MARCADOR A|B (arriba derecha) ──
              Positioned(
                top: 8,
                right: 8,
                child: _TeamScoreBoard(gameState: gameState),
              ),

              // ── BOTONES DE ACCIÓN (izquierda) ──
              

              // ── MANO DEL JUGADOR HUMANO (abajo) ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildPlayerSection(context, ref, gameState),
              ),

              // ── MENSAJE DEL JUEGO (centro arriba) ──
              if (gameState.message != null &&
                  gameState.phase == GamePhase.playing)
                Positioned(
                  top: 110,
                  left: 80,
                  right: 80,
                  child: Center(
                    child: _GameMessageBadge(message: gameState.message!),
                  ),
                ),

              // El número gigante de la repartida ahora se muestra en globos de diálogo (bocadillos) sobre los avatares

              // ── MENÚ HAMBURGER (arriba) ──
              Positioned(
                top: 8,
                left: 8,
                child: _MenuButton(gameState: gameState),
              ),

              // ── MESA LIMPIA CHIP ──
              if (gameState.mesaLimpia)
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        '🎉 ¡MESA LIMPIA!',
                        style: GoogleFonts.cinzel(
                          color: AppTheme.background,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              // ── ANIMACIÓN DE REPARTIDA DE MESA (1,2,3,4 / 4,3,2,1) ──
              if (gameState.animMesaValue != null &&
                  gameState.phase == GamePhase.dealing)
                Positioned.fill(
                  child: _MesaDealingOverlay(
                    value: gameState.animMesaValue!,
                    card: gameState.animatingMesaCard,
                    dealerName: gameState.players[gameState.dealerIndex].name,
                    isHumanDealer: gameState.dealerIndex == 0,
                  ),
                ),

              // ── ANIMACIÓN GLOBAL DE CARTA JUGADA ──
              if (gameState.animatingPlayCard != null &&
                  gameState.animatingPlayCardPlayerIndex != null)
                Positioned.fill(
                  child: _GlobalCardPlayAnimationOverlay(
                    card: gameState.animatingPlayCard!,
                    playerIndex: gameState.animatingPlayCardPlayerIndex!,
                    players: gameState.players,
                    capturedCards: gameState.animatingCapturedCards,
                    isCaida: gameState.animatingIsCaida,
                    cantoName: gameState.animatingCantoName,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSection(
      BuildContext context, WidgetRef ref, GameStateModel gameState) {
    final humanPlayer = gameState.players[0];
    final isHumanTurn = ref.watch(isHumanTurnProvider);

    // Fase de elección de mesa
    if (gameState.phase == GamePhase.mesaChoice) {
      if (gameState.dealerIndex == 0) {
        return _MesaChoicePanel();
      } else {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Esperando a que ${gameState.players[gameState.dealerIndex].name} elija mesa...',
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    // Si es fin de ronda
    if (gameState.phase == GamePhase.roundEnd) {
      return _RoundEndPanel(gameState: gameState);
    }

    // ¿El humano (0) tiene el mazo? (es el repartidor)
    final humanHasDeck = gameState.dealerIndex == 0 && gameState.deck.isNotEmpty;

    // ¿El humano (0) muestra las capturas del equipo A?
    final humanCapturedWidget = _getCapturedWidget(gameState, 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Capturas del equipo A - IZQUIERDA en pantalla = IZQUIERDA del Sur mirando a la mesa
        SizedBox(
          width: 56,
          child: humanCapturedWidget != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 9)),
                      humanCapturedWidget,
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),

        // Mano del jugador con avatar
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerHandWidget(
              player: humanPlayer,
              isActive: isHumanTurn,
              isAnimating: gameState.animatingPlayCard != null, // Bug 3
              onCardTap: (card) {
                ref.read(gameProvider.notifier).playCard(card);
              },
            ),
            const SizedBox(height: 0),
            _HumanAvatar(
              name: humanPlayer.name,
              isActive: isHumanTurn,
              canto: humanPlayer.currentCanto,
              speechBubbleText: _getSpeechBubble(gameState, 0),
            ),
            const SizedBox(height: 8), // Separación para estar súper abajo
          ],
        ),
        const SizedBox(width: 10),

        // Mazo (si el humano reparte) - DERECHA en pantalla = DERECHA del Sur mirando a la mesa
        SizedBox(
          width: 56,
          child: humanHasDeck
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 9)),
                      _DeckPileWidget(count: gameState.deck.length),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  String? _getSpeechBubble(GameStateModel gameState, int idx) {
    // Solo mostrar globo durante repartida de mesa, no durante reparto de cartas
    if (gameState.animMesaValue != null &&
        gameState.phase == GamePhase.dealing &&
        gameState.animMesaIndex != -1 &&
        gameState.dealerIndex == idx) {
      return '¡${gameState.animMesaValue}!';
    }
    return null;
  }

  Widget? _getDeckWidget(GameStateModel gameState, int playerIndex) {
    if (gameState.dealerIndex == playerIndex && gameState.deck.isNotEmpty) {
      return _DeckPileWidget(count: gameState.deck.length);
    }
    return null;
  }

  Widget? _getCapturedWidget(GameStateModel gameState, int playerIndex) {
    final teamACapturedCount = gameState.players[0].capturedCount + gameState.players[2].capturedCount;
    final teamBCapturedCount = gameState.players[1].capturedCount + gameState.players[3].capturedCount;

    if (playerIndex == 0 || playerIndex == 2) {
      // Para el equipo A: si el dealer es 0, mostramos en 2. Si no, en 0.
      final targetShowIndex = (gameState.dealerIndex == 0) ? 2 : 0;
      if (playerIndex == targetShowIndex && teamACapturedCount > 0) {
        return _CapturedPileWidget(
          count: teamACapturedCount,
          label: playerIndex == 0 ? 'Tus capturas' : 'Capturas A',
        );
      }
    } else {
      // Para el equipo B: si el dealer es 1, mostramos en 3. Si no, en 1.
      final targetShowIndex = (gameState.dealerIndex == 1) ? 3 : 1;
      if (playerIndex == targetShowIndex && teamBCapturedCount > 0) {
        return _CapturedPileWidget(
          count: teamBCapturedCount,
          label: 'Capturas B',
        );
      }
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────
// AVATAR DEL JUGADOR HUMANO
// ─────────────────────────────────────────────────────────────
class _HumanAvatar extends StatelessWidget {
  final String name;
  final bool isActive;
  final String? canto;
  final String? speechBubbleText;

  const _HumanAvatar({
    required this.name,
    required this.isActive,
    this.canto,
    this.speechBubbleText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A2050),
                border: Border.all(
                  color: isActive ? AppTheme.accent : Colors.white30,
                  width: isActive ? 3 : 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.6),
                          blurRadius: 14,
                          spreadRadius: 3,
                        )
                      ]
                    : [],
              ),
              child: ClipOval(
                child: Icon(
                  Icons.person,
                  size: 28,
                  color: isActive ? AppTheme.accent : Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canto != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      canto!,
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.accent.withOpacity(0.85)
                        : Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? '🎯 $name' : name,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (speechBubbleText != null)
          Positioned(
            top: -45,
            child: SpeechBubble(text: speechBubbleText!),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MARCADOR EQUIPOS A | B
// ─────────────────────────────────────────────────────────────
class _TeamScoreBoard extends StatelessWidget {
  final GameStateModel gameState;

  const _TeamScoreBoard({required this.gameState});


  @override
  Widget build(BuildContext context) {
    final teamAScore = gameState.team0Score; // jugadores 0 y 2
    final teamBScore = gameState.team1Score; // jugadores 1 y 3

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header A | B
            Row(
              children: [
                _ScoreCell(
                  label: 'A',
                  isHeader: true,
                  color: AppTheme.accent,
                ),
                Container(
                    width: 1, height: 28, color: Colors.white24),
                _ScoreCell(
                  label: 'B',
                  isHeader: true,
                  color: AppTheme.warning,
                ),
              ],
            ),
            Container(height: 1, color: Colors.white24),
            // Scores
            Row(
              children: [
                _ScoreCell(
                  label: '$teamAScore',
                  isHeader: false,
                  color: Colors.white,
                ),
                Container(
                    width: 1, height: 28, color: Colors.white24),
                _ScoreCell(
                  label: '$teamBScore',
                  isHeader: false,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  final String label;
  final bool isHeader;
  final Color color;

  const _ScoreCell({
    required this.label,
    required this.isHeader,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 28,
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.cinzel(
            color: color,
            fontSize: isHeader ? 13 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BADGE DE MENSAJE
// ─────────────────────────────────────────────────────────────
class _GameMessageBadge extends StatelessWidget {
  final String message;
  const _GameMessageBadge({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.lato(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MESA CHOICE
// ─────────────────────────────────────────────────────────────
class _MesaChoicePanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¡TU TURNO DE REPARTIR!',
            style: GoogleFonts.cinzel(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '¿Cuántas cartas deseas poner en la mesa?',
            style: GoogleFonts.lato(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChoiceButton(
                label: '1 CARTA',
                onPressed: () =>
                    ref.read(gameProvider.notifier).chooseMesa(1),
              ),
              const SizedBox(width: 12),
              _ChoiceButton(
                label: '4 CARTAS',
                onPressed: () =>
                    ref.read(gameProvider.notifier).chooseMesa(4),
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ChoiceButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? AppTheme.primary : Colors.white.withOpacity(0.2),
        foregroundColor: isPrimary ? AppTheme.background : Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(label,
          style: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MENÚ
// ─────────────────────────────────────────────────────────────
class _MenuButton extends ConsumerWidget {
  final GameStateModel gameState;

  const _MenuButton({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.menu, color: Colors.white70, size: 20),
        color: const Color(0xFF1A2A40),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) {
          switch (value) {
            case 'restart':
              _showRestartDialog(context, ref);
              break;
            case 'home':
              ref.read(gameProvider.notifier).resetGame();
              Navigator.of(context).pop();
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'restart',
            child: Row(children: [
              const Icon(Icons.refresh, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Reiniciar',
                  style:
                      GoogleFonts.lato(color: AppTheme.textPrimary)),
            ]),
          ),
          PopupMenuItem(
            value: 'home',
            child: Row(children: [
              const Icon(Icons.home, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Menú principal',
                  style:
                      GoogleFonts.lato(color: AppTheme.textPrimary)),
            ]),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A40),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Reiniciar?',
          style: GoogleFonts.cinzel(color: AppTheme.primary),
        ),
        content: Text(
          '¿Seguro que deseas reiniciar la partida?',
          style: GoogleFonts.lato(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.lato(
                    color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).startGame();
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FIN DE RONDA
// ─────────────────────────────────────────────────────────────
class _RoundEndPanel extends ConsumerWidget {
  final GameStateModel gameState;

  const _RoundEndPanel({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FIN DE RONDA ${gameState.roundNumber}',
            style: GoogleFonts.cinzel(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (gameState.message != null) ...[
            const SizedBox(height: 6),
            Text(
              gameState.message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                  color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(gameProvider.notifier).startNextRound();
            },
            icon: Icon(gameState.roundNumber == 3 ? Icons.play_arrow : Icons.navigate_next),
            label: Text(gameState.roundNumber == 3 ? 'SEGUIR JUGANDO' : 'SIGUIENTE RONDA'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(180, 42),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PILA DE MAZO (al lado del repartidor)
// ─────────────────────────────────────────────────────────────
class _DeckPileWidget extends StatelessWidget {
  final int count;
  const _DeckPileWidget({required this.count});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$count cartas en el mazo',
      child: Container(
        width: 46,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cartas apiladas efecto
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 38,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // Contador
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF0A1628),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PILA DE CARTAS CAPTURADAS
// ─────────────────────────────────────────────────────────────
class _CapturedPileWidget extends StatelessWidget {
  final int count;
  final String label;
  const _CapturedPileWidget({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        width: 46,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.success.withOpacity(0.3),
              AppTheme.success.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.success.withOpacity(0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.success.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers, color: Colors.white70, size: 16),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'cap.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// PATRÓN DE TAPETE (felt texture)
// ─────────────────────────────────────────────────────────────
class _FeltPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 24.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// ANIMACIÓN GLOBAL DE JUEGO DE CARTAS (HUMANO E IA)
// ─────────────────────────────────────────────────────────────
class _GlobalCardPlayAnimationOverlay extends ConsumerStatefulWidget {
  final CardModel card;
  final int playerIndex;
  final List<PlayerModel> players;
  final List<CardModel>? capturedCards;
  final bool isCaida;
  final String? cantoName;

  const _GlobalCardPlayAnimationOverlay({
    super.key,
    required this.card,
    required this.playerIndex,
    required this.players,
    this.capturedCards,
    this.isCaida = false,
    this.cantoName,
  });

  @override
  ConsumerState<_GlobalCardPlayAnimationOverlay> createState() =>
      __GlobalCardPlayAnimationOverlayState();
}

class __GlobalCardPlayAnimationOverlayState
    extends ConsumerState<_GlobalCardPlayAnimationOverlay> {
  double bgOpacity = 0.0;
  double cardScale = 0.4;
  double cardRotation = 0.0;
  Offset? cardPosition;
  bool showTitle = false;
  bool showCaidaText = false;
  Duration animationDuration = const Duration(milliseconds: 500);
  bool isDisposed = false;
  List<CardModel> slidingStack = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _runSequence();
      }
    });
  }

  @override
  void dispose() {
    isDisposed = true;
    Future.microtask(() {
      if (ref.context.mounted) {
        ref.read(hiddenMesaCardsProvider.notifier).state = {};
      }
    });
    super.dispose();
  }

  Offset? _getMesaCardPosition(String cardId) {
    final key = CardWidget.cardKeys[cardId];
    if (key == null) return null;
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final localPos = renderBox.localToGlobal(Offset.zero);
    final overlayBox = context.findRenderObject() as RenderBox?;

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenW < 480 || screenH < 750;
    final cardW = isSmall ? 60.0 : 70.0;
    final cardH = isSmall ? 90.0 : 105.0;

    if (overlayBox != null) {
      final localInOverlay = overlayBox.globalToLocal(localPos);
      // Centrar respecto a la nueva carta de mesa responsiva (60x90 o 70x105)
      return localInOverlay + Offset(cardW / 2, cardH / 2);
    }
    return localPos + Offset(cardW / 2, cardH / 2);
  }

  Future<void> _runSequence() async {
    if (isDisposed || !mounted) return;

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    Offset startOffset;
    switch (widget.playerIndex) {
      case 0: // Humano (Abajo)
        startOffset = Offset(screenW / 2, screenH - 60);
        break;
      case 1: // Oeste (Izquierda)
        startOffset = Offset(60, screenH / 2);
        break;
      case 2: // Norte (Arriba)
        startOffset = Offset(screenW / 2, 70);
        break;
      case 3: // Este (Derecha)
        startOffset = Offset(screenW - 60, screenH / 2);
        break;
      default:
        startOffset = Offset(screenW / 2, screenH / 2);
    }

    final centerOffset = Offset(screenW / 2, screenH / 2 - 30);

    // Estado inicial
    setState(() {
      slidingStack = [widget.card];
      animationDuration = Duration.zero;
      cardPosition = startOffset;
      bgOpacity = 0.0;
      cardScale = 0.4;
      cardRotation = 0.0;
    });
    ref.read(hiddenMesaCardsProvider.notifier).state = {};

    await Future.delayed(const Duration(milliseconds: 50));
    if (isDisposed || !mounted) return;

    // Fase 1: Deslizar al centro
    setState(() {
      animationDuration = const Duration(milliseconds: 600);
      cardPosition = centerOffset;
      bgOpacity = 0.75;
      cardScale = 1.3;
      cardRotation = 0.012; // Aprox 4.3 grados de rotación
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (isDisposed || !mounted) return;

    // Mostrar títulos
    setState(() {
      showTitle = true;
      if (widget.isCaida || widget.cantoName != null) {
        showCaidaText = true;
      }
    });

    // Fase 2: Mantener en el centro por 1 segundo
    await Future.delayed(const Duration(milliseconds: 1000));
    if (isDisposed || !mounted) return;

    // Ocultar overlay oscuro ANTES de ir a las capturas (carta visible sobre mesa limpia)
    setState(() {
      showTitle = false;
      showCaidaText = false;
      animationDuration = const Duration(milliseconds: 300);
      bgOpacity = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (isDisposed || !mounted) return;

    final isSmall = screenW < 480 || screenH < 750;
    final targetScale = (isSmall ? 60.0 : 70.0) / 120.0;
    final captureScale = targetScale * 0.72; // Escala más pequeña para ver la carta de la mesa detrás

    // Fase 3: Capturas consecutivas sin overlay oscuro
    if (widget.capturedCards != null && widget.capturedCards!.isNotEmpty) {
      for (final capCard in widget.capturedCards!) {
        final capPos = _getMesaCardPosition(capCard.id);
        if (capPos != null) {
          // Deslizar hacia la carta capturada
          setState(() {
            animationDuration = const Duration(milliseconds: 400);
            cardPosition = capPos;
            cardScale = captureScale;
            cardRotation = 0.0;
          });
          await Future.delayed(const Duration(milliseconds: 400));
          if (isDisposed || !mounted) return;

          // Una vez llega a la carta, la agrega al mazo deslizante y la oculta en la mesa
          setState(() {
            slidingStack.add(capCard);
          });
          ref.read(hiddenMesaCardsProvider.notifier).update((state) => {...state, capCard.id});

          // Esperar 0.6 segundos mostrando la carta agregada al mazo
          await Future.delayed(const Duration(milliseconds: 600));
          if (isDisposed || !mounted) return;
        }
      }
    }

    // Fase 4: Reducir la carta antes de completar
    setState(() {
      animationDuration = const Duration(milliseconds: 300);
      cardScale = targetScale;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (isDisposed || !mounted) return;

    // Limpiar cartas ocultas
    ref.read(hiddenMesaCardsProvider.notifier).state = {};

    // Fase 5: Completar oficialmente la jugada en el provider
    ref.read(gameProvider.notifier).completePlayCard(widget.card);
  }

  @override
  Widget build(BuildContext context) {
    final cardPos = cardPosition ?? const Offset(0, 0);
    final playerName = widget.players[widget.playerIndex].name;

    return Stack(
      children: [
        IgnorePointer(
          child: AnimatedContainer(
            duration: animationDuration,
            color: Colors.black.withOpacity(bgOpacity),
          ),
        ),

        if (showTitle)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                ),
                child: Text(
                  widget.playerIndex == 0 ? '🎯 ¡Tú juegas!' : '▶ $playerName juega...',
                  style: GoogleFonts.cinzel(
                    color: AppTheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        if (showCaidaText)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 + 110,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                widget.cantoName != null ? '¡${widget.cantoName}!' : 'CAÍDA',
                style: GoogleFonts.cinzel(
                  fontSize: widget.cantoName != null ? 36 : 50,
                  fontWeight: FontWeight.w900,
                  color: widget.cantoName != null ? AppTheme.primary : AppTheme.cardRed,
                  letterSpacing: widget.cantoName != null ? 4.0 : 8.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 15,
                      offset: const Offset(2, 2),
                    ),
                    Shadow(
                      color: (widget.cantoName != null ? AppTheme.primary : AppTheme.cardRed).withOpacity(0.5),
                      blurRadius: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),

        AnimatedPositioned(
          duration: animationDuration,
          curve: Curves.easeInOut,
          left: cardPos.dx - 60,
          top: cardPos.dy - 90,
          child: IgnorePointer(
            child: AnimatedScale(
              duration: animationDuration,
              curve: Curves.easeInOut,
              scale: cardScale,
              child: AnimatedRotation(
                duration: animationDuration,
                curve: Curves.easeInOut,
                turns: cardRotation,
                child: SizedBox(
                  width: 120,
                  height: 180,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(slidingStack.length, (index) {
                      final card = slidingStack[index];
                      // Las cartas capturadas se apilan con un desplazamiento sutil y ligera rotación
                      final double dx = index * 4.0;
                      final double dy = -index * 4.0;
                      final double angle = index * 0.02; // ~1.1 grados de rotación por carta

                      return Positioned(
                        left: dx,
                        top: dy,
                        child: Transform.rotate(
                          angle: angle,
                          child: CardWidget(
                            card: card,
                            width: 120,
                            height: 180,
                            isPlayable: false,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MesaDealingOverlay extends StatelessWidget {
  final int value;
  final CardModel? card;
  final String dealerName;
  final bool isHumanDealer;

  const _MesaDealingOverlay({
    required this.value,
    this.card,
    required this.dealerName,
    required this.isHumanDealer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.65), // Hace todo un poco más oscuro
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (card != null) ...[
              CardWidget(
                card: card!,
                width: 120,
                height: 180,
                isPlayable: false,
              ),
              const SizedBox(height: 20),
            ],
            Text(
              '$value',
              style: GoogleFonts.cinzel(
                fontSize: 100, // Gigante y estilizado
                fontWeight: FontWeight.bold,
                color: AppTheme.primary, // Color oro/amarillo principal
                shadows: [
                  Shadow(
                    color: AppTheme.primary.withOpacity(0.6),
                    blurRadius: 25,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Text(
                isHumanDealer ? '¡Tú cantas $value!' : '¡$dealerName canta $value!',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
