import 'package:flutter/material.dart';
import 'package:neuro_word/core/constants/app_colors.dart';

class NeonIconBox extends StatelessWidget {
  const NeonIconBox({
    super.key,
    required this.icon,
    this.color,
    this.size = 48,
    this.iconSize = 24,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.electricBlue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.25), width: 1),
      ),
      child: Icon(icon, color: accent, size: iconSize),
    );
  }
}
