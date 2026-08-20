import 'package:flutter/material.dart';
import '../core/app_theme.dart';

enum SkeuButtonVariant { primary, secondary, danger, success }

/// Botão skeuomórfico com gradiente, brilho superior
/// e estado de pressionado animado. Suporta estado de loading.
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
    this.height = 56,
    this.loading = false,
  });

  @override
  State<SkeuButton> createState() => _SkeuButtonState();
}

class _SkeuButtonState extends State<SkeuButton> {
  bool _pressed = false;

  LinearGradient get _gradient {
    switch (widget.variant) {
      case SkeuButtonVariant.primary:
        return AppTheme.primaryGradient;
      case SkeuButtonVariant.danger:
        return AppTheme.dangerGradient;
      case SkeuButtonVariant.success:
        return AppTheme.successGradient;
      case SkeuButtonVariant.secondary:
        return AppTheme.cardLightGradient;
    }
  }

  Color get _shadowColor {
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

  Color get _textColor => widget.variant == SkeuButtonVariant.secondary
      ? AppTheme.darkText
      : Colors.white;

  bool get _habilitado => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _habilitado ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _habilitado ? (_) => setState(() => _pressed = false) : null,
      onTapCancel:
          _habilitado ? () => setState(() => _pressed = false) : null,
      onTap: _habilitado ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: widget.height,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(
              widget.variant == SkeuButtonVariant.secondary ? 0.8 : 0.3,
            ),
            width: 1,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: _shadowColor.withOpacity(0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ]
              : [
                  BoxShadow(
                    color: _shadowColor.withOpacity(0.4),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Brilho superior
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: widget.height * 0.45,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: widget.loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _textColor,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: _textColor, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
