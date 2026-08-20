import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'skeu_card.dart';

/// Gráfico de pizza: distribuição entre entradas e saídas do mês.
class GraficoPizza extends StatelessWidget {
  final double entrada;
  final double saida;

  const GraficoPizza({
    super.key,
    required this.entrada,
    required this.saida,
  });

  @override
  Widget build(BuildContext context) {
    final total = entrada + saida;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SkeuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Distribuição do mês",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 16),
            if (total <= 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "Sem lançamentos ainda",
                    style: TextStyle(
                      color: AppTheme.coolGray,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 170,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 42,
                    sections: [
                      PieChartSectionData(
                        value: entrada,
                        color: AppTheme.primaryBlue,
                        radius: 42,
                        title:
                            "${(entrada / total * 100).toStringAsFixed(0)}%",
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      PieChartSectionData(
                        value: saida,
                        color: AppTheme.dangerRed,
                        radius: 42,
                        title:
                            "${(saida / total * 100).toStringAsFixed(0)}%",
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legenda(AppTheme.primaryBlue, "Entradas"),
                  const SizedBox(width: 24),
                  _legenda(AppTheme.dangerRed, "Saídas"),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _legenda(Color cor, String texto) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: cor.withOpacity(0.4),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.mediumText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
