import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Logo do app (koi) — usado no lugar do antigo ícone de carteira.
///
/// Uso:
///   const AppLogo(size: 116)                          -> cartão claro (login)
///   const AppLogo(size: 36, sobreFundoEscuro: true)   -> sobre gradiente azul
///   const AppLogo(size: 40, comCartao: false)         -> só a imagem
class AppLogo extends StatelessWidget {
  /// Tamanho total do widget (largura = altura).
  final double size;

  /// Se `true`, desenha o "cartão" skeuomórfico atrás da imagem.
  final bool comCartao;

  /// Use `true` quando o logo ficar sobre um fundo colorido/escuro
  /// (ex.: dentro do card azul de saldo).
  final bool sobreFundoEscuro;

  const AppLogo({
    super.key,
    this.size = 116,
    this.comCartao = true,
    this.sobreFundoEscuro = false,
  });

  /// Caminho do asset — declarado aqui para não repetir a string pelo app.
  static const String assetPath = 'assets/images/logo_finup_koi.png';

  @override
  Widget build(BuildContext context) {
    final imagem = Image.asset(
      assetPath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!comCartao) {
      return SizedBox(width: size, height: size, child: imagem);
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.07),
      decoration: BoxDecoration(
        gradient: sobreFundoEscuro ? null : AppTheme.cardLightGradient,
        color: sobreFundoEscuro ? Colors.white.withOpacity(0.92) : null,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: sobreFundoEscuro
              ? Colors.white.withOpacity(0.6)
              : AppTheme.silverMist.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: sobreFundoEscuro ? null : AppTheme.blueShadow,
      ),
      child: imagem,
    );
  }
}
