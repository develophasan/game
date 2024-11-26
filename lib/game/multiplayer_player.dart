import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MultiplayerPlayer extends PositionComponent {
  final String id;
  final String username;
  double speed = 200.0;
  bool isMoving = false;
  Vector2 moveDirection = Vector2.zero();
  Vector2 targetPosition;
  late final Paint paint;
  late final TextComponent usernameText;
  static const double lerpSpeed = 0.3;

  MultiplayerPlayer({
    required this.id,
    required this.username,
    required Vector2 position,
    required Vector2 size,
    required Color color,
  }) : targetPosition = position.clone(),
       super(position: position, size: size, anchor: Anchor.center) {
    paint = Paint()..color = color;
    usernameText = TextComponent(
      text: username,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
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
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      size.x / 2,
      paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isMoving) {
      position += moveDirection * speed * dt;
    }

    // Smooth movement for other players
    position = lerpVector2(position, targetPosition, lerpSpeed);

    // Update username position
    usernameText.position = Vector2(
      -usernameText.size.x / 2,
      -size.y - 20,
    );
  }

  Vector2 lerpVector2(Vector2 start, Vector2 end, double t) {
    return Vector2(
      start.x + (end.x - start.x) * t,
      start.y + (end.y - start.y) * t,
    );
  }

  void move(Vector2 direction) {
    isMoving = direction != Vector2.zero();
    if (isMoving) {
      moveDirection = direction.normalized();
    } else {
      moveDirection = Vector2.zero();
    }
  }

  void updateTargetPosition(Vector2 newPosition) {
    targetPosition = newPosition;
  }
}