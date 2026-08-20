import 'package:flutter/material.dart';

/// Tema skeuomórfico do app: paleta azul/branco, gradientes em camadas,
/// sombras suaves e elevadas.
class AppTheme {
  AppTheme._();

  // ── Paleta ─────────────────────────────────────────────────────
  static const Color background = Color(0xffeef2f7);
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

  // ── Medidas ────────────────────────────────────────────────────
  static const double cardRadius = 24;

  // ── Gradientes ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [skyBlue, deepBlue],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xfff87171), Color(0xffdc2626)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff4ade80), Color(0xff16a34a)],
  );

  /// Gradiente claro dos cards (branco -> cinza gelo)
  static const LinearGradient cardLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffffffff), Color(0xfff1f5f9)],
  );

  // ── Sombras ────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: deepBlue.withOpacity(0.06),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.9),
          offset: const Offset(-2, -2),
          blurRadius: 6,
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: deepBlue.withOpacity(0.10),
          offset: const Offset(0, 10),
          blurRadius: 24,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.8),
          offset: const Offset(-2, -2),
          blurRadius: 8,
        ),
      ];

  static List<BoxShadow> get blueShadow => [
        BoxShadow(
          color: primaryBlue.withOpacity(0.35),
          offset: const Offset(0, 6),
          blurRadius: 14,
          spreadRadius: -2,
        ),
      ];

  /// Sombra "afundada" para inputs (efeito inset simulado)
  static List<BoxShadow> get insetShadow => [
        BoxShadow(
          color: silverMist.withOpacity(0.5),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ];

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
