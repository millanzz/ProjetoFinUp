import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/neu.dart';

/// Superfície neumórfica genérica — a peça de base de todo o app.
///
/// Empilha, na ordem: sombra externa → gradiente → sombra interna
/// (se afundada) → verniz → grão → bisel → conteúdo.
///
/// Exemplos:
/// ```dart
/// NeuSurface(child: Text('Card'))                       // elevado
/// NeuSurface(shape: NeuShape.pressed, child: ...)       // cavado
/// NeuSurface(gradient: AppTheme.primaryGradient,        // azul
///            glowColor: AppTheme.primaryBlue, child: ...)
/// ```
class NeuSurface extends StatelessWidget {
  final Widget? child;
  final NeuShape shape;
  final double radius;
  final double depth;
  final double intensity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  /// Sobrescreve o gradiente automático (ex.: azul do saldo).
  final Gradient? gradient;
  final Color? color;

  /// Se informado, troca a sombra neutra por um halo colorido.
  final Color? glowColor;

  final bool bevel;
  final bool texture;
  final bool gloss;
  final double textureOpacity;

  /// Sobrescreve completamente a sombra externa.
  final List<BoxShadow>? shadows;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NeuSurface({
    super.key,
    this.child,
    this.shape = NeuShape.convex,
    this.radius = AppTheme.cardRadius,
    this.depth = AppTheme.depthMd,
    this.intensity = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.gradient,
    this.color,
    this.glowColor,
    this.bevel = true,
    this.texture = true,
    this.gloss = true,
    this.textureOpacity = 0.035,
    this.shadows,
    this.onTap,
    this.onLongPress,
  });

  bool get _escuro => gradient != null || glowColor != null;

  Gradient get _fundo {
    if (gradient != null) return gradient!;
    if (color != null) {
      return LinearGradient(colors: [color!, color!]);
    }
    switch (shape) {
      case NeuShape.convex:
        return AppTheme.convexGradient;
      case NeuShape.concave:
      case NeuShape.pressed:
        return AppTheme.concaveGradient;
      case NeuShape.flat:
        return const LinearGradient(
          colors: [AppTheme.surface, AppTheme.surface],
        );
    }
  }

  List<BoxShadow> get _sombraExterna {
    if (shadows != null) return shadows!;
    if (glowColor != null) return AppTheme.glow(glowColor!, depth: depth);
    if (shape == NeuShape.pressed) {
      return AppTheme.neuPressed(depth: depth);
    }
    return AppTheme.neuRaised(depth: depth, intensity: intensity);
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    Widget conteudo = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: _fundo)),
        ),

        // Sombra interna real — só faz sentido em superfícies cavadas.
        if (shape == NeuShape.pressed)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: NeuInnerShadowPainter(
                  borderRadius: br,
                  shadows: neuInnerShadows(
                    depth: depth * 0.7,
                    intensity: intensity,
                  ),
                ),
              ),
            ),
          ),

        // Verniz superior (vidro).
        if (gloss && shape != NeuShape.pressed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: (height ?? 160) * 0.42,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(_escuro ? 0.30 : 0.70),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Grão.
        if (texture)
          Positioned.fill(
            child: NeuTexture(
              opacity: (_escuro ? textureOpacity * 1.6 : textureOpacity)
                  .clamp(0.0, 1.0),
            ),
          ),

        // Bisel.
        if (bevel)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: NeuBevelPainter(
                  borderRadius: br,
                  width: 1.4,
                  opacity: _escuro ? 0.55 : 1.0,
                ),
              ),
            ),
          ),

        if (child != null)
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
      ],
    );

    Widget resultado = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: _sombraExterna,
      ),
      child: ClipRRect(borderRadius: br, child: conteudo),
    );

    if (onTap != null || onLongPress != null) {
      resultado = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: resultado,
      );
    }

    return resultado;
  }
}
