import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Card compacto de resumo (entrada/saída do mês).
class ResumoCard extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color cor;

  const ResumoCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final isEntrada = cor == AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.cardLightGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cor.withOpacity(0.15), cor.withOpacity(0.25)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cor.withOpacity(0.2), width: 1),
            ),
            child: Icon(
              isEntrada
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: cor,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mediumText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "R\$ ${valor.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
