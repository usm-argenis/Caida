import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/game_state_model.dart';
import '../models/canto_model.dart';
import '../core/game_constants.dart';
import 'deck_manager.dart';
import 'turn_manager.dart';
import 'capture_engine.dart';
import 'canto_engine.dart';
import 'score_engine.dart';
import 'rules_engine.dart';

/// GameManager - Controla TODO el flujo del juego Caída
/// Es el único punto de entrada para modificar el estado del juego
class GameManager {
  GameManager._();

  // ──────────────────────────────────────────────
  // INICIALIZACIÓN
  // ──────────────────────────────────────────────

  /// Crea el estado inicial del juego
  static GameStateModel initializeGame({
    required GameMode mode,
    List<String>? playerNames,
  }) {
    final names = playerNames ??
        ['Tú', 'Jugador 2', 'Jugador 3', 'Jugador 4'];

    final players = List.generate(GameConstants.playerCount, (i) {
      return PlayerModel(
        id: 'player_$i',
        name: names[i],
        type: i == 0 ? PlayerType.human : PlayerType.ai,
        teamIndex: i % 2, // 0&2 son equipo 0, 1&3 son equipo 1
      );
    });

    final deck = DeckManager.shuffleRandom(DeckManager.createDeck());

    return GameStateModel(
      players: players,
      mesa: [],
      deck: deck,
      currentPlayerIndex: 0,
      dealerIndex: 0,
      phase: GamePhase.setup,
      mode: mode,
      roundNumber: 0,
      cantos: [],
      cantoPhaseComplete: false,
      message: 'Iniciando juego...',
    );
  }

  // ──────────────────────────────────────────────
  // INICIO DE PARTIDA
  // ──────────────────────────────────────────────

  /// Inicia la partida
  static GameStateModel startGame(GameStateModel state) {
    final newState = state.copyWith(
      roundNumber: 1,
      dealerIndex: 0,
      phase: GamePhase.mesaChoice,
      message: '${state.players[state.dealerIndex].name} debe elegir: ¿1 o 4 cartas a la mesa?',
    );
    return newState;
  }

  /// Inicia la revancha conservando nombres y modo, pero reiniciando cartas,
  /// puntajes y asignando el dealer según el ganador de la partida anterior.
  static GameStateModel startRematch(GameStateModel state) {
    final winnerPlayer = state.winner;
    int newDealer = 0;
    
    if (winnerPlayer != null) {
      if (state.mode == GameMode.teams) {
        // En parejas, el primer jugador del equipo ganador es el que reparte (saca)
        final winnerTeamIndex = winnerPlayer.teamIndex;
        newDealer = state.players.indexWhere((p) => p.teamIndex == winnerTeamIndex);
        if (newDealer == -1) newDealer = 0;
      } else {
        // En individual, el ganador reparte (saca)
        newDealer = state.players.indexOf(winnerPlayer);
        if (newDealer == -1) newDealer = 0;
      }
    }

    // Reiniciar los puntajes de los jugadores a 0 y limpiar manos, capturas y cantos
    var players = state.players.map((p) => p.copyWith(
      score: 0,
      hand: [],
      capturedCount: 0,
      currentCanto: null,
    )).toList();

    final deck = DeckManager.shuffleRandom(DeckManager.createDeck());

    return state.copyWith(
      players: players,
      deck: deck,
      mesa: [],
      dealerIndex: newDealer,
      currentPlayerIndex: newDealer, // El dealer elige la mesa primero
      phase: GamePhase.mesaChoice,
      roundNumber: 1,
      cantos: [],
      pendingCantos: [],
      cantoPhaseComplete: false,
      lastCapturerId: null,
      lastPlayedCard: null,
      lastCardPlayerIndex: null,
      animMesaIndex: -1,
      animMesaValue: null,
      clearAnimation: true,
      mesaHitsCount: 0,
      message: '¡Iniciando revancha! ${players[newDealer].name} reparte y elige mesa.',
    );
  }

  /// Inicia el proceso de repartida secuencial de mesa
  static GameStateModel startMesaDealing(GameStateModel state, int startNumber) {
    return state.copyWith(
      phase: GamePhase.dealing,
      animMesaIndex: 0,
      animMesaValue: null,
      animatingMesaCard: null,
      isDescendingMesa: startNumber == 4,
      message: 'Repartiendo mesa...',
      mesaHitsCount: 0, // Reiniciar contador de aciertos en mesa
    );
  }

  /// Procesa una carta de la mesa en la secuencia inicial
  static GameStateModel addMesaCardSequentially(GameStateModel state) {
    if (state.animMesaIndex < 0 || state.animMesaIndex >= 4) return state;

    var deck = List<CardModel>.from(state.deck);
    if (deck.isEmpty) return state;

    // Bug 1 Fix: buscar una carta cuyo VALOR no esté ya en la mesa
    // ni sea el mismo que el valor anunciado de otra posición ya puesta
    final mesaValues = state.mesa.map((c) => c.value).toSet();

    int deckIndex = 0;
    while (deckIndex < deck.length) {
      final candidate = deck[deckIndex];
      if (!mesaValues.contains(candidate.value)) break;
      deckIndex++;
    }

    // Si no encontramos carta única (caso extremadamente raro), usamos la primera disponible
    if (deckIndex >= deck.length) deckIndex = 0;

    final card = deck.removeAt(deckIndex);
    final mesa = [...state.mesa, card];

    // Calcular el valor anunciado según la dirección
    final announcedValue = state.isDescendingMesa ? (4 - state.animMesaIndex) : (1 + state.animMesaIndex);

    int pointsEarned = 0;
    final bool isHit = card.value == announcedValue;
    if (isHit) {
      pointsEarned = card.value;
    }

    var players = List<PlayerModel>.from(state.players);
    if (pointsEarned > 0) {
      final dealerIdx = state.dealerIndex;
      players[dealerIdx] = players[dealerIdx].copyWith(
        score: players[dealerIdx].score + pointsEarned,
      );
    }

    final nextIndex = state.animMesaIndex + 1;
    final nextMesaHitsCount = state.mesaHitsCount + (isHit ? 1 : 0);

    if (nextIndex < 4) {
      return state.copyWith(
        players: players,
        mesa: mesa,
        deck: deck,
        animMesaIndex: nextIndex,
        animMesaValue: announcedValue,
        animatingMesaCard: card,
        mesaHitsCount: nextMesaHitsCount,
        message: pointsEarned > 0 ? '¡MAL DE OJO! (+ $pointsEarned)' : 'Repartiendo mesa...',
      );
    } else {
      // Fin de la repartida de mesa
      var playersClean = List<PlayerModel>.from(players);
      String penaltyMessage = '';

      // Si no hubo ningún acierto en las 4 cartas de la mesa inicial, el equipo contrario recibe 1 punto
      if (nextMesaHitsCount == 0) {
        final dealer = playersClean[state.dealerIndex];
        int penaltyReceiverIdx = -1;
        
        if (state.mode == GameMode.teams) {
          // Parejas: primer oponente directo del equipo contrario
          penaltyReceiverIdx = playersClean.indexWhere((p) => p.teamIndex != dealer.teamIndex);
        } else {
          // Individual: el oponente directo que es "mano" (siguiente al dealer)
          penaltyReceiverIdx = (state.dealerIndex + 1) % playersClean.length;
        }

        if (penaltyReceiverIdx != -1) {
          playersClean[penaltyReceiverIdx] = playersClean[penaltyReceiverIdx].copyWith(
            score: playersClean[penaltyReceiverIdx].score + 1,
          );
          penaltyMessage = '\n¡No pegó ninguna! +1 punto para el equipo contrario (${playersClean[penaltyReceiverIdx].name}).';
        }
      }

      playersClean = playersClean.map((p) => p.copyWith(hand: [], currentCanto: null)).toList();

      return state.copyWith(
        players: playersClean,
        mesa: mesa,
        deck: deck,
        animMesaIndex: -1,
        animMesaValue: announcedValue,
        animatingMesaCard: card,
        mesaHitsCount: nextMesaHitsCount,
        message: 'Mesa repartida.$penaltyMessage',
      );
    }
  }

  // ──────────────────────────────────────────────
  // NUEVA RONDA
  // ──────────────────────────────────────────────

  /// Prepara un nuevo mazo (nueva mano de 40 cartas)
  static GameStateModel _startNewMano(GameStateModel state) {
    final newDealer = (state.dealerIndex + 1) % GameConstants.playerCount;
    final deck = DeckManager.shuffleRandom(DeckManager.createDeck());

    var players = List<PlayerModel>.from(state.players);
    players = players.map((p) => p.copyWith(
      capturedCount: 0,
      currentCanto: null, // Limpiar cantos viejos
    )).toList();

    var newState = state.copyWith(
      players: players,
      deck: deck,
      mesa: [],
      dealerIndex: newDealer,
      currentPlayerIndex:
          TurnManager.getFirstPlayerIndex(newDealer, GameConstants.playerCount),
      phase: GamePhase.mesaChoice,
      roundNumber: 1, // Resetear a la primera ronda de la nueva mano
      cantos: [],
      lastCapturerId: null, // Resetear último en capturar
      clearLastPlayedCard: true,
      message: 'Nuevo mazo barajado. ${state.players[newDealer].name} elige mesa.',
    );

    return newState;
  }

  /// Continúa con el siguiente reparto del mismo mazo
  static GameStateModel _continueMano(GameStateModel state) {
    return startDealingSequence(state);
  }

  /// Inicia la secuencia de reparto de 3 cartas a cada jugador (una por una)
  static GameStateModel startDealingSequence(GameStateModel state) {
    // El reparto empieza por el jugador siguiente al repartidor
    final firstToReceive = (state.dealerIndex + 1) % GameConstants.playerCount;
    
    // Limpiar cantos al iniciar el reparto
    var players = state.players.map((p) => p.copyWith(currentCanto: null)).toList();

    return state.copyWith(
      players: players,
      phase: GamePhase.dealing,
      currentPlayerIndex: firstToReceive,
      message: 'Repartiendo cartas...',
      clearAnimMesa: true,
    );
  }

  /// Reparte una sola carta al jugador actual y pasa al siguiente
  static GameStateModel dealOneCard(GameStateModel state) {
    var deck = List<CardModel>.from(state.deck);
    if (deck.isEmpty) return state;

    final card = deck.removeAt(0);
    var players = List<PlayerModel>.from(state.players);
    final currentIdx = state.currentPlayerIndex;
    
    players[currentIdx] = players[currentIdx].copyWith(
      hand: [...players[currentIdx].hand, card],
    );

    // Siguiente jugador en círculo
    final nextPlayerIdx = (currentIdx + 1) % GameConstants.playerCount;

    return state.copyWith(
      players: players,
      deck: deck,
      currentPlayerIndex: nextPlayerIdx,
    );
  }

  /// Finaliza el reparto y activa la fase de juego, precalculando los cantos de todos los jugadores
  static GameStateModel finishDealing(GameStateModel state) {
    var pendingCantos = <CantoModel>[];
    for (final player in state.players) {
      final canto = CantoEngine.evaluateBestCanto(player.hand, player.id);
      if (canto != null) {
        pendingCantos.add(canto);
      }
    }

    return state.copyWith(
      phase: GamePhase.playing,
      clearLastPlayedCard: true,
      pendingCantos: pendingCantos,
      message: '¡A jugar!',
    );
  }

  // ──────────────────────────────────────────────
  // FASE DE CANTOS
  // ──────────────────────────────────────────────

  /// Evalúa si el jugador actual tiene un canto al iniciar su turno (sin sumar puntos aún)
  static GameStateModel checkPlayerCanto(GameStateModel state) {
    final player = state.currentPlayer;
    final canto = CantoEngine.evaluateBestCanto(player.hand, player.id);

    if (canto == null) return state;

    var players = List<PlayerModel>.from(state.players);
    final currentIdx = state.currentPlayerIndex;
    players[currentIdx] = players[currentIdx].copyWith(
      currentCanto: '¡${canto.typeName.toUpperCase()}!',
    );

    return state.copyWith(
      players: players,
      pendingCantos: [...state.pendingCantos, canto],
      message: '¡${player.name} grita ${canto.typeName.toUpperCase()}!',
    );
  }

  /// Resuelve la prioridad de cantos y otorga puntos solo al mejor
  static GameStateModel resolveCantos(GameStateModel state) {
    if (state.pendingCantos.isEmpty) return state;

    // Ordenar por tipo de canto (prioridad: Registro > Vigía > Patrulla > Ronda)
    // Registro = 4, Vigía = 3, Patrulla = 2, Ronda = 1 (en jerarquía)
    final sortedCantos = List<CantoModel>.from(state.pendingCantos);
    sortedCantos.sort((a, b) {
      // Comparación por tipo primero
      if (b.type.index != a.type.index) {
        return b.type.index.compareTo(a.type.index);
      }
      // Si son del mismo tipo, mayor puntaje (o valor de carta)
      return b.points.compareTo(a.points);
    });

    final winnerCanto = sortedCantos.first;
    final winnerPlayerIdx = state.players.indexWhere((p) => p.id == winnerCanto.playerId);

    if (winnerPlayerIdx == -1) return state;

    var players = List<PlayerModel>.from(state.players);
    players[winnerPlayerIdx] = players[winnerPlayerIdx].copyWith(
      score: players[winnerPlayerIdx].score + winnerCanto.points,
    );

    return state.copyWith(
      players: players,
      cantos: [...state.cantos, winnerCanto],
      pendingCantos: [], // Limpiar para el siguiente reparto
      message: 'Prioridad: ¡${players[winnerPlayerIdx].name} gana ${winnerCanto.points} pts por ${winnerCanto.typeName}!',
    );
  }

  // ──────────────────────────────────────────────
  // JUGAR CARTA
  // ──────────────────────────────────────────────

  /// El jugador actual juega una carta
  /// Si puede capturar, captura; si no, la pone en mesa
  /// El jugador actual juega una carta
  /// Si puede capturar, captura; si no, la pone en mesa
  static GameStateModel playCard(
      GameStateModel state, CardModel card) {
    if (!RulesEngine.canPlayCard(state, card)) {
      return state.copyWith(message: 'No puedes jugar esa carta ahora');
    }

    final currentIdx = state.currentPlayerIndex;
    final currentPlayer = state.players[currentIdx];

    // Verificar si el jugador tiene un canto precalculado y es su primer lanzamiento de la mano (mano = 3)
    CantoModel? playerCanto;
    if (currentPlayer.hand.length == 3) {
      final idx = state.pendingCantos.indexWhere((c) => c.playerId == currentPlayer.id);
      if (idx != -1) {
        playerCanto = state.pendingCantos[idx];
      }
    }

    // Quitar carta de la mano del jugador actual
    var players = List<PlayerModel>.from(state.players);
    
    // Si estamos en la ronda 2 o 3 (menos de 3 cartas en mano), limpiar los cantos de todos los jugadores
    if (currentPlayer.hand.length < 3) {
      players = players.map((p) => p.copyWith(currentCanto: null)).toList();
    }

    final newHand =
        currentPlayer.hand.where((c) => c.id != card.id).toList();
    
    // Si tiene canto, se muestra visualmente en el avatar de inmediato
    players[currentIdx] = players[currentIdx].copyWith(
      hand: newHand,
      currentCanto: playerCanto != null ? '¡${playerCanto.typeName.toUpperCase()}!' : null,
    );

    var newState = state.copyWith(players: players, clearAnimation: true);
    
    // Verificar Caída (si la carta actual es igual a la última jugada)
    int caidaPoints = 0;
    if (state.lastPlayedCard != null && state.lastPlayedCard!.value == card.value) {
      caidaPoints = switch (card.value) {
        10 => 2,
        11 => 3,
        12 => 4,
        _ => 1,
      };
      
      // Aplicar puntos de caída
      var updatedPlayers = List<PlayerModel>.from(newState.players);
      updatedPlayers[currentIdx] = updatedPlayers[currentIdx].copyWith(
        score: updatedPlayers[currentIdx].score + caidaPoints,
      );
      newState = newState.copyWith(players: updatedPlayers);
    }

    // Actualizar la última carta jugada ANTES de procesar la captura
    newState = newState.copyWith(
      lastPlayedCard: card,
      lastCardPlayerIndex: currentIdx,
    );

    // Intentar captura
    final captureResult = CaptureEngine.tryCapture(card, state.mesa);

    if (captureResult.success) {
      newState = _handleCapture(newState, card, captureResult);
      if (caidaPoints > 0) {
        newState = newState.copyWith(
          message: '¡CAÍDA! +$caidaPoints pts para ${currentPlayer.name}',
        );
      }
    } else {
      // Poner carta en mesa
      final newMesa = [...state.mesa, card];
      newState = newState.copyWith(
        mesa: newMesa,
        lastCapture: null,
        mesaLimpia: false,
        message: caidaPoints > 0 
            ? '¡CAÍDA! +$caidaPoints pts para ${currentPlayer.name}'
            : (playerCanto != null 
                ? '¡${currentPlayer.name} canta ${playerCanto.typeName.toUpperCase()}!'
                : '${currentPlayer.name} pone ${card.value} en mesa'),
      );
    }

    // Verificar victoria
    if (RulesEngine.isGameOver(newState)) {
      return newState.copyWith(phase: GamePhase.gameOver);
    }

    // Verificar si todos jugaron sus 3 cartas
    if (newState.players.every((p) => p.hand.isEmpty)) {
      // Los puntos de canto se agregan al finalizar esa ronda de 3 cartas (cuando el último jugador tire su última carta)
      if (newState.pendingCantos.isNotEmpty) {
        newState = _resolveAndScoreCantos(newState);
      }
      return _endRound(newState);
    }

    // Siguiente turno
    return TurnManager.nextTurn(newState);
  }

  /// Resuelve los cantos y suma el puntaje al ganador de prioridad al finalizar la primera ronda.
  /// Bug 2 Fix: este es el ÚNICO lugar donde se suman puntos de cantos.
  static GameStateModel _resolveAndScoreCantos(GameStateModel state) {
    if (state.pendingCantos.isEmpty) return state;

    // Ordenar por tipo (mayor enum index = mayor prioridad: tribilin > registro > vigia > patrulla > ronda)
    final sortedCantos = List<CantoModel>.from(state.pendingCantos);
    sortedCantos.sort((a, b) {
      if (b.type.index != a.type.index) {
        return b.type.index.compareTo(a.type.index);
      }
      return b.points.compareTo(a.points);
    });

    final winnerCanto = sortedCantos.first;
    final winnerPlayerIdx = state.players.indexWhere((p) => p.id == winnerCanto.playerId);

    if (winnerPlayerIdx == -1) return state;

    // Bug 4: Si el canto ganador es Tribilín, aplicar reglas especiales
    if (winnerCanto.type == CantoType.tribilin) {
      // Ronda 1 o 3 (primera o última ronda del reparto): ganar la partida automáticamente
      // Ronda 2 (ronda del medio): solo sumar 5 puntos
      if (state.roundNumber == 2) {
        // Ronda del medio: solo +5 puntos
        var players = List<PlayerModel>.from(state.players);
        players[winnerPlayerIdx] = players[winnerPlayerIdx].copyWith(
          score: players[winnerPlayerIdx].score + winnerCanto.points,
        );
        players = players.map((p) => p.copyWith(currentCanto: null)).toList();
        players[winnerPlayerIdx] = players[winnerPlayerIdx].copyWith(
          currentCanto: '🏆 ¡TRIBILÍN!',
        );
        final result = state.copyWith(
          players: players,
          cantos: [...state.cantos, winnerCanto],
          pendingCantos: [],
          message: '¡TRIBILÍN! ${players[winnerPlayerIdx].name} gana +${winnerCanto.points} pts',
        );
        if (RulesEngine.isGameOver(result)) {
          return result.copyWith(phase: GamePhase.gameOver);
        }
        return result;
      } else {
        // Ronda 1 o 3: ganar la partida
        var players = List<PlayerModel>.from(state.players);
        // Dar suficientes puntos para ganar
        players[winnerPlayerIdx] = players[winnerPlayerIdx].copyWith(
          score: 24, // Forzar puntuación ganadora
        );
        players = players.map((p) => p.copyWith(currentCanto: null)).toList();
        players[winnerPlayerIdx] = players[winnerPlayerIdx].copyWith(
          currentCanto: '🏆 ¡TRIBILÍN!',
        );
        return state.copyWith(
          players: players,
          cantos: [...state.cantos, winnerCanto],
          pendingCantos: [],
          phase: GamePhase.gameOver,
          message: '¡TRIBILÍN! ${players[winnerPlayerIdx].name} ¡GANA LA PARTIDA!',
        );
      }
    }

    // Canto normal: sumar puntos solo al ganador
    var players = List<PlayerModel>.from(state.players);
    players[winnerPlayerIdx] = players[winnerPlayerIdx].copyWith(
      score: players[winnerPlayerIdx].score + winnerCanto.points,
    );

    // Ocultar cantos individuales del primer turno y destacar al ganador
    players = players.map((p) => p.copyWith(currentCanto: null)).toList();
    players[winnerPlayerIdx] = players[winnerPlayerIdx].copyWith(
      currentCanto: '🏆 ¡${winnerCanto.typeName.toUpperCase()}!',
    );

    final result = state.copyWith(
      players: players,
      cantos: [...state.cantos, winnerCanto],
      pendingCantos: [], // Limpiar cantos pendientes
      message: '¡${players[winnerPlayerIdx].name} gana ${winnerCanto.points} pts por ${winnerCanto.typeName}!',
    );

    if (RulesEngine.isGameOver(result)) {
      return result.copyWith(phase: GamePhase.gameOver);
    }
    return result;
  }

  static GameStateModel _handleCapture(
    GameStateModel state,
    CardModel playedCard,
    CaptureResult captureResult,
  ) {
    final currentIdx = state.currentPlayerIndex;
    var players = List<PlayerModel>.from(state.players);
    final currentPlayer = players[currentIdx];

    // Actualizar mesa
    final capturedIds = captureResult.capturedCards.map((c) => c.id).toSet();
    final newMesa =
        state.mesa.where((c) => !capturedIds.contains(c.id)).toList();

    // Actualizar capturas del jugador (+1 por carta jugada + capturas)
    final totalCaptured = captureResult.capturedCards.length + 1; // +carta jugada
    players[currentIdx] = currentPlayer.copyWith(
      capturedCount: currentPlayer.capturedCount + totalCaptured,
    );

    var newState = state.copyWith(
      players: players,
      mesa: newMesa,
      lastCapture: captureResult.capturedCards,
      mesaLimpia: captureResult.mesaLimpia,
      lastCapturerId: currentPlayer.id, // Rastrear quién capturó por última vez
      clearLastPlayedCard: true,
      message: captureResult.mesaLimpia
          ? '¡Mesa limpia! ${currentPlayer.name} captura todo'
          : '${currentPlayer.name} captura ${captureResult.capturedCards.length + 1} carta(s)',
    );

    // Aplicar bonus de mesa limpia
    if (captureResult.mesaLimpia) {
      newState =
          ScoreEngine.applyMesaLimpiaBonus(newState, currentPlayer.id);
    }

    return newState;
  }

  // ──────────────────────────────────────────────
  // FIN DE RONDA
  // ──────────────────────────────────────────────

  static GameStateModel _endRound(GameStateModel state) {
    var newState = state;

    // Limpiar los cantos de todos los jugadores al finalizar la ronda de 3 cartas (para que no queden en la siguiente ronda)
    var playersCleanCanto = List<PlayerModel>.from(newState.players);
    playersCleanCanto = playersCleanCanto.map((p) => p.copyWith(currentCanto: null)).toList();
    newState = newState.copyWith(players: playersCleanCanto);

    // Verificar victoria
    if (RulesEngine.isGameOver(newState)) {
      return newState.copyWith(phase: GamePhase.gameOver);
    }

    // ¿Hay más cartas para repartir?
    if (newState.deck.isEmpty) {
      // Regla: El último en capturar se lleva lo que queda en la mesa
      if (newState.mesa.isNotEmpty && newState.lastCapturerId != null) {
        final lastCapturerIdx = newState.players.indexWhere((p) => p.id == newState.lastCapturerId);
        if (lastCapturerIdx != -1) {
          var players = List<PlayerModel>.from(newState.players);
          players[lastCapturerIdx] = players[lastCapturerIdx].copyWith(
            capturedCount: players[lastCapturerIdx].capturedCount + newState.mesa.length,
          );
          newState = newState.copyWith(players: players, mesa: []);
        }
      }

      // Fin del mazo: contar capturas acumuladas
      newState = ScoreEngine.applyRoundScore(newState);
      
      final scoreMsg = newState.message;
      if (RulesEngine.isGameOver(newState)) {
        return newState.copyWith(
          phase: GamePhase.gameOver,
          message: '¡Juego terminado!\n$scoreMsg',
        );
      }

      return newState.copyWith(
        phase: GamePhase.roundEnd,
        message: '¡El último en capturar se llevó la mesa!\n$scoreMsg',
      );
    }

    return newState.copyWith(phase: GamePhase.roundEnd);
  }

  /// Avanza al siguiente reparto o a una nueva mano de 40 cartas
  static GameStateModel nextRound(GameStateModel state) {
    if (state.deck.isEmpty) {
      return _startNewMano(state);
    } else {
      return _continueMano(state);
    }
  }

  // ──────────────────────────────────────────────
  // IA
  // ──────────────────────────────────────────────

  /// El jugador IA elige automáticamente una carta para jugar
  static CardModel? aiChooseCard(GameStateModel state) {
    final aiPlayer = state.currentPlayer;
    if (aiPlayer.hand.isEmpty) return null;

    // Estrategia simple: intentar capturar si es posible
    for (final card in aiPlayer.hand) {
      if (CaptureEngine.canCapture(card, state.mesa)) {
        return card;
      }
    }

    // Si no puede capturar, jugar la primera carta
    return aiPlayer.hand.first;
  }

  /// El jugador IA juega automáticamente
  static GameStateModel aiPlay(GameStateModel state) {
    final card = aiChooseCard(state);
    if (card == null) return state;
    return playCard(state, card);
  }
}
