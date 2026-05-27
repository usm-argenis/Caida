import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state_model.dart';
import '../providers/game_provider.dart';
import '../core/app_theme.dart';
import 'game_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla principal de inicio / menú del juego
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<TextEditingController> _nameControllers = List.generate(
    4,
    (i) => TextEditingController(
        text: i == 0 ? 'Tú' : 'Jugador ${i + 1}'),
  );

  GameMode _selectedMode = GameMode.teams;
  int _mesaCards = 0; // 0 = reparto normal
  bool _showNameConfig = false;
  bool _preloaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preloaded) {
      _preloaded = true;
      _preloadImages();
    }
  }

  void _preloadImages() {
    final suits = ['oro', 'copa', 'espada', 'basto'];
    final values = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];
    for (final s in suits) {
      for (final v in values) {
        precacheImage(
          AssetImage('lib/image/${v}_$s.png'),
          context,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    final names = _nameControllers.map((c) => c.text.trim()).toList();
    ref.read(gameProvider.notifier).initGame(
          mode: _selectedMode,
          playerNames: names,
        );

    ref.read(gameProvider.notifier).startGame();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const GameScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildTitle(),
                    const SizedBox(height: 50),
                    _buildModeSelector(),
                    const SizedBox(height: 24),
                    _buildMesaSelector(),
                    const SizedBox(height: 24),
                    _buildNameConfig(),
                    const SizedBox(height: 40),
                    _buildStartButton(),
                    const SizedBox(height: 24),
                    _buildRulesCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        // Logo animado con cartas
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['🃏', '⚔️', '🃏'].map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(e, style: const TextStyle(fontSize: 36)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.goldGradient.createShader(bounds),
          child: Text(
            'LA CAÍDA',
            style: GoogleFonts.cinzel(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'JUEGO DE CARTAS VENEZOLANO',
          style: GoogleFonts.lato(
            color: AppTheme.textSecondary,
            fontSize: 13,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MODO DE JUEGO',
            style: GoogleFonts.cinzel(
              color: AppTheme.primary,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  title: 'Individual',
                  icon: Icons.person,
                  description: '4 jugadores,\npuntaje individual',
                  isSelected: _selectedMode == GameMode.individual,
                  onTap: () =>
                      setState(() => _selectedMode = GameMode.individual),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  title: 'Parejas',
                  icon: Icons.people,
                  description: '2 equipos de 2,\npuntaje por equipo',
                  isSelected: _selectedMode == GameMode.teams,
                  onTap: () => setState(() => _selectedMode = GameMode.teams),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMesaSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INICIO DE PARTIDA',
            style: GoogleFonts.cinzel(
              color: AppTheme.primary,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StartOption(
                title: 'Normal',
                icon: Icons.style,
                isSelected: _mesaCards == 0,
                onTap: () => setState(() => _mesaCards = 0),
              ),
              const SizedBox(width: 8),
              ...List.generate(4, (i) {
                final n = i + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _StartOption(
                    title: '$n en mesa',
                    icon: Icons.table_bar,
                    isSelected: _mesaCards == n,
                    onTap: () => setState(() => _mesaCards = n),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameConfig() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _showNameConfig = !_showNameConfig),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NOMBRES DE JUGADORES',
                  style: GoogleFonts.cinzel(
                    color: AppTheme.primary,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _showNameConfig
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
          if (_showNameConfig) ...[
            const SizedBox(height: 16),
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _nameControllers[i],
                  style: GoogleFonts.lato(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText:
                        i == 0 ? 'Tu nombre' : 'Jugador ${i + 1}',
                    labelStyle:
                        GoogleFonts.lato(color: AppTheme.textSecondary),
                    prefixIcon: Icon(
                      i == 0 ? Icons.person : Icons.smart_toy,
                      color: AppTheme.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.primary),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withOpacity(0.5),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              '¡JUGAR AHORA!',
              style: GoogleFonts.cinzel(
                color: AppTheme.background,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CANTOS',
            style: GoogleFonts.cinzel(
              color: AppTheme.primary,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _RuleRow('🎯 Ronda', '1-4 pts (par de 2,10,11,12)'),
          _RuleRow('🎵 Patrulla', '6 pts (3 consecutivas)'),
          _RuleRow('👁 Vigía', '7 pts (par + consecutiva)'),
          _RuleRow('📋 Registro', '8 pts (1,11,12)'),
          const Divider(color: AppTheme.surfaceVariant),
          const SizedBox(height: 8),
          Text(
            'Secuencia: 1-2-3-4-5-6-7-10-11-12\n(NO existen cartas 8 ni 9)',
            style: GoogleFonts.lato(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🏆 Gana quien llegue a 24 puntos',
            style: GoogleFonts.lato(
              color: AppTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cinzel(
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StartOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.2)
              : AppTheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.lato(
                color:
                    isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String title;
  final String description;

  const _RuleRow(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: GoogleFonts.cinzel(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.lato(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
