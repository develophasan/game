import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'player.dart';
import 'platform.dart';
import 'skill.dart';

class MultiplayerGame extends FlameGame {
  final String gameId;
  final String playerId;
  final DatabaseReference gameRef;
  final Map<String, Player> players = {};
  DateTime _lastUpdate = DateTime.now();
  static const updateThreshold = Duration(milliseconds: 50);

  // Oyun boyutları
  static const gameWidth = 5000.0;
  static const gameHeight = 600.0;
  static const groundHeight = 50.0;

  // Oyun durumu
  bool isGameStarted = false;
  int countdown = 10;
  final countdownNotifier = ValueNotifier<int>(10);

  // Platform ve zemin
  late Platform platform;
  late RectangleComponent ground;

  MultiplayerGame({
    required this.gameId,
    required this.playerId,
  }) : gameRef = FirebaseDatabase.instance.ref().child('games/$gameId') {
    // Kamera ayarları
    camera = CameraComponent(world: world)
      ..viewfinder.anchor = Anchor.topLeft
      ..viewfinder.zoom = 1.0;
  }

  @override
  Future<void> onLoad() async {
    // Zemin oluşturma (siyah)
    ground = RectangleComponent(
      position:
          Vector2(0, Player.platformY + 10), // Platform yüksekliğinin altında
      size: Vector2(gameWidth, groundHeight),
      paint: Paint()..color = Colors.black,
    );
    world.add(ground);

    // Platform oluşturma (gri)
    platform = Platform(
      position: Vector2(0, Player.platformY), // Sabit platform yüksekliği
      size: Vector2(gameWidth, 10),
    );
    world.add(platform);

    // Oyuncuları dinle
    gameRef.child('players').onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final playersData =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      _updatePlayers(playersData);
    });

    // Geri sayımı başlat
    startCountdown();
  }

  void _updatePlayers(Map<String, dynamic> playersData) {
    playersData.forEach((id, data) {
      final playerData = Map<String, dynamic>.from(data);
      final username = playerData['username'] as String;

      if (!players.containsKey(id)) {
        // Yeni oyuncu oluştur
        final isCurrentPlayer = id == playerId;
        final playerColor = _getPlayerColor(id);

        final player = Player(
          id: id,
          username: username,
          position: Vector2(100 + players.length * 100,
              Player.platformY - 40), // Platform üzerinde başlat
          size: Vector2(40, 40),
          color: playerColor,
          isCurrentPlayer: isCurrentPlayer,
        );

        players[id] = player;
        world.add(player);
      }

      // Pozisyon güncelleme
      if (playerData.containsKey('position')) {
        final pos = Map<String, dynamic>.from(playerData['position']);
        final x = (pos['x'] as num).toDouble();
        final y = (pos['y'] as num).toDouble();
        if (id != playerId) {
          players[id]?.updatePosition(Vector2(x, y));
        }
      }
    });
  }

  Color _getPlayerColor(String id) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    final index = id.hashCode % colors.length;
    return colors[index];
  }

  void startCountdown() async {
    while (countdown > 0) {
      countdownNotifier.value = countdown;
      await Future.delayed(const Duration(seconds: 1));
      countdown--;
      if (countdown == 0) {
        isGameStarted = true;
      }
    }
    countdownNotifier.value = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isGameStarted) return;

    final currentPlayer = players[playerId];
    if (currentPlayer != null) {
      // Kamera takibi
      camera.follow(currentPlayer);

      // Pozisyon güncelleme
      final now = DateTime.now();
      if (now.difference(_lastUpdate) >= updateThreshold) {
        _updatePlayerPosition(currentPlayer);
        _lastUpdate = now;
      }
    }
  }

  void _updatePlayerPosition(Player player) {
    gameRef.child('players/$playerId/position').set({
      'x': player.position.x,
      'y': player.position.y,
    });
  }

  void jump() {
    if (!isGameStarted) return;
    players[playerId]?.jump();
  }
}
