import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tons das superfícies coloridas (gradiente + halo da própria cor).
enum FinTone { primary, coral, green }

/// Paleta do FinUp KOI · Fusão.
///
/// Os valores vêm 1:1 das coleções de variáveis "FinUp Claro" e
/// "FinUp Escuro" do Figma. Acesse com `context.fin`.
@immutable
class FinColors extends ThemeExtension<FinColors> {
  final bool isDark;
  final Color bg, surface, inset, outlineVar, outline;
  final Color text, textVar, primary, onPrimary;
  final Color income, expense, done;
  final Color shadowDark, shadowLight;
  final Color invSurface, onInvSurface, invPrimary, scrim;

  /// Gradientes: luz vindo do canto superior esquerdo.
  final List<Color> gPrimary, gCoral, gGreen, gConvex, gConcave;

  const FinColors({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.inset,
    required this.outlineVar,
    required this.outline,
    required this.text,
    required this.textVar,
    required this.primary,
    required this.onPrimary,
    required this.income,
    required this.expense,
    required this.done,
    required this.shadowDark,
    required this.shadowLight,
    required this.invSurface,
    required this.onInvSurface,
    required this.invPrimary,
    required this.scrim,
    required this.gPrimary,
    required this.gCoral,
    required this.gGreen,
    required this.gConvex,
    required this.gConcave,
  });

  static const light = FinColors(
    isDark: false,
    bg: Color(0xffE3EBF6),
    surface: Color(0xffF4F8FD),
    inset: Color(0xffD9E3F0),
    outlineVar: Color(0xffCBD5E1),
    outline: Color(0xff94A3B8),
    text: Color(0xff1E293B),
    textVar: Color(0xff55657D),
    primary: Color(0xff2F6FE4),
    onPrimary: Color(0xffFFFFFF),
    income: Color(0xff1F5FD1),
    expense: Color(0xffB5583A),
    done: Color(0xff15803D),
    shadowDark: Color(0xffA7B6CD),
    shadowLight: Color(0xffFFFFFF),
    invSurface: Color(0xff1E293B),
    onInvSurface: Color(0xffF1F4FA),
    invPrimary: Color(0xff9FBDFF),
    scrim: Color(0xff0B1220),
    gPrimary: [Color(0xff6EA8F8), Color(0xff3478EE), Color(0xff1A45C4)],
    gCoral: [Color(0xffF7A68B), Color(0xffE3785A), Color(0xffC05A3E)],
    gGreen: [Color(0xff86EFAC), Color(0xff22C55E), Color(0xff15803D)],
    gConvex: [Color(0xffFAFCFF), Color(0xffDAE4F1)],
    gConcave: [Color(0xffD3DDEB), Color(0xffF7FAFE)],
  );

  static const dark = FinColors(
    isDark: true,
    bg: Color(0xff151D2E),
    surface: Color(0xff1C273C),
    inset: Color(0xff111827),
    outlineVar: Color(0xff2A3650),
    outline: Color(0xff6F7C98),
    text: Color(0xffE8EDF7),
    textVar: Color(0xffA9B4C9),
    primary: Color(0xff8FB0FF),
    onPrimary: Color(0xffFFFFFF),
    income: Color(0xff8DB8FF),
    expense: Color(0xffFFB199),
    done: Color(0xff6EE7A0),
    shadowDark: Color(0xff05080F),
    shadowLight: Color(0xff2B3B5E),
    invSurface: Color(0xffE3E8F3),
    onInvSurface: Color(0xff1B2336),
    invPrimary: Color(0xff2F6FE4),
    scrim: Color(0xff000000),
    gPrimary: [Color(0xff6F9EF2), Color(0xff2F64D6), Color(0xff17389A)],
    gCoral: [Color(0xffEE9F84), Color(0xffD06E52), Color(0xffA84F36)],
    gGreen: [Color(0xff6ED897), Color(0xff1FA24F), Color(0xff12673A)],
    gConvex: [Color(0xff27334F), Color(0xff161F32)],
    gConcave: [Color(0xff10172A), Color(0xff222D46)],
  );

  List<Color> tone(FinTone t) => switch (t) {
        FinTone.primary => gPrimary,
        FinTone.coral => gCoral,
        FinTone.green => gGreen,
      };

  /// Cor do halo de cada tom (mesma nos dois temas).
  static Color glowOf(FinTone t) => switch (t) {
        FinTone.primary => const Color(0xff3B82F6),
        FinTone.coral => const Color(0xffF08A6C),
        FinTone.green => const Color(0xff22C55E),
      };

  @override
  FinColors copyWith() => this;

  @override
  FinColors lerp(ThemeExtension<FinColors>? other, double t) {
    if (other is! FinColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension FinContext on BuildContext {
  FinColors get fin => Theme.of(this).extension<FinColors>()!;
}

/// Escala tipográfica Material 3 em Roboto (estilos "FinUp/…" do Figma).
class FinType {
  FinType._();

  static TextStyle _s(double size, double lh, FontWeight w, double ls) =>
      GoogleFonts.roboto(
        fontSize: size,
        height: lh / size,
        fontWeight: w,
        letterSpacing: ls,
      );

  static final displayS = _s(36, 44, FontWeight.w700, -0.8);
  static final headlineL = _s(32, 40, FontWeight.w500, -0.4);
  static final headlineS = _s(24, 32, FontWeight.w500, -0.2);
  static final titleL = _s(22, 28, FontWeight.w500, 0);
  static final titleM = _s(16, 24, FontWeight.w500, 0.1);
  static final titleS = _s(14, 20, FontWeight.w500, 0.1);
  static final bodyL = _s(16, 24, FontWeight.w400, 0.2);
  static final bodyM = _s(14, 20, FontWeight.w400, 0.2);
  static final bodyS = _s(12, 16, FontWeight.w400, 0.3);
  static final labelL = _s(14, 20, FontWeight.w500, 0.1);
  static final labelM = _s(12, 16, FontWeight.w500, 0.4);
  static final labelS = _s(11, 16, FontWeight.w500, 0.4);
}

/// Efeitos de relevo. Luz no canto superior esquerdo:
/// sombra escura (+d,+d), realce claro (−d,−d) e linha de contato.
class FinFx {
  FinFx._();

  static BoxShadow _ds(Color c, double a, double x, double y, double blur,
          [double spread = 0]) =>
      BoxShadow(
        color: c.withValues(alpha: a.clamp(0.0, 1.0)),
        offset: Offset(x, y),
        blurRadius: blur,
        spreadRadius: spread,
      );

  static List<BoxShadow> raised(FinColors c, double d) => c.isDark
      ? [
          _ds(Colors.black, 0.55, d, d, d * 2.2),
          _ds(c.shadowLight, 0.55, -d * 0.7, -d * 0.7, d * 1.8),
          _ds(Colors.black, 0.35, 0, d * 0.35, d * 0.6, -d * 0.2),
        ]
      : [
          _ds(c.shadowDark, 0.6, d, d, d * 2.2),
          _ds(Colors.white, 0.95, -d * 0.85, -d * 0.85, d * 2),
          _ds(c.shadowDark, 0.3, 0, d * 0.35, d * 0.6, -d * 0.2),
        ];

  /// Halo da própria cor para superfícies coloridas.
  static List<BoxShadow> glow(FinColors c, Color col, double d) => c.isDark
      ? [
          _ds(col, 0.4, 0, d, d * 2.4, -d * 0.35),
          _ds(Colors.black, 0.5, d * 0.5, d * 0.6, d * 2),
        ]
      : [
          _ds(col, 0.45, 0, d, d * 2.4, -d * 0.35),
          _ds(c.shadowDark, 0.45, d * 0.5, d * 0.6, d * 2),
          _ds(Colors.white, 0.85, -d * 0.6, -d * 0.6, d * 1.6),
        ];

  /// Sombras internas das superfícies côncavas.
  static List<BoxShadow> inset(FinColors c, double d) => c.isDark
      ? [
          _ds(Colors.black, 0.7, d, d, d * 1.8),
          _ds(c.shadowLight, 0.45, -d * 0.9, -d * 0.9, d * 1.6),
        ]
      : [
          _ds(c.shadowDark, 0.75, d, d, d * 1.8),
          _ds(Colors.white, 0.9, -d * 0.9, -d * 0.9, d * 1.6),
        ];

  /// Bisel da borda (branco em cima/esquerda, escuro embaixo/direita).
  static LinearGradient bevel(FinColors c, [double o = 1]) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, 0.5, 1],
        colors: c.isDark
            ? [
                Colors.white.withValues(alpha: 0.14 * o),
                Colors.white.withValues(alpha: 0.03 * o),
                Colors.black.withValues(alpha: 0.5 * o),
              ]
            : [
                Colors.white.withValues(alpha: 0.95 * o),
                Colors.white.withValues(alpha: 0.2 * o),
                c.shadowDark.withValues(alpha: 0.45 * o),
              ],
      );

  /// Verniz no topo das superfícies.
  static LinearGradient gloss(double a, [double end = 0.45]) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, end, 1],
        colors: [
          Colors.white.withValues(alpha: a),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
        ],
      );

  static LinearGradient diag(List<Color> cols) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: cols,
        stops: cols.length == 3 ? const [0, 0.45, 1] : null,
      );

  /// Sombra de texto sobre superfícies coloridas.
  static List<Shadow> textOnColor(double a) => [
        Shadow(
          color: const Color(0xff0A1F55).withValues(alpha: a),
          offset: const Offset(0, 1.5),
          blurRadius: 3,
        ),
      ];

  /// Texto "gravado" (realce branco embaixo) — só no tema claro.
  static List<Shadow>? emboss(FinColors c) => c.isDark
      ? null
      : [
          Shadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(0, 1),
          ),
        ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(FinColors.light, Brightness.light);
  static ThemeData get dark => _build(FinColors.dark, Brightness.dark);

  static ThemeData _build(FinColors c, Brightness b) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: b,
        primary: c.primary,
        surface: c.surface,
        onSurface: c.text,
        error: c.expense,
      ),
      splashFactory: InkRipple.splashFactory,
      extensions: [c],
    );
    return base.copyWith(
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme).apply(
        bodyColor: c.text,
        displayColor: c.text,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.3),
        selectionHandleColor: c.primary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        headerBackgroundColor: c.primary,
        headerForegroundColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: c.text,
      ),
    );
  }
}
