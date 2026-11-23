import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/categorias.dart';
import '../core/neu.dart';

enum _Kind { convex, pressed, colored }

/// Superfície em relevo do FinUp (Figma: Convexa, Côncava, Colorida).
///
/// - [FinSurface.convex]: cards, chips, botões suaves.
/// - [FinSurface.pressed]: campos, trilhos, valor do formulário.
/// - [FinSurface.colored]: saldo, botões principais, FAB — com halo.
class FinSurface extends StatefulWidget {
  final _Kind _kind;
  final FinTone tone;
  final double depth;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Alignment? alignment;
  final Color? border;

  const FinSurface.convex({
    super.key,
    this.depth = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.padding,
    this.width,
    this.height,
    this.child,
    this.onTap,
    this.onLongPress,
    this.alignment,
  })  : _kind = _Kind.convex,
        tone = FinTone.primary,
        border = null;

  const FinSurface.pressed({
    super.key,
    this.depth = 4.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.width,
    this.height,
    this.child,
    this.onTap,
    this.onLongPress,
    this.alignment,
    this.border,
  })  : _kind = _Kind.pressed,
        tone = FinTone.primary;

  const FinSurface.colored({
    super.key,
    this.tone = FinTone.primary,
    this.depth = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.padding,
    this.width,
    this.height,
    this.child,
    this.onTap,
    this.onLongPress,
    this.alignment,
  })  : _kind = _Kind.colored,
        border = null;

  @override
  State<FinSurface> createState() => _FinSurfaceState();
}

class _FinSurfaceState extends State<FinSurface> {
  bool _down = false;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final w = widget;
    final r = w.borderRadius;

    late final Gradient base;
    late final List<BoxShadow> shadows;
    Gradient? gloss;
    double noise;
    Gradient? bevel;
    List<BoxShadow>? inner;

    switch (w._kind) {
      case _Kind.convex:
        base = FinFx.diag(c.gConvex);
        gloss = FinFx.gloss(c.isDark ? 0.06 : 0.7, 0.42);
        noise = c.isDark ? 0.25 : 0.35;
        bevel = FinFx.bevel(c);
        shadows = FinFx.raised(c, _down ? w.depth * 0.35 : w.depth);
      case _Kind.pressed:
        base = FinFx.diag(c.gConcave);
        noise = c.isDark ? 0.2 : 0.3;
        inner = FinFx.inset(c, w.depth);
        shadows = c.isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.85),
                  offset: const Offset(0, 1.5),
                  blurRadius: 2,
                ),
              ];
      case _Kind.colored:
        base = FinFx.diag(c.tone(w.tone));
        gloss = FinFx.gloss(0.24, 0.45);
        noise = 0.45;
        bevel = FinFx.bevel(c, 0.55);
        shadows = FinFx.glow(
          c,
          FinColors.glowOf(w.tone),
          _down ? w.depth * 0.4 : w.depth,
        );
    }

    Widget content = Padding(
      padding: w.padding ?? EdgeInsets.zero,
      child: w.child,
    );
    if (w.alignment != null) {
      content = Align(alignment: w.alignment!, child: content);
    }

    Widget box = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: w.width,
      height: w.height,
      decoration: BoxDecoration(
        gradient: base,
        borderRadius: r,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            if (gloss != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(decoration: BoxDecoration(gradient: gloss)),
                ),
              ),
            Positioned.fill(child: NeuTexture(opacity: noise)),
            if (inner != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: NeuInnerShadowPainter(borderRadius: r, shadows: inner),
                  ),
                ),
              ),
            content,
            if (bevel != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: NeuBevelPainter(borderRadius: r, gradient: bevel),
                  ),
                ),
              ),
            if (w.border != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: r,
                      border: Border.all(color: w.border!, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!_interactive) return box;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: w.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              w.onTap!();
            },
      onLongPress: w.onLongPress == null
          ? null
          : () {
              setState(() => _down = false);
              HapticFeedback.mediumImpact();
              w.onLongPress!();
            },
      child: AnimatedScale(
        scale: _down && w._kind != _Kind.pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: box,
      ),
    );
  }
}

/// Card de destaque colorido (saldo, resumos): gradiente vivo, brilhos
/// radiais à direita, sombras internas e halo.
class FinGradCard extends StatelessWidget {
  final FinTone tone;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FinGradCard({
    super.key,
    required this.tone,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final cols = c.tone(tone);
    const r = BorderRadius.all(Radius.circular(26));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cols[1], cols[2], cols[2]],
          stops: const [0, 0.6, 1],
        ),
        boxShadow: FinFx.glow(c, FinColors.glowOf(tone), 12),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: NeuTexture(opacity: 0.45)),
            // brilhos radiais no lado direito
            Positioned(right: -76, top: -90, child: _brilho(190, 0.16)),
            Positioned(right: -60, top: 70, child: _brilho(150, 0.10)),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NeuInnerShadowPainter(
                    borderRadius: r,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        offset: const Offset(0, -3),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.45),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NeuBevelPainter(
                    borderRadius: r,
                    gradient: FinFx.bevel(c, 0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _brilho(double s, double a) => IgnorePointer(
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: a),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      );
}

/// Emblema em relevo: pictograma branco sobre esfera colorida.
class Emblem extends StatelessWidget {
  final EmblemaStyle estilo;
  final double size;

  const Emblem({super.key, required this.estilo, this.size = 40});

  Emblem.categoria(String? categoria, {super.key, this.size = 40})
      : estilo = Categorias.estilo(categoria);

  Emblem.meta(String? icone, {super.key, this.size = 40})
      : estilo = MetaIcones.estilo(icone);

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final s = size;
    final circle = BorderRadius.circular(s / 2);

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: FinFx.diag([estilo.claro, estilo.escuro]),
        boxShadow: [
          BoxShadow(
            color: estilo.escuro.withValues(alpha: c.isDark ? 0.45 : 0.4),
            offset: Offset(0, s * 0.12),
            blurRadius: s * 0.3,
            spreadRadius: -s * 0.05,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: FinFx.gloss(0.45, 0.5),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: NeuInnerShadowPainter(
                borderRadius: circle,
                shadows: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.35),
                    offset: const Offset(0, 1.5),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: NeuBevelPainter(
                borderRadius: circle,
                width: 1.2,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0, 0.5, 1],
                  colors: [
                    Colors.white.withValues(alpha: 0.85),
                    Colors.white.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
          Icon(
            estilo.icon,
            size: s * 0.52,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Trilho côncavo com preenchimento em gradiente.
class FinProgress extends StatelessWidget {
  final double value;
  final FinTone tone;
  final double height;

  const FinProgress({
    super.key,
    required this.value,
    this.tone = FinTone.primary,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final h = height;
    final frac = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return FinSurface.pressed(
      height: h,
      depth: h * 0.28,
      borderRadius: BorderRadius.circular(h / 2),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: frac),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, f, _) => Container(
                width: frac <= 0 ? 0 : (w * f).clamp(h, w),
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(h / 2),
                  gradient: FinFx.diag(c.tone(tone)),
                  boxShadow: [
                    BoxShadow(
                      color: FinColors.glowOf(tone).withValues(alpha: 0.35),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(h / 2),
                  gradient: FinFx.gloss(0.4, 0.55),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Fundo das telas: cor base, brilho radial no canto superior esquerdo
/// e grão. Também ajusta os ícones da barra de status ao tema.
class FinBackground extends StatelessWidget {
  final Widget child;

  const FinBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: ColoredBox(
        color: c.bg,
        child: Stack(
          children: [
            Positioned(
              left: -330,
              top: -360,
              child: IgnorePointer(
                child: Container(
                  width: 760,
                  height: 760,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: c.isDark
                          ? [
                              const Color(0xff4A6FD6).withValues(alpha: 0.22),
                              const Color(0xff4A6FD6).withValues(alpha: 0),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0),
                            ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: NeuTexture(opacity: c.isDark ? 0.25 : 0.4)),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

/// Scaffold com o fundo do FinUp.
class FinScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool safeBottom;

  const FinScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.safeBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fin.bg,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: FinBackground(
        child: SafeArea(bottom: safeBottom, child: body),
      ),
    );
  }
}
