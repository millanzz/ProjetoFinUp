import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Formato do relevo de uma superfície.
enum NeuShape {
  /// Superfície plana, apenas elevada.
  flat,

  /// Estufada — parece um botão que sai da tela.
  convex,

  /// Afundada como uma cuia (gradiente invertido).
  concave,

  /// Cavada na tela: sombra INTERNA de verdade (inputs, trilhos, slots).
  pressed,
}

// ═══════════════════════════════════════════════════════════════════
// 1. Sombra interna real
// ═══════════════════════════════════════════════════════════════════

/// Pinta sombras internas dentro de um retângulo arredondado.
///
/// O Flutter não tem `inset box-shadow` nativo. A técnica aqui é
/// desenhar um "buraco" (retângulo gigante MENOS a forma deslocada) e
/// borrar a borda desse buraco dentro do clip da própria forma.
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
          shadow.blurRadius <= 0 ? 0.01 : shadow.blurRadius,
        );

      final outer = Path()..addRect(rect.inflate(size.longestSide));
      final inner = Path()
        ..addRRect(
          rrect
              .shift(shadow.offset)
              .deflate(shadow.spreadRadius),
        );

      canvas.drawPath(
        Path.combine(PathOperation.difference, outer, inner),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(NeuInnerShadowPainter old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}

/// Conjunto padrão de sombras internas (luz no canto superior esquerdo).
///
/// As opacidades são travadas em 0–1: `intensity` acima de 1 estouraria
/// o assert de `Color.withOpacity` (dart:ui/painting.dart).
List<BoxShadow> neuInnerShadows({double depth = 5, double intensity = 1.0}) => [
      BoxShadow(
        color: AppTheme.shadowDark.withOpacity(
          (0.75 * intensity).clamp(0.0, 1.0),
        ),
        offset: Offset(depth, depth),
        blurRadius: depth * 1.8,
      ),
      BoxShadow(
        color: Colors.white.withOpacity(
          (0.90 * intensity).clamp(0.0, 1.0),
        ),
        offset: Offset(-depth * 0.9, -depth * 0.9),
        blurRadius: depth * 1.6,
      ),
    ];

// ═══════════════════════════════════════════════════════════════════
// 2. Bisel da borda
// ═══════════════════════════════════════════════════════════════════

/// Traça uma borda de 1–2px com gradiente: branca no topo-esquerda,
/// escura na base-direita. É o detalhe que dá a sensação de espessura.
class NeuBevelPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double width;
  final double opacity;

  const NeuBevelPainter({
    required this.borderRadius,
    this.width = 1.4,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(width / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity((0.95 * opacity).clamp(0.0, 1.0)),
          Colors.white.withOpacity((0.20 * opacity).clamp(0.0, 1.0)),
          AppTheme.shadowDark.withOpacity((0.40 * opacity).clamp(0.0, 1.0)),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(NeuBevelPainter old) =>
      old.borderRadius != borderRadius ||
      old.width != width ||
      old.opacity != opacity;
}

// ═══════════════════════════════════════════════════════════════════
// 3. Textura de grão
// ═══════════════════════════════════════════════════════════════════

/// Gera (uma única vez) uma imagem de ruído 128x128 usada como textura
/// repetida. Sem isso as superfícies ficam "plásticas" demais.
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
      final v = 118 + rnd.nextInt(74); // 118..191
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
  final double scale;

  const _NeuNoisePainter({
    required this.image,
    required this.opacity,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final matrix = Matrix4.identity()..scale(scale, scale);

    // A camada inteira e composta em "overlay" sobre o card, com alfa
    // baixo: o grao modula a luz existente em vez de sujar a cor.
    canvas.saveLayer(
      rect,
      Paint()
        ..blendMode = BlendMode.overlay
        ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
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
      old.image != image || old.opacity != opacity || old.scale != scale;
}

/// Camada de grão para sobrepor uma superfície.
/// Use opacidades baixas (0.02–0.06); acima disso vira sujeira.
class NeuTexture extends StatefulWidget {
  final double opacity;
  final double scale;

  const NeuTexture({super.key, this.opacity = 0.035, this.scale = 1.0});

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
      child: CustomPaint(
        painter: _NeuNoisePainter(
          image: img,
          opacity: widget.opacity,
          scale: widget.scale,
        ),
        size: Size.infinite,
      ),
    );
  }
}
