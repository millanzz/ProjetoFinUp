import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../models/lancamento_model.dart';
import '../services/lancamento_service.dart';
import '../widgets/grafico_barras.dart';

/// Tela de listagem de receitas OU despesas, conforme [tipo].
class LancamentosScreen extends StatefulWidget {
  final TipoLancamento tipo;
  final String titulo;

  const LancamentosScreen({
    super.key,
    required this.tipo,
    required this.titulo,
  });

  @override
  State<LancamentosScreen> createState() => _LancamentosScreenState();
}

class _LancamentosScreenState extends State<LancamentosScreen> {
  bool get _isReceita => widget.tipo == TipoLancamento.receita;

  List<LancamentoModel> get _lancamentos => _isReceita
      ? LancamentoService.getReceitas()
      : LancamentoService.getDespesas();

  double get _total =>
      _isReceita ? LancamentoService.totalReceitas : LancamentoService.totalDespesas;

  Color get _cor => _isReceita ? AppTheme.primaryBlue : AppTheme.dangerRed;

  LinearGradient get _gradient =>
      _isReceita ? AppTheme.primaryGradient : AppTheme.dangerGradient;

  Future<void> _recarregar() async {
    try {
      await LancamentoService.carregar(force: true);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _novoLancamento() async {
    await Navigator.pushNamed(
      context,
      _isReceita ? AppRoutes.novaReceita : AppRoutes.novaDespesa,
    );
    await _recarregar();
  }

  Future<void> _confirmarExclusao(LancamentoModel lancamento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Excluir lançamento",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        content: Text(
          'Deseja excluir "${lancamento.titulo}" '
          '(R\$ ${lancamento.valor.toStringAsFixed(2)})?',
          style: const TextStyle(color: AppTheme.mediumText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: AppTheme.coolGray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Excluir",
              style: TextStyle(
                color: AppTheme.dangerRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await LancamentoService.remover(lancamento);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Lançamento excluído."),
            backgroundColor: AppTheme.darkText,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Não foi possível excluir. Tente novamente."),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lancamentos = _lancamentos;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: GestureDetector(
        onTap: _novoLancamento,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _cor.withOpacity(0.45),
                offset: const Offset(0, 8),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _cor,
          onRefresh: _recarregar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.titulo,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Resumo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: _gradient,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _cor.withOpacity(0.4),
                        offset: const Offset(0, 8),
                        blurRadius: 20,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isReceita ? "Total de entradas" : "Total de saídas",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "R\$ ${_total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${lancamentos.length} ${lancamentos.length == 1 ? 'item' : 'itens'}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Lista
                const Text(
                  "Lançamentos",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 14),
                if (lancamentos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardLightGradient,
                      borderRadius:
                          BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isReceita
                              ? Icons.savings_outlined
                              : Icons.receipt_long_outlined,
                          color: AppTheme.coolGray,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isReceita
                              ? "Nenhuma receita registrada ainda.\nToque em + para adicionar."
                              : "Nenhuma despesa registrada ainda.\nToque em + para adicionar.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.coolGray,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardLightGradient,
                      borderRadius:
                          BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      boxShadow: AppTheme.elevatedShadow,
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < lancamentos.length; i++) ...[
                          _itemLancamento(lancamentos[i]),
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

                // Gráfico por categoria
                GraficoBarras(
                  titulo: _isReceita
                      ? "Receitas por categoria"
                      : "Despesas por categoria",
                  lancamentos: lancamentos,
                  corBarra: _cor,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemLancamento(LancamentoModel l) {
    return InkWell(
      onLongPress: () => _confirmarExclusao(l),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _cor.withOpacity(0.12),
                    _cor.withOpacity(0.22),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cor.withOpacity(0.2)),
              ),
              child: Icon(
                _isReceita
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: _cor,
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
                    "${l.categoria ?? 'Sem categoria'} • ${l.dataFormatada}"
                    "${l.parcelado ? ' • Parcelado' : ''}",
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
              "${_isReceita ? '+' : '-'} R\$ ${l.valor.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
