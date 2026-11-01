import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/neu.dart';

enum SkeuButtonVariant { primary, secondary, danger, success }

/// Botão neumórfico: elevado em repouso, **afundado** ao toque
/// (sombra interna real, não só um deslocamento de 2px).
class SkeuButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final SkeuButtonVariant variant;
  final double height;
  final bool loading;

  const SkeuButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = SkeuButtonVariant.primary,
    this.height = 58,
    this.loading = false,
  });

  @override
  State<SkeuButton> createState() => _SkeuButtonState();
}

class _SkeuButtonState extends State<SkeuButton> {
  bool _pressed = false;

  bool get _colorido => widget.variant != SkeuButtonVariant.secondary;

  LinearGradient get _gradient {
    switch (widget.variant) {
      case SkeuButtonVariant.primary:
        return AppTheme.primaryGradient;
      case SkeuButtonVariant.danger:
        return AppTheme.dangerGradient;
      case SkeuButtonVariant.success:
        return AppTheme.successGradient;
      case SkeuButtonVariant.secondary:
        return AppTheme.convexGradient;
    }
  }

  Color get _accent {
    switch (widget.variant) {
      case SkeuButtonVariant.primary:
        return AppTheme.primaryBlue;
      case SkeuButtonVariant.danger:
        return AppTheme.dangerRed;
      case SkeuButtonVariant.success:
        return AppTheme.successGreen;
      case SkeuButtonVariant.secondary:
        return AppTheme.silverMist;
    }
  }

  Color get _textColor => _colorido ? Colors.white : AppTheme.darkText;

  bool get _habilitado => widget.onPressed != null && !widget.loading;

  List<BoxShadow> get _sombra {
    if (!_habilitado) {
      return AppTheme.neuRaised(depth: AppTheme.depthSm, intensity: 0.5);
    }
    if (_pressed) return AppTheme.neuPressed(depth: 5);
    return _colorido
        ? AppTheme.glow(_accent, depth: AppTheme.depthMd)
        : AppTheme.neuRaised(depth: AppTheme.depthMd);
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(AppTheme.buttonRadius);

    return GestureDetector(
      onTapDown: _habilitado ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _habilitado ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _habilitado ? () => setState(() => _pressed = false) : null,
      onTap: _habilitado ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        height: widget.height,
        transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
        decoration: BoxDecoration(borderRadius: br, boxShadow: _sombra),
        child: ClipRRect(
          borderRadius: br,
          child: Opacity(
            opacity: _habilitado ? 1 : 0.55,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: _gradient),
                  ),
                ),

                // Verniz superior — encolhe quando pressionado.
                if (!_pressed)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: widget.height * 0.5,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(_colorido ? 0.35 : 0.75),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Ao pressionar, o botão realmente afunda.
                if (_pressed)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: NeuInnerShadowPainter(
                          borderRadius: br,
                          shadows: [
                            BoxShadow(
                              color: _colorido
                                  ? Colors.black.withOpacity(0.35)
                                  : AppTheme.shadowDark.withOpacity(0.8),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(
                                _colorido ? 0.25 : 0.9,
                              ),
                              offset: const Offset(-3, -3),
                              blurRadius: 7,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                Positioned.fill(
                  child: NeuTexture(opacity: _colorido ? 0.05 : 0.035),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: NeuBevelPainter(
                        borderRadius: br,
                        width: 1.4,
                        opacity: _colorido ? 0.5 : 1.0,
                      ),
                    ),
                  ),
                ),

                if (widget.loading)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(_textColor),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: _textColor, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          shadows: _colorido
                              ? [
                                  const Shadow(
                                    color: Color(0x55000000),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                              : [
                                  const Shadow(
                                    color: Colors.white,
                                    offset: Offset(0, 1),
                                    blurRadius: 0,
                                  ),
                                ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
