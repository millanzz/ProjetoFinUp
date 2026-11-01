import 'package:flutter/material.dart';

/// Tema skeuomórfico/neumórfico do FinUp KOI.
///
/// Regra de ouro do relevo: a luz vem do **canto superior esquerdo**.
/// Portanto todo elemento elevado tem DUAS sombras:
///   • clara (branca) deslocada para cima/esquerda  → (-d, -d)
///   • escura (azul-acinzentada) para baixo/direita → ( d,  d)
///
/// Todos os nomes antigos foram mantidos para não quebrar as telas já
/// existentes — apenas os valores foram recalibrados.
class AppTheme {
  AppTheme._();

  // ── Paleta base ────────────────────────────────────────────────
  // O fundo NÃO pode ser branco puro: sem um cinza-azulado de base o
  // realce branco não aparece e o relevo "some".
  static const Color background = Color(0xffe3ebf6);
  static const Color surface = Color(0xffe9f0f9);
  static const Color surfaceHigh = Color(0xfff6f9fd);
  static const Color surfaceLow = Color(0xffd5e0ef);
  static const Color pureWhite = Color(0xffffffff);

  static const Color primaryBlue = Color(0xff3b82f6);
  static const Color skyBlue = Color(0xff60a5fa);
  static const Color deepBlue = Color(0xff1d4ed8);
  static const Color iceBlue = Color(0xffe0ecff);

  static const Color silverMist = Color(0xffcbd5e1);
  static const Color coolGray = Color(0xff94a3b8);

  static const Color darkText = Color(0xff1e293b);
  static const Color mediumText = Color(0xff64748b);

  static const Color dangerRed = Color(0xffef4444);
  static const Color successGreen = Color(0xff22c55e);
  static const Color warningYellow = Color(0xfffbbf24);

  /// Cor da sombra projetada. Não é preto: é o fundo escurecido e
  /// dessaturado, o que mantém a sombra "limpa" sobre azul-claro.
  static const Color shadowDark = Color(0xffa7b6cd);
  static const Color shadowLight = Color(0xffffffff);

  // ── Medidas ────────────────────────────────────────────────────
  static const double cardRadius = 26;
  static const double buttonRadius = 18;
  static const double inputRadius = 16;

  /// Profundidade padrão do relevo (em px de deslocamento).
  static const double depthSm = 4;
  static const double depthMd = 8;
  static const double depthLg = 12;

  // ── Gradientes ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff7cb6ff), Color(0xff3b82f6), Color(0xff1a45c4)],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffffa5a5), Color(0xffef4444), Color(0xffb91c1c)],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff86efac), Color(0xff22c55e), Color(0xff15803d)],
    stops: [0.0, 0.45, 1.0],
  );

  /// Gradiente claro dos cards — agora com amplitude maior
  /// (antes ia de #fff a #f1f5f9, quase invisível).
  static const LinearGradient cardLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xfff8fbff), Color(0xffdbe5f2)],
  );

  /// Superfície estufada (parece que "sai" da tela).
  static const LinearGradient convexGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xfffafcff), Color(0xffdae4f1)],
  );

  /// Superfície afundada (parece uma "cuia").
  static const LinearGradient concaveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffd9e3f0), Color(0xfffafcff)],
  );

  /// Verniz aplicado sobre o topo das superfícies (efeito de vidro).
  static LinearGradient get glossGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      );

  /// Bisel da borda: branco em cima/esquerda, escuro embaixo/direita.
  static LinearGradient get bevelGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.25),
          shadowDark.withOpacity(0.35),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  // ── Sombras ────────────────────────────────────────────────────

  /// Trava a opacidade em 0–1. `Color.withOpacity` tem assert e explode
  /// em runtime se receber valor fora da faixa (ex.: 0.95 * intensity
  /// com intensity = 1.15).
  static double _op(double v) => v.clamp(0.0, 1.0);

  /// Relevo elevado padrão. [depth] controla o quanto o elemento
  /// "sobe" da tela; [intensity] controla o contraste da sombra.
  static List<BoxShadow> neuRaised({
    double depth = depthMd,
    double intensity = 1.0,
  }) =>
      [
        BoxShadow(
          color: shadowDark.withOpacity(_op(0.60 * intensity)),
          offset: Offset(depth, depth),
          blurRadius: depth * 2.2,
        ),
        BoxShadow(
          color: shadowLight.withOpacity(_op(0.95 * intensity)),
          offset: Offset(-depth * 0.85, -depth * 0.85),
          blurRadius: depth * 2.0,
        ),
        // Contato: linha fina e escura logo abaixo do objeto. É o que
        // faz o olho acreditar que ele está apoiado sobre a tela.
        BoxShadow(
          color: shadowDark.withOpacity(_op(0.30 * intensity)),
          offset: Offset(0, depth * 0.35),
          blurRadius: depth * 0.6,
          spreadRadius: -depth * 0.2,
        ),
      ];

  /// Sombra externa reduzida para o estado pressionado.
  static List<BoxShadow> neuPressed({double depth = depthMd}) => [
        BoxShadow(
          color: shadowDark.withOpacity(0.35),
          offset: Offset(depth * 0.2, depth * 0.2),
          blurRadius: depth * 0.6,
        ),
      ];

  /// Elemento flutuando bem acima da tela (FAB, modais).
  static List<BoxShadow> get neuFloating => [
        BoxShadow(
          color: shadowDark.withOpacity(0.70),
          offset: const Offset(14, 18),
          blurRadius: 34,
          spreadRadius: -6,
        ),
        BoxShadow(
          color: shadowLight.withOpacity(0.95),
          offset: const Offset(-10, -10),
          blurRadius: 24,
        ),
      ];

  /// Halo colorido para superfícies com gradiente (azul, vermelho…).
  static List<BoxShadow> glow(Color color, {double depth = depthLg}) => [
        BoxShadow(
          color: color.withOpacity(0.45),
          offset: Offset(0, depth),
          blurRadius: depth * 2.4,
          spreadRadius: -depth * 0.35,
        ),
        BoxShadow(
          color: shadowDark.withOpacity(0.45),
          offset: Offset(depth * 0.5, depth * 0.6),
          blurRadius: depth * 2.0,
        ),
        BoxShadow(
          color: shadowLight.withOpacity(0.85),
          offset: Offset(-depth * 0.6, -depth * 0.6),
          blurRadius: depth * 1.6,
        ),
      ];

  // ── Aliases legados (mantidos para não quebrar telas antigas) ───
  static List<BoxShadow> get softShadow => neuRaised(depth: depthSm);
  static List<BoxShadow> get elevatedShadow => neuRaised(depth: depthMd);
  static List<BoxShadow> get blueShadow => glow(primaryBlue, depth: depthMd);
  static List<BoxShadow> get insetShadow => neuPressed();

  // ── ThemeData ──────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          surface: background,
        ),
        splashFactory: InkRipple.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: darkText,
        ),
      );
}
