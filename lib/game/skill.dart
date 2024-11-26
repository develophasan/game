import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';

enum SkillType {
  freeze, // Dondurma
  pull, // Geri çekme
  block, // Engel bırakma
  speed // Hızlanma
}

class Skill extends PositionComponent {
  final SkillType type;
  late final Paint _paint;

  Skill({
    required Vector2 position,
    required this.type,
  }) : super(position: position, size: Vector2.all(30)) {
    _paint = Paint()
      ..color = _getColorForType(type)
      ..style = PaintingStyle.fill;
  }

  Color _getColorForType(SkillType type) {
    switch (type) {
      case SkillType.freeze:
        return Colors.lightBlue;
      case SkillType.pull:
        return Colors.purple;
      case SkillType.block:
        return Colors.orange;
      case SkillType.speed:
        return Colors.green;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      _paint,
    );
  }

  bool checkCollision(Player player) {
    return player.toRect().overlaps(toRect());
  }
}
