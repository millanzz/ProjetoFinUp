import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/lancamento_model.dart';
import 'skeu_card.dart';

/// Gráfico de barras por categoria.
class GraficoBarras extends StatefulWidget {
  final String titulo;
  final List<LancamentoModel> lancamentos;
  final Color corBarra;

  const GraficoBarras({
    super.key,
    required this.titulo,
    required this.lancamentos,
    this.corBarra = AppTheme.primaryBlue,
  });

  @override
  State<GraficoBarras> createState() => _GraficoBarrasState();
}

class _GraficoBarrasState extends State<GraficoBarras> {
  int _touchedIndex = -1;

  Map<String, double> get _dadosPorCategoria {
    final mapa = <String, double>{};
    for (final l in widget.lancamentos) {
      final cat = l.categoria ?? "Outros";
      mapa[cat] = (mapa[cat] ?? 0) + l.valor;
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final dados = _dadosPorCategoria;

    if (dados.isEmpty) {
      return const SizedBox.shrink();
    }

    final categorias = dados.keys.toList();
    final valores = dados.values.toList();
    final maxValor =
        valores.isEmpty ? 100.0 : valores.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SkeuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  maxY: maxValor * 1.2,
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response == null || response.spot == null) {
                          _touchedIndex = -1;
                        } else {
                          _touchedIndex =
                              response.spot!.touchedBarGroupIndex;
                        }
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.darkText,
                      getTooltipItem: (group, gIndex, rod, rIndex) {
                        return BarTooltipItem(
                          "${categorias[group.x]}\nR\$ ${rod.toY.toStringAsFixed(2)}",
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= categorias.length) {
                            return const SizedBox.shrink();
                          }
                          final nome = categorias[index];
                          final abrev = nome.length > 5
                              ? "${nome.substring(0, 5)}."
                              : nome;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              abrev,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.mediumText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.silverMist.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < categorias.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: valores[i],
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                widget.corBarra.withOpacity(
                                  _touchedIndex == i ? 1.0 : 0.7,
                                ),
                                widget.corBarra,
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
