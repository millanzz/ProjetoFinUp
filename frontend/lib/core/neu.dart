import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
// 1. Sombra interna real
// ═══════════════════════════════════════════════════════════════════

/// Pinta sombras internas dentro de um retângulo arredondado.
///
/// O Flutter não tem `inset box-shadow` nativo: desenhamos um "buraco"
/// (retângulo gigante MENOS a forma deslocada) com blur, recortado pela
/// própria forma.
class NeuInnerShadowPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  const NeuInnerShadowPainter({
    required this.borderRadius,
    required this.shadows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.saveLayer(rect, Paint());
    canvas.clipRRect(rrect);

    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          shadow.blurRadius <= 0 ? 0.01 : shadow.blurRadius * 0.57,
        );

      // Retângulo grande com um "furo" na forma deslocada (evenOdd).
      final hole = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(size.longestSide))
        ..addRRect(rrect.shift(shadow.offset).deflate(shadow.spreadRadius));

      canvas.drawPath(hole, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(NeuInnerShadowPainter old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}

// ═══════════════════════════════════════════════════════════════════
// 2. Bisel / contorno em gradiente
// ═══════════════════════════════════════════════════════════════════

class NeuBevelPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Gradient gradient;
  final double width;

  const NeuBevelPainter({
    required this.borderRadius,
    required this.gradient,
    this.width = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(width / 2);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(NeuBevelPainter old) =>
      old.borderRadius != borderRadius ||
      old.gradient != gradient ||
      old.width != width;
}

// ═══════════════════════════════════════════════════════════════════
// 3. Textura de grão
// ═══════════════════════════════════════════════════════════════════

/// Gera (uma única vez) uma imagem de ruído 128x128 usada como textura.
class NeuNoise {
  NeuNoise._();

  static ui.Image? _image;
  static Future<ui.Image>? _pending;

  static ui.Image? get image => _image;

  static Future<ui.Image> load() {
    if (_image != null) return Future.value(_image);
    return _pending ??= _generate().then((img) {
      _image = img;
      _pending = null;
      return img;
    });
  }

  static Future<ui.Image> _generate() {
    const int side = 128;
    final rnd = Random(2024);
    final pixels = Uint8List(side * side * 4);

    for (var i = 0; i < side * side; i++) {
      final v = 96 + rnd.nextInt(64);
      final o = i * 4;
      pixels[o] = v;
      pixels[o + 1] = v;
      pixels[o + 2] = v;
      pixels[o + 3] = 255;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      side,
      side,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}

class _NeuNoisePainter extends CustomPainter {
  final ui.Image image;
  final double opacity;

  const _NeuNoisePainter({required this.image, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final matrix = Matrix4.identity()..scaleByDouble(0.5, 0.5, 1, 1);

    // Composto em "overlay": o grão modula a luz sem sujar a cor.
    canvas.saveLayer(
      rect,
      Paint()
        ..blendMode = BlendMode.overlay
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          matrix.storage,
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NeuNoisePainter old) =>
      old.image != image || old.opacity != opacity;
}

/// Camada de grão para sobrepor uma superfície.
/// [opacity] segue a opacidade do preenchimento de ruído no Figma.
class NeuTexture extends StatefulWidget {
  final double opacity;

  const NeuTexture({super.key, this.opacity = 0.35});

  @override
  State<NeuTexture> createState() => _NeuTextureState();
}

class _NeuTextureState extends State<NeuTexture> {
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    _img = NeuNoise.image;
    if (_img == null) {
      NeuNoise.load().then((img) {
        if (mounted) setState(() => _img = img);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _img;
    if (img == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          // Ruído em overlay com alfa reduzido: o Figma aplica a textura
          // em meia escala, o que a deixa mais suave do que o alfa sugere.
          painter: _NeuNoisePainter(image: img, opacity: widget.opacity * 0.22),
          size: Size.infinite,
        ),
      ),
    );
  }
}
