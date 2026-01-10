import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tokens de fondos para mantener consistencia visual en toda la app
class EvioBackgrounds {
  EvioBackgrounds._();

  /// Opacidad del noise/grain
  static const double noiseOpacity = 0.06;

  /// Tamaño del patrón de noise (128x128 px)
  static const int noiseSize = 128;

  /// Genera un patrón de noise/grain para usar como textura de fondo
  /// 
  /// Este patrón se genera una sola vez y se cachea automáticamente
  /// por Flutter al usar MemoryImage
  static Uint8List generateNoisePattern() {
    final random = math.Random(42); // Seed fijo para consistencia
    final pixels = Uint8List(noiseSize * noiseSize * 4); // RGBA

    for (int i = 0; i < noiseSize * noiseSize; i++) {
      final offset = i * 4;
      final noise = random.nextInt(256);
      
      // Gris con variación (efecto grain/film)
      pixels[offset] = noise;     // R
      pixels[offset + 1] = noise; // G
      pixels[offset + 2] = noise; // B
      pixels[offset + 3] = 255;   // A (opaco, la opacidad se controla en el DecorationImage)
    }

    return pixels;
  }

  /// Decoration estándar para fondos de pantallas
  /// 
  /// Incluye:
  /// - Color de fondo base
  /// - Textura de noise/grain sutil
  static BoxDecoration screenBackground(Color backgroundColor) {
    return BoxDecoration(
      color: backgroundColor,
      image: DecorationImage(
        image: MemoryImage(generateNoisePattern()),
        repeat: ImageRepeat.repeat,
        opacity: noiseOpacity,
      ),
    );
  }
}
