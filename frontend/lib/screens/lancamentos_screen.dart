import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import '../services/consulta_lancamentos.dart';
import '../services/lancamento_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_feedback.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';
import '../widgets/lancamento_acoes.dart';

/// Entradas OU Despesas, conforme [tipo], filtradas por mês.
class LancamentosScreen extends StatefulWidget {
  final TipoLancamento tipo;

  const LancamentosScreen({super.key, required this.tipo});

  @override
  State<LancamentosScreen> createState() => _LancamentosScreenState();
}

class _LancamentosScreenState extends State<LancamentosScreen> {
  /// Mês exibido; `null` = todos os meses.
  DateTime? _mes = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isReceita => widget.tipo == TipoLancamento.receita;
  FinTone get _tone => _isReceita ? FinTone.primary : FinTone.coral;

  /// Meses anteriores ao atual e "Tudo" não estão no cache: são buscados
  /// página por página, com os totais calculados pela API.
  ConsultaLancamentos? _consulta;

  /// Linhas montadas por vez quando o mês está no cache. O mês corrente de
  /// quem lança muito pode ter milhares de itens; montar todos de uma vez
  /// atrasava a abertura do app, já que esta aba fica viva desde o início.
  static const _lote = 30;
  int _visiveis = _lote;

  void _definirMes(DateTime? mes) {
    _consulta?.dispose();
    _consulta = (mes != null && LancamentoService.cobre(mes))
        ? null
        : ConsultaLancamentos(
            tipo: widget.tipo,
            de: mes,
            ate: mes == null ? null : DateTime(mes.year, mes.month + 1, 0),
          );
    _mes = mes;
    _visiveis = _lote;
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

  Future<void> _escolherMes() async {
    final agora = DateTime.now();
    final opcoes = <DateTime>{
      for (var i = 0; i < 12; i++) DateTime(agora.year, agora.month - i),
      ...LancamentoService.meses,
      for (final l in LancamentoService.getAll()) DateTime(l.data.year, l.data.month),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    final escolhido = await showFinSheet<Object>(
      context: context,
      builder: (ctx, _) {
        final c = ctx.fin;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Escolha o mês',
              style: FinType.titleL.copyWith(color: c.text, shadows: FinFx.emboss(c)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                FinChip(
                  label: 'Tudo',
                  selected: _mes == null,
                  onTap: () => Navigator.pop(ctx, 'tudo'),
                ),
                for (final m in opcoes)
                  FinChip(
                    label: Fmt.mesAno(m),
                    selected: _mes != null && Fmt.mesmoMes(_mes!, m),
                    onTap: () => Navigator.pop(ctx, m),
                  ),
              ],
            ),
          ],
        );
      },
    );
    if (escolhido == null) return;
    setState(() => _definirMes(escolhido is DateTime ? escolhido : null));
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
    final double total;
    final int quantidade;
    if (consulta == null) {
      final todos = _isReceita ? LancamentoService.getReceitas() : LancamentoService.getDespesas();
      lista = todos.where((l) => Fmt.mesmoMes(l.data, _mes!)).toList();
      total = lista.fold<double>(0, (s, l) => s + l.valor);
      quantidade = lista.length;
    } else {
      lista = consulta.itens;
      total = _isReceita ? consulta.receitas : consulta.despesas;
      quantidade = consulta.total;
    }
    final aguardando = consulta != null && !consulta.pronta;
    final temMais = consulta != null ? consulta.temMais : lista.length > _visiveis;
    final linhas = consulta != null ? lista : lista.take(_visiveis);
    final periodo = _mes == null ? 'no total' : 'em ${Fmt.meses[_mes!.month - 1]}';

    return FinScaffold(
      safeBottom: false,
      floatingActionButton: FinFab(
        label: _isReceita ? 'Nova receita' : 'Nova despesa',
        tone: _tone,
        onTap: () => LancamentoAcoes.novo(context, widget.tipo, acimaDoFab: true),
      ),
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface,
        onRefresh: _recarregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            FinTopBar(
              title: _isReceita ? 'Entradas' : 'Despesas',
              actions: [MonthChip(mes: _mes, onTap: _escolherMes)],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FinGradCard(
                    tone: _tone,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isReceita ? 'Total recebido $periodo' : 'Total gasto $periodo',
                          style: FinType.bodyM.copyWith(
                            color: const Color(0xffEEF4FF),
                            shadows: FinFx.textOnColor(0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Fmt.brl(total),
                            style: FinType.displayS.copyWith(
                              color: Colors.white,
                              shadows: FinFx.textOnColor(0.3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aguardando
                              ? 'Carregando…'
                              : '$quantidade ${quantidade == 1 ? 'lançamento' : 'lançamentos'}',
                          style: FinType.bodyS.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (aguardando)
                    const CarregandoMais()
                  else if (consulta?.erro != null && lista.isEmpty)
                    EmptyCard(
                      icon: Icons.cloud_off,
                      texto: consulta!.erro!.message,
                      acao: FinButton.text(
                        label: 'Tentar de novo',
                        icon: Icons.refresh,
                        onPressed: _recarregar,
                      ),
                    )
                  else if (lista.isEmpty)
                    EmptyCard(
                      icon: _isReceita ? Icons.savings : Icons.receipt_long,
                      texto: _isReceita
                          ? 'Nenhuma receita neste período.\nToque em “Nova receita” para adicionar.'
                          : 'Nenhuma despesa neste período.\nToque em “Nova despesa” para adicionar.',
                    )
                  else ...[
                    const SectionHead(title: 'Por categoria'),
                    const SizedBox(height: 10),
                    if (consulta == null)
                      CategoriasCard(lancamentos: lista, tone: _tone)
                    else
                      CategoriasCard.totais(
                        totais: _isReceita ? consulta.categoriasReceita : consulta.categoriasDespesa,
                        tone: _tone,
                      ),
                    const SizedBox(height: 24),
                    SectionHead(
                      title: 'Lançamentos',
                      trailing: Text(
                        'Toque e segure para editar',
                        style: FinType.bodyS.copyWith(color: c.textVar),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListCard(
                      rows: [
                        for (final l in linhas)
                          LancRow(
                            lancamento: l,
                            onTap: () => LancamentoAcoes.menu(context, l),
                            onLongPress: () => LancamentoAcoes.menu(context, l),
                          ),
                      ],
                    ),
                    // Próxima página quando o fim da lista aparece
                    if (temMais)
                      CarregandoMais(
                        key: ValueKey(consulta?.itens.length ?? _visiveis),
                        aoAparecer: consulta != null
                            ? consulta.carregarMais
                            : () => setState(() => _visiveis += _lote),
                      ),
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
