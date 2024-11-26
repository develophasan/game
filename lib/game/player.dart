import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Player extends PositionComponent {
  final String id;
  final String username;
  final bool isCurrentPlayer;

  // Hareket değişkenleri
  double baseSpeed = 200.0;
  double currentSpeed = 200.0;
  double jumpForce = -400.0;
  double gravity = 800.0;
  double verticalVelocity = 0.0;
  bool isOnGround = false;
  bool isFrozen = false;

  // Görsel öğeler
  late final Paint paint;
  late final TextComponent usernameText;

  // Platform yüksekliği
  static const platformY = 500.0; // Ekranın alt kısmına yakın sabit bir değer

  Player({
    required this.id,
    required this.username,
    required Vector2 position,
    required Vector2 size,
    required Color color,
    required this.isCurrentPlayer,
  }) : super(position: position, size: size) {
    paint = Paint()..color = color;
    usernameText = TextComponent(
      text: username,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await add(usernameText);
    // Başlangıçta karakteri platform üzerine yerleştir
    position.y = platformY - size.y;
    isOnGround = true;
  }

  @override
  void render(Canvas canvas) {
    // Karakteri daire olarak çiz
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isFrozen) return;

    // Otomatik ileri hareket
    position.x += currentSpeed * dt;

    // Yerçekimi ve zıplama
    if (!isOnGround) {
      verticalVelocity += gravity * dt;
      position.y += verticalVelocity * dt;
    }

    // Platform kontrolü
    if (position.y >= platformY - size.y) {
      position.y = platformY - size.y;
      verticalVelocity = 0;
      isOnGround = true;
    }

    // Kullanıcı adı pozisyonu güncelleme
    usernameText.position = Vector2(
      size.x / 2 - usernameText.size.x / 2,
      -25,
    );
  }

  void jump() {
    if (isOnGround && !isFrozen) {
      verticalVelocity = jumpForce;
      isOnGround = false;
    }
  }

  void setSpeedBoost(bool enabled) {
    currentSpeed = enabled ? baseSpeed * 2 : baseSpeed;
  }

  void updatePosition(Vector2 newPosition) {
    position = newPosition;
  }
}
