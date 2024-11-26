import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Platform extends PositionComponent {
  final Paint _paint;

  Platform({
    required Vector2 position,
    required Vector2 size,
  }) : _paint = Paint()
    ..color = Colors.grey.shade800,
    super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }
}