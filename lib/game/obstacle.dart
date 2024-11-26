import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';

class Obstacle extends PositionComponent {
  final Paint _paint = Paint()..color = Colors.red;

  Obstacle({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }

  bool checkCollision(Player player) {
    return player.toRect().overlaps(toRect());
  }
}