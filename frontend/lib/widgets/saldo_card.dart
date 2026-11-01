import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/neu.dart';

/// Card principal de saldo: gradiente azul com halo colorido,
/// verniz de vidro, grão e número em alto-relevo.
class SaldoCard extends StatelessWidget {
  final double saldo;

  const SaldoCard({super.key, required this.saldo});

  @override
  Widget build(BuildContext context) {
    final negativo = saldo < 0;
    final accent = negativo ? AppTheme.dangerRed : AppTheme.primaryBlue;
    final br = BorderRadius.circular(AppTheme.cardRadius);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: AppTheme.glow(accent, depth: AppTheme.depthLg),
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: negativo
                      ? AppTheme.dangerGradient
                      : AppTheme.primaryGradient,
                ),
              ),
            ),

            // Círculos decorativos — dão profundidade ao fundo.
            Positioned(
              right: -34,
              bottom: -46,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.16),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -50,
              top: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Verniz superior.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 88,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.34),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Sombra interna suave nas bordas: dá espessura ao cartão.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NeuInnerShadowPainter(
                    borderRadius: br,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.22),
                        offset: const Offset(0, -3),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.45),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Positioned.fill(child: NeuTexture(opacity: 0.055)),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NeuBevelPainter(
                    borderRadius: br,
                    width: 1.6,
                    opacity: 0.6,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Selo do ícone, também em relevo.
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.32),
                              Colors.white.withOpacity(0.12),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.40),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Text(
                        "Saldo atual",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(
                              color: Color(0x44000000),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "R\$ ${saldo.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                        Shadow(
                          color: Color(0x33ffffff),
                          offset: Offset(0, -1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
