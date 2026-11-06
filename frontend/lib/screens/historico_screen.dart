import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import '../services/lancamento_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';
import '../widgets/lancamento_acoes.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  int _filtro = 0;

  static const _filtros = ['Este mês', '3 meses', '6 meses', 'Tudo'];

  List<LancamentoModel> get _filtrados {
    final todos = LancamentoService.getAll();
    final agora = DateTime.now();
    switch (_filtro) {
      case 0:
        return todos.where((l) => Fmt.mesmoMes(l.data, agora)).toList();
      case 1:
        final limite = DateTime(agora.year, agora.month - 2, 1);
        return todos.where((l) => !l.data.isBefore(limite)).toList();
      case 2:
        final limite = DateTime(agora.year, agora.month - 5, 1);
        return todos.where((l) => !l.data.isBefore(limite)).toList();
      default:
        return todos;
    }
  }

  Future<void> _recarregar() async {
    try {
      await LancamentoService.carregar(force: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LancamentoService.revisao,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = context.fin;
    final lista = _filtrados;
    final entradas = lista.where((l) => l.isReceita).fold<double>(0, (s, l) => s + l.valor);
    final saidas = lista.where((l) => !l.isReceita).fold<double>(0, (s, l) => s + l.valor);

    // Agrupa por dia (a lista já vem do mais recente para o mais antigo).
    final grupos = <DateTime, List<LancamentoModel>>{};
    for (final l in lista) {
      grupos.putIfAbsent(DateTime(l.data.year, l.data.month, l.data.day), () => []).add(l);
    }

    return FinScaffold(
      safeBottom: false,
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface,
        onRefresh: _recarregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const FinTopBar(title: 'Histórico'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (var i = 0; i < _filtros.length; i++) ...[
                    FinChip(
                      label: _filtros[i],
                      selected: _filtro == i,
                      onTap: () => setState(() => _filtro = i),
                    ),
                    if (i < _filtros.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FinSurface.convex(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Resumo(
                            label: 'Entradas',
                            valor: '+ ${Fmt.brl(entradas)}',
                            cor: c.income,
                            icon: Icons.arrow_downward,
                            tone: FinTone.primary,
                          ),
                        ),
                        Row(
                          children: [
                            Container(width: 1, height: 40, color: c.outlineVar),
                            Container(
                              width: 1,
                              height: 40,
                              color: c.isDark
                                  ? const Color(0xff2B3B5E).withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                        Expanded(
                          child: _Resumo(
                            label: 'Saídas',
                            valor: '− ${Fmt.brl(saidas)}',
                            cor: c.expense,
                            icon: Icons.arrow_upward,
                            tone: FinTone.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${lista.length} ${lista.length == 1 ? 'lançamento' : 'lançamentos'}',
                      style: FinType.titleM.copyWith(color: c.text, shadows: FinFx.emboss(c)),
                    ),
                  ),
                  if (lista.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: EmptyCard(
                        icon: Icons.history,
                        texto: 'Nenhum lançamento neste período.',
                      ),
                    )
                  else
                    for (final e in grupos.entries) ...[
                      const SizedBox(height: 10),
                      Text(
                        Fmt.diaPorExtenso(e.key),
                        style: FinType.labelL.copyWith(color: c.textVar),
                      ),
                      const SizedBox(height: 8),
                      ListCard(
                        rows: [
                          for (final l in e.value)
                            LancRow(
                              lancamento: l,
                              subtitulo: l.categoria ?? 'Sem categoria',
                              onTap: () => LancamentoAcoes.menu(context, l),
                              onLongPress: () => LancamentoAcoes.menu(context, l),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  final IconData icon;
  final FinTone tone;

  const _Resumo({
    required this.label,
    required this.valor,
    required this.cor,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 14),
      child: Row(
        children: [
          FinSurface.colored(
            tone: tone,
            width: 34,
            height: 34,
            depth: 3,
            borderRadius: BorderRadius.circular(17),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: FinType.bodyS.copyWith(color: c.textVar)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valor,
                    style: FinType.titleS.copyWith(color: cor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
