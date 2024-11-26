import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/multiplayer_game.dart';

class GameScreen extends StatefulWidget {
  final String gameId;
  final String playerId;

  const GameScreen({
    super.key,
    required this.gameId,
    required this.playerId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  MultiplayerGame? game;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGame();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _enforceOrientation();
  }

  Future<void> _enforceOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializeGame() async {
    await _enforceOrientation();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!mounted) return;

    setState(() {
      game = MultiplayerGame(
        gameId: widget.gameId,
        playerId: widget.playerId,
      );
      isInitialized = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Oyun
            GameWidget(game: game!),

            // Üst bilgi çubuğu
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Geri sayım / Oyuncu bilgisi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: game!.countdownNotifier,
                        builder: (context, int countdown, _) {
                          return Text(
                            countdown > 0
                                ? 'Başlamasına: $countdown'
                                : 'Oyun Başladı!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    // Çıkış butonu
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Oyundan Çık'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zıplama butonu
            Positioned(
              left: 16,
              bottom: 16,
              child: GestureDetector(
                onTapDown: (_) => game?.jump(),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Skill göstergeleri
            Positioned(
              right: 16,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSkillIndicator(
                    icon: Icons.ac_unit,
                    label: 'Dondur',
                    color: Colors.lightBlue,
                  ),
                  const SizedBox(width: 8),
                  _buildSkillIndicator(
                    icon: Icons.undo,
                    label: 'Geri Çek',
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _buildSkillIndicator(
                    icon: Icons.block,
                    label: 'Engelle',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildSkillIndicator(
                    icon: Icons.speed,
                    label: 'Hızlan',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillIndicator({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
