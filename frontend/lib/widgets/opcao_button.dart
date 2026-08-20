import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Botão quadrado de ação rápida (ícone + label), com press state.
/// Dimensões pensadas para evitar overflow do conteúdo em camadas.
class OpcaoButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color cor;
  final VoidCallback? onTap;

  const OpcaoButton({
    super.key,
    required this.icon,
    required this.label,
    required this.cor,
    this.onTap,
  });

  @override
  State<OpcaoButton> createState() => _OpcaoButtonState();
}

class _OpcaoButtonState extends State<OpcaoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 96,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.cardLightGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            width: 1,
          ),
          boxShadow: _pressed ? AppTheme.softShadow : AppTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.cor.withOpacity(0.85),
                    widget.cor,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.cor.withOpacity(0.35),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
