import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/lancamento_model.dart';
import '../services/lancamento_service.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  int _filtroSelecionado = 0;

  static const List<String> _filtros = [
    "Este mês",
    "3 meses",
    "6 meses",
    "Tudo",
  ];

  List<LancamentoModel> get _lancamentosFiltrados {
    final todos = LancamentoService.getAll();
    final agora = DateTime.now();

    switch (_filtroSelecionado) {
      case 0: // Este mês
        return todos
            .where(
              (l) => l.data.year == agora.year && l.data.month == agora.month,
            )
            .toList();
      case 1: // 3 meses
        final limite = DateTime(agora.year, agora.month - 2, 1);
        return todos.where((l) => !l.data.isBefore(limite)).toList();
      case 2: // 6 meses
        final limite = DateTime(agora.year, agora.month - 5, 1);
        return todos.where((l) => !l.data.isBefore(limite)).toList();
      default: // Tudo
        return todos;
    }
  }

  Future<void> _recarregar() async {
    try {
      await LancamentoService.carregar(force: true);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lancamentos = _lancamentosFiltrados;

    final totalEntradas = lancamentos
        .where((l) => l.isReceita)
        .fold<double>(0, (s, l) => s + l.valor);
    final totalSaidas = lancamentos
        .where((l) => !l.isReceita)
        .fold<double>(0, (s, l) => s + l.valor);

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _recarregar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Histórico",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < _filtros.length; i++) ...[
                      GestureDetector(
                        onTap: () => setState(() => _filtroSelecionado = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: _filtroSelecionado == i
                                ? AppTheme.primaryGradient
                                : AppTheme.cardLightGradient,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                _filtroSelecionado == i ? 0.4 : 0.8,
                              ),
                            ),
                            boxShadow: _filtroSelecionado == i
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue
                                          .withOpacity(0.35),
                                      offset: const Offset(0, 4),
                                      blurRadius: 10,
                                      spreadRadius: -2,
                                    ),
                                  ]
                                : AppTheme.softShadow,
                          ),
                          child: Text(
                            _filtros[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _filtroSelecionado == i
                                  ? Colors.white
                                  : AppTheme.mediumText,
                            ),
                          ),
                        ),
                      ),
                      if (i < _filtros.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Resumo do período
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardLightGradient,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _resumoItem(
                        "Entradas",
                        totalEntradas,
                        AppTheme.primaryBlue,
                        Icons.arrow_downward_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 46,
                      color: AppTheme.silverMist.withOpacity(0.5),
                    ),
                    Expanded(
                      child: _resumoItem(
                        "Saídas",
                        totalSaidas,
                        AppTheme.dangerRed,
                        Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "${lancamentos.length} ${lancamentos.length == 1 ? 'lançamento' : 'lançamentos'}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mediumText,
                ),
              ),
              const SizedBox(height: 14),

              if (lancamentos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardLightGradient,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: Colors.white.withOpacity(0.8)),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: AppTheme.coolGray,
                        size: 40,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Nenhum lançamento neste período.",
                        style: TextStyle(
                          color: AppTheme.coolGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardLightGradient,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: Colors.white.withOpacity(0.8)),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < lancamentos.length; i++) ...[
                        _itemHistorico(lancamentos[i]),
                        if (i < lancamentos.length - 1)
                          Divider(
                            height: 1,
                            indent: 20,
                            endIndent: 20,
                            color: AppTheme.silverMist.withOpacity(0.4),
                          ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumoItem(String titulo, double valor, Color cor, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cor, size: 15),
            const SizedBox(width: 5),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mediumText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "R\$ ${valor.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemHistorico(LancamentoModel l) {
    final cor = l.isReceita ? AppTheme.primaryBlue : AppTheme.dangerRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cor.withOpacity(0.12), cor.withOpacity(0.22)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor.withOpacity(0.2)),
            ),
            child: Icon(
              l.isReceita
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: cor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${l.categoria ?? 'Sem categoria'} • ${l.dataFormatada}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.coolGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${l.isReceita ? '+' : '-'} R\$ ${l.valor.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
