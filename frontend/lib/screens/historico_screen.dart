import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import '../services/consulta_lancamentos.dart';
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

  /// Filtros além de "Este mês" não estão no cache: são buscados página por
  /// página, com os totais do período inteiro calculados pela API.
  ConsultaLancamentos? _consulta;

  DateTime? _inicioDoFiltro(int filtro) {
    final agora = DateTime.now();
    switch (filtro) {
      case 1:
        return DateTime(agora.year, agora.month - 2, 1);
      case 2:
        return DateTime(agora.year, agora.month - 5, 1);
      default:
        return null;
    }
  }

  void _escolherFiltro(int i) {
    if (i == _filtro) return;
    _consulta?.dispose();
    _consulta = i == 0 ? null : ConsultaLancamentos(de: _inicioDoFiltro(i));
    setState(() => _filtro = i);
  }

  @override
  void dispose() {
    _consulta?.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    try {
      if (_consulta != null) {
        await _consulta!.recarregar();
      } else {
        await LancamentoService.carregar(force: true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LancamentoService.revisao, _consulta]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = context.fin;
    final consulta = _consulta;
    final List<LancamentoModel> lista;
    final double entradas, saidas;
    final int quantidade;
    if (consulta == null) {
      final agora = DateTime.now();
      lista = LancamentoService.getAll().where((l) => Fmt.mesmoMes(l.data, agora)).toList();
      entradas = lista.where((l) => l.isReceita).fold<double>(0, (s, l) => s + l.valor);
      saidas = lista.where((l) => !l.isReceita).fold<double>(0, (s, l) => s + l.valor);
      quantidade = lista.length;
    } else {
      lista = consulta.itens;
      entradas = consulta.receitas;
      saidas = consulta.despesas;
      quantidade = consulta.total;
    }
    final aguardando = consulta != null && !consulta.pronta;
    final falhou = consulta != null && consulta.erro != null && lista.isEmpty;
    final temMais = consulta != null && consulta.temMais;

    // Agrupa por dia (a lista já vem do mais recente para o mais antigo).
    final grupos = <DateTime, List<LancamentoModel>>{};
    for (final l in lista) {
      grupos.putIfAbsent(DateTime(l.data.year, l.data.month, l.data.day), () => []).add(l);
    }

    final dias = grupos.entries.toList();
    final cabecalho = <Widget>[
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
                onTap: () => _escolherFiltro(i),
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
                aguardando
                    ? 'Carregando…'
                    : '$quantidade ${quantidade == 1 ? 'lançamento' : 'lançamentos'}',
                style: FinType.titleM.copyWith(color: c.text, shadows: FinFx.emboss(c)),
              ),
            ),
          ],
        ),
      ),
    ];

    return FinScaffold(
      safeBottom: false,
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface,
        onRefresh: _recarregar,
        // Lista sob demanda (ListView.builder): só monta os grupos de dias que
        // aparecem na tela. Antes, com o filtro "Tudo", todos os lançamentos eram
        // montados de uma vez e a tela travava com milhares de itens (DEF-08).
        // Nos períodos longos, a próxima página só é buscada quando o fim da
        // lista aparece (CarregandoMais).
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          itemCount: cabecalho.length +
              (lista.isEmpty ? 1 : dias.length + (temMais ? 1 : 0)),
          itemBuilder: (context, i) {
            if (i < cabecalho.length) return cabecalho[i];
            if (aguardando) return const CarregandoMais();
            if (falhou) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: EmptyCard(
                  icon: Icons.cloud_off,
                  texto: consulta.erro!.message,
                  acao: FinButton.text(
                    label: 'Tentar de novo',
                    icon: Icons.refresh,
                    onPressed: _recarregar,
                  ),
                ),
              );
            }
            if (lista.isNotEmpty && i == cabecalho.length + dias.length) {
              return CarregandoMais(
                key: ValueKey(lista.length),
                aoAparecer: consulta?.carregarMais,
              );
            }
            if (lista.isEmpty) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: EmptyCard(
                  icon: Icons.history,
                  texto: 'Nenhum lançamento neste período.',
                ),
              );
            }
            final e = dias[i - cabecalho.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
              ),
            );
          },
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
