import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/neu.dart';

/// Campo de texto realmente "cavado" na superfície: sombra interna
/// desenhada com CustomPainter em vez de uma borda escura simulada.
class SkeuInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int maxLines;
  final void Function(String)? onChanged;

  const SkeuInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  State<SkeuInput> createState() => _SkeuInputState();
}

class _SkeuInputState extends State<SkeuInput> {
  late bool _obscured;
  final FocusNode _focus = FocusNode();
  bool _focado = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focus.addListener(() {
      if (mounted) setState(() => _focado = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(AppTheme.inputRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 9),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _focado ? AppTheme.primaryBlue : AppTheme.darkText,
              shadows: const [
                Shadow(color: Colors.white, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: br,
            boxShadow: [
              // Realce branco na borda de baixo: a "quina" do sulco.
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                offset: const Offset(-1, -1),
                blurRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.75),
                offset: const Offset(2, 3),
                blurRadius: 4,
              ),
              if (_focado)
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.28),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: br,
            child: Stack(
              children: [
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
                        shadows: neuInnerShadows(
                          depth: 4.5,
                          intensity: _focado ? 1.15 : 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: NeuTexture(opacity: 0.03)),
                TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: widget.keyboardType,
                  obscureText: _obscured,
                  validator: widget.validator,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  onChanged: widget.onChanged,
                  cursorColor: AppTheme.primaryBlue,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      color: AppTheme.coolGray,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: widget.prefixIcon,
                    suffixIcon: widget.obscureText
                        ? IconButton(
                            icon: Icon(
                              _obscured
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.coolGray,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscured = !_obscured),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
