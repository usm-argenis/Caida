import 'package:flutter/foundation.dart';
import 'card_model.dart';
import 'player_model.dart';
import 'canto_model.dart';

/// Fases del juego
enum GamePhase {
  setup,        // Configuración inicial
  dealing,      // Repartiendo cartas
  mesaChoice,   // Elección de cartas iniciales en mesa (1 o 4)
  playing,      // Jugando
  roundEnd,     // Fin de ronda
  gameOver,     // Fin del juego
}

/// Modo de juego
enum GameMode {
  individual,   // 4 jugadores individuales
  teams,        // 2 parejas (jugadores 0&2 vs 1&3)
}

/// Estado completo del juego
@immutable
class GameStateModel {
  final List<PlayerModel> players;
  final List<CardModel> mesa;         // Cartas en la mesa
  final List<CardModel> deck;         // Mazo restante
  final int currentPlayerIndex;       // Índice del jugador actual
  final int dealerIndex;              // Índice del repartidor
  final GamePhase phase;
  final GameMode mode;
  final int roundNumber;              // Número de ronda actual
  final List<CantoModel> cantos;      // Cantos de esta ronda
  final bool cantoPhaseComplete;      // Si la fase de canto terminó
  final String? message;             // Mensaje para mostrar al usuario
  final List<CardModel>? lastCapture; // Última captura realizada
  final bool mesaLimpia;             // Si se hizo mesa limpia
  final CardModel? lastPlayedCard;   // Última carta lanzada a la mesa
  final int? lastCardPlayerIndex;     // Índice del jugador que lanzó la última carta
  final int animMesaIndex;           // Índice de carta animándose (0-3)
  final int? animMesaValue;          // Valor "cantado" que se muestra en grande
  final bool isDescendingMesa;       // Si la cuenta es 4,3,2,1
  final List<CantoModel> pendingCantos; // Cantos de este reparto esperando resolución
  final String? lastCapturerId;      // ID del último jugador que capturó (se lleva la mesa al final)
  final CardModel? animatingPlayCard; // Carta jugándose actualmente (en animación)
  final int? animatingPlayCardPlayerIndex; // Índice del jugador que la está jugando
  final List<CardModel>? animatingCapturedCards; // Cartas capturadas por el movimiento actual
  final bool animatingIsCaida;       // Booleano indicando si la jugada resulta en caída
  final CardModel? animatingMesaCard; // Carta repartiéndose a la mesa (en animación)
  final String? animatingCantoName; // Canto que se anuncia
  final int mesaHitsCount; // Rastrear aciertos en mesa inicial (Bug 1 de ronda 2)

  const GameStateModel({
    required this.players,
    required this.mesa,
    required this.deck,
    required this.currentPlayerIndex,
    required this.dealerIndex,
    required this.phase,
    required this.mode,
    required this.roundNumber,
    required this.cantos,
    required this.cantoPhaseComplete,
    this.message,
    this.lastCapture,
    this.mesaLimpia = false,
    this.turnTimer = 30,
    this.lastPlayedCard,
    this.lastCardPlayerIndex,
    this.animMesaIndex = -1,
    this.animMesaValue,
    this.isDescendingMesa = false,
    this.pendingCantos = const [],
    this.lastCapturerId,
    this.animatingPlayCard,
    this.animatingPlayCardPlayerIndex,
    this.animatingCapturedCards,
    this.animatingIsCaida = false,
    this.animatingMesaCard,
    this.animatingCantoName,
    this.mesaHitsCount = 0,
  });

  final int turnTimer;

  /// Jugador actual
  PlayerModel get currentPlayer => players[currentPlayerIndex];

  /// Índice del siguiente jugador
  int get nextPlayerIndex => (currentPlayerIndex + 1) % players.length;

  /// ¿Hay un ganador?
  PlayerModel? get winner {
    if (mode == GameMode.individual) {
      for (final p in players) {
        if (p.score >= 24) return p;
      }
    } else {
      // Verificar por equipos
      final team0Score = players
          .where((p) => p.teamIndex == 0)
          .fold(0, (sum, p) => sum + p.score);
      final team1Score = players
          .where((p) => p.teamIndex == 1)
          .fold(0, (sum, p) => sum + p.score);
      if (team0Score >= 24) {
        return players.firstWhere((p) => p.teamIndex == 0);
      }
      if (team1Score >= 24) {
        return players.firstWhere((p) => p.teamIndex == 1);
      }
    }
    return null;
  }

  /// Puntaje del equipo 0
  int get team0Score => players
      .where((p) => p.teamIndex == 0)
      .fold(0, (sum, p) => sum + p.score);

  /// Puntaje del equipo 1
  int get team1Score => players
      .where((p) => p.teamIndex == 1)
      .fold(0, (sum, p) => sum + p.score);

  GameStateModel copyWith({
    List<PlayerModel>? players,
    List<CardModel>? mesa,
    List<CardModel>? deck,
    int? currentPlayerIndex,
    int? dealerIndex,
    GamePhase? phase,
    GameMode? mode,
    int? roundNumber,
    List<CantoModel>? cantos,
    bool? cantoPhaseComplete,
    String? message,
    List<CardModel>? lastCapture,
    bool? mesaLimpia,
    int? turnTimer,
    CardModel? lastPlayedCard,
    int? lastCardPlayerIndex,
    int? animMesaIndex,
    int? animMesaValue,
    bool? isDescendingMesa,
    List<CantoModel>? pendingCantos,
    String? lastCapturerId,
    CardModel? animatingPlayCard,
    int? animatingPlayCardPlayerIndex,
    List<CardModel>? animatingCapturedCards,
    bool? animatingIsCaida,
    CardModel? animatingMesaCard,
    String? animatingCantoName,
    int? mesaHitsCount,
    bool clearAnimation = false,
    bool clearLastPlayedCard = false,
    bool clearAnimMesa = false,
  }) {
    return GameStateModel(
      players: players ?? this.players,
      mesa: mesa ?? this.mesa,
      deck: deck ?? this.deck,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      roundNumber: roundNumber ?? this.roundNumber,
      cantos: cantos ?? this.cantos,
      cantoPhaseComplete: cantoPhaseComplete ?? this.cantoPhaseComplete,
      message: message ?? this.message,
      lastCapture: lastCapture,
      mesaLimpia: mesaLimpia ?? this.mesaLimpia,
      turnTimer: turnTimer ?? this.turnTimer,
      lastPlayedCard: clearLastPlayedCard ? null : (lastPlayedCard ?? this.lastPlayedCard),
      lastCardPlayerIndex: clearLastPlayedCard ? null : (lastCardPlayerIndex ?? this.lastCardPlayerIndex),
      animMesaIndex: clearAnimMesa ? -1 : (animMesaIndex ?? this.animMesaIndex),
      animMesaValue: clearAnimMesa ? null : (animMesaValue ?? this.animMesaValue),
      isDescendingMesa: isDescendingMesa ?? this.isDescendingMesa,
      pendingCantos: pendingCantos ?? this.pendingCantos,
      lastCapturerId: lastCapturerId ?? this.lastCapturerId,
      animatingPlayCard: clearAnimation ? null : (animatingPlayCard ?? this.animatingPlayCard),
      animatingPlayCardPlayerIndex: clearAnimation ? null : (animatingPlayCardPlayerIndex ?? this.animatingPlayCardPlayerIndex),
      animatingCapturedCards: clearAnimation ? null : (animatingCapturedCards ?? this.animatingCapturedCards),
      animatingIsCaida: clearAnimation ? false : (animatingIsCaida ?? this.animatingIsCaida),
      animatingMesaCard: (clearAnimation || clearAnimMesa) ? null : (animatingMesaCard ?? this.animatingMesaCard),
      animatingCantoName: clearAnimation ? null : (animatingCantoName ?? this.animatingCantoName),
      mesaHitsCount: mesaHitsCount ?? this.mesaHitsCount,
    );
  }
}
