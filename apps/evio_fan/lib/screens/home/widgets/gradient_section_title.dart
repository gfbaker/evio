import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

/// Título de sección con primary mate
/// ✅ Sin gradiente, solo primary
class GradientSectionTitle extends StatelessWidget {
  final String text;

  const GradientSectionTitle({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9), // ⚡ Blanco mate con opacidad
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}
