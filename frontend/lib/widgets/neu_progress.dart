import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/neu.dart';

/// Barra de progresso com trilho cavado na tela e preenchimento
/// estufado por cima — usada em metas e resumos.
class NeuProgress extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final double height;
  final Gradient? gradient;
  final Color? accent;

  const NeuProgress({
    super.key,
    required this.value,
    this.height = 14,
    this.gradient,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final br = BorderRadius.circular(height);
    final cor = accent ?? AppTheme.primaryBlue;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.85),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            // Trilho.
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppTheme.concaveGradient,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NeuInnerShadowPainter(
                    borderRadius: br,
                    shadows: neuInnerShadows(depth: height * 0.28),
                  ),
                ),
              ),
            ),

            // Preenchimento.
            FractionallySizedBox(
              widthFactor: v == 0 ? 0.001 : v,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: br,
                  gradient: gradient ??
                      LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(cor, Colors.white, 0.45)!,
                          cor,
                          Color.lerp(cor, Colors.black, 0.22)!,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                  boxShadow: [
                    BoxShadow(
                      color: cor.withOpacity(0.55),
                      blurRadius: 8,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.42,
                    widthFactor: 1,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: height * 0.25),
                      decoration: BoxDecoration(
                        borderRadius: br,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.55),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Positioned.fill(child: NeuTexture(opacity: 0.04)),
          ],
        ),
      ),
    );
  }
}
