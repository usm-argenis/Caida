import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/game_state_model.dart';
import '../game_engine/game_manager.dart';
import '../game_engine/capture_engine.dart';
import '../core/game_constants.dart';


/// Notifier principal que maneja el estado del juego
class GameNotifier extends StateNotifier<GameStateModel?> {
  GameNotifier() : super(null);

  Timer? _turnTimer;

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // INICIALIZACIÓN
  // ──────────────────────────────────────────────

  void initGame({
    required GameMode mode,
    List<String>? playerNames,
  }) {
    state = GameManager.initializeGame(
      mode: mode,
      playerNames: playerNames,
    );
  }

  void startNextRound() {
    final current = state;
    if (current == null) return;
    
    // Si el mazo se acabó, barajar uno nuevo
    if (current.deck.isEmpty) {
      state = GameManager.nextRound(current);
      _triggerAiDealerChoice();
    } else {
      // Siguiente reparto del mismo mazo
      var players = List<PlayerModel>.from(current.players);
      players = players.map((p) => p.copyWith(hand: [])).toList();
      
      // Incrementar el número de ronda para este reparto
      final updatedState = current.copyWith(
        players: players,
        roundNumber: current.roundNumber + 1,
      );
      
      state = GameManager.startDealingSequence(updatedState);
      _processDealingSequence(0);
    }
  }

  void startGame() {
    final current = state;
    if (current == null) return;
    state = GameManager.startGame(current);
    
    // Si el repartidor es IA, elige mesa automáticamente
    _triggerAiDealerChoice();
  }

  void _triggerAiDealerChoice() {
    if (state?.phase == GamePhase.mesaChoice && 
        state?.players[state!.dealerIndex].type == PlayerType.ai) {
      Future.delayed(const Duration(milliseconds: 1500), () => chooseMesa(1));
    }
  }

  void chooseMesa(int startNumber) {
    final current = state;
    if (current == null) return;
    state = GameManager.startMesaDealing(current, startNumber);
    
    // Iniciar secuencia de repartida secuencial de mesa inmediatamente
    _processMesaDealing();
  }

  void _processMesaDealing() {
    final current = state;
    if (current == null || current.animMesaIndex == -1) return;

    // Agregar la carta a la mesa inmediatamente
    state = GameManager.addMesaCardSequentially(current);
    
    // Esperar 1500ms para que se visualicen la carta y el número al mismo tiempo
    Future.delayed(const Duration(milliseconds: 1500), () {
      final freshState = state;
      if (freshState == null) return;

      if (freshState.animMesaIndex != -1) {
        _processMesaDealing();
      } else {
        // Limpiar la animación de la mesa
        state = freshState.copyWith(clearAnimation: true);
        
        // Esperar 1000ms antes de empezar a repartir las manos de los jugadores
        Future.delayed(const Duration(milliseconds: 1000), () {
          final dealState = state;
          if (dealState == null) return;
          state = GameManager.startDealingSequence(dealState);
          _processDealingSequence(0);
        });
      }
    });
  }

  void _processDealingSequence(int cardsDealt) {
    // Total de cartas a repartir: handSize (3) * playerCount (4) = 12
    const totalToDeal = GameConstants.handSize * GameConstants.playerCount;

    if (cardsDealt >= totalToDeal) {
      state = GameManager.finishDealing(state!);
      // Después de repartir, ir directamente al primer turno y activar el temporizador
      _startTimer();
      if (state!.currentPlayer.type == PlayerType.ai) {
         Future.delayed(const Duration(milliseconds: 1200), _aiTurn);
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      final current = state;
      if (current == null) return;
      
      state = GameManager.dealOneCard(current);
      _processDealingSequence(cardsDealt + 1);
    });
  }

  // ──────────────────────────────────────────────
  // TEMPORIZADOR
  // ──────────────────────────────────────────────

  void _startTimer() {
    _turnTimer?.cancel();
    state = state?.copyWith(turnTimer: 30);
    
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state;
      if (current == null || current.phase != GamePhase.playing) {
        timer.cancel();
        return;
      }

      if (current.turnTimer > 0) {
        state = current.copyWith(turnTimer: current.turnTimer - 1);
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    final current = state;
    if (current == null) return;
    
    // Si se acaba el tiempo, la IA juega por el humano o la IA juega su turno
    if (current.currentPlayer.type == PlayerType.human) {
      // El humano pierde el turno o juega una carta al azar
      if (current.currentPlayer.hand.isNotEmpty) {
        playCard(current.currentPlayer.hand.first);
      }
    } else {
      _aiTurn();
    }
  }

  // ──────────────────────────────────────────────
  // CANTOS
  // ──────────────────────────────────────────────


  // ──────────────────────────────────────────────
  // JUGADAS
  // ──────────────────────────────────────────────

  void playCard(CardModel card) {
    final current = state;
    if (current == null) return;
    if (current.phase != GamePhase.playing) return;

    // Bug 3 Fix: bloquear si ya hay una animación de carta en curso (evita doble tap)
    if (current.animatingPlayCard != null) return;

    _animateAndPlayCard(card, 0);
  }

  void _animateAndPlayCard(CardModel card, int playerIndex) {
    final current = state;
    if (current == null) return;

    // Quitar temporalmente la carta de la mano del jugador actual para que desaparezca
    var players = List<PlayerModel>.from(current.players);
    players[playerIndex] = players[playerIndex].copyWith(
      hand: players[playerIndex].hand.where((c) => c.id != card.id).toList(),
    );

    // Determinar si la jugada resulta en caída (si la carta actual es igual a la última jugada)
    final isCaida = current.lastPlayedCard != null && current.lastPlayedCard!.value == card.value;

    // Determinar si hay canto precalculado y es la primera carta del jugador (mano = 3)
    final player = current.players[playerIndex];
    String? cantoName;
    if (player.hand.length == 3) {
      final idx = current.pendingCantos.indexWhere((c) => c.playerId == player.id);
      if (idx != -1) {
        cantoName = current.pendingCantos[idx].typeName.toUpperCase();
      }
    }

    // Determinar si hay captura y qué cartas se capturan
    final captureResult = CaptureEngine.tryCapture(card, current.mesa);
    final capturedCards = captureResult.success ? captureResult.capturedCards : <CardModel>[];

    state = current.copyWith(
      players: players,
      animatingPlayCard: card,
      animatingPlayCardPlayerIndex: playerIndex,
      animatingCapturedCards: capturedCards,
      animatingIsCaida: isCaida,
      animatingCantoName: cantoName,
    );
  }

  void completePlayCard(CardModel card) {
    final freshState = state;
    if (freshState == null) return;

    // Jugar la carta oficialmente
    state = GameManager.playCard(freshState, card);

    // Esperar 1000ms antes del siguiente turno (para asimilar el resultado en mesa)
    Future.delayed(const Duration(milliseconds: 1000), () {
      _processAfterPlay();
    });
  }

  void _processAfterPlay() {
    final current = state;
    if (current == null) return;

    if (current.phase == GamePhase.roundEnd || current.phase == GamePhase.gameOver) {
      _turnTimer?.cancel();
      return;
    }

    _startTimer(); // Reiniciar timer para el siguiente jugador

    // Si es turno de la IA, jugar automáticamente
    if (current.phase == GamePhase.playing &&
        current.currentPlayer.type == PlayerType.ai) {
      Future.delayed(const Duration(milliseconds: 1200), _aiTurn);
    }
  }

  void _aiTurn() {
    final current = state;
    if (current == null) return;
    if (current.phase != GamePhase.playing) return;
    if (current.currentPlayer.type != PlayerType.ai) return;

    final card = GameManager.aiChooseCard(current);
    if (card == null) return;

    _animateAndPlayCard(card, current.currentPlayerIndex);
  }

  void rematch() {
    _turnTimer?.cancel();
    final current = state;
    if (current == null) return;

    state = GameManager.startRematch(current);

    // Si el nuevo repartidor es IA, elige mesa automáticamente
    _triggerAiDealerChoice();
  }

  void resetGame() {
    _turnTimer?.cancel();
    state = null;
  }
}

/// Provider del estado del juego
final gameProvider =
    StateNotifierProvider<GameNotifier, GameStateModel?>(
  (ref) => GameNotifier(),
);

/// Provider conveniente solo para la fase actual
final gamePhaseProv = Provider<GamePhase?>((ref) {
  return ref.watch(gameProvider)?.phase;
});

/// Provider para el jugador actual
final currentPlayerProvider = Provider((ref) {
  return ref.watch(gameProvider)?.currentPlayer;
});

/// Provider para las cartas en mesa
final mesaProvider = Provider<List>((ref) {
  return ref.watch(gameProvider)?.mesa ?? [];
});

/// Provider para verificar si es el turno del humano
final isHumanTurnProvider = Provider<bool>((ref) {
  final state = ref.watch(gameProvider);
  if (state == null) return false;
  return state.currentPlayer.type == PlayerType.human &&
      state.phase == GamePhase.playing;
});

/// Provider para los cantos de la ronda actual
final cantosProvider = Provider((ref) {
  return ref.watch(gameProvider)?.cantos ?? [];
});

/// Provider temporal para ocultar cartas de la mesa durante las animaciones de captura
final hiddenMesaCardsProvider = StateProvider<Set<String>>((ref) => {});
