import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/categorias.dart';
import '../core/formatters.dart';
import '../models/meta_model.dart';
import '../services/api_client.dart';
import '../services/meta_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_feedback.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';
import '../widgets/meta_card.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMetas();
  }

  Future<void> _carregarMetas() async {
    try {
      await MetaService.carregar();
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  bool get _podeVoltar => ModalRoute.of(context)?.canPop ?? false;

  // ── Nova meta ────────────────────────────────────────────────

  Future<void> _abrirNovaMeta() async {
    final tituloController = TextEditingController();
    final valorMetaController = TextEditingController();
    final valorInicialController = TextEditingController();
    var icone = 'flag';
    var salvando = false;

    final criada = await showFinSheet<bool>(
      context: context,
      builder: (ctx, setSheet) {
        final c = ctx.fin;

        Future<void> criar() async {
          final titulo = tituloController.text.trim();
          final valorMeta = Fmt.parseValor(valorMetaController.text);
          final valorInicial = Fmt.parseValor(valorInicialController.text) ?? 0;

          if (titulo.isEmpty) {
            showFinSnack(context, 'Informe o título da meta.', erro: true);
            return;
          }
          if (valorMeta == null || valorMeta <= 0) {
            showFinSnack(context, 'Informe um valor de meta válido.', erro: true);
            return;
          }

          setSheet(() => salvando = true);
          try {
            await MetaService.criar(
              titulo: titulo,
              valorMeta: valorMeta,
              valorInicial: valorInicial,
              icone: icone,
            );
            if (ctx.mounted) Navigator.pop(ctx, true);
          } on ApiException catch (e) {
            setSheet(() => salvando = false);
            if (mounted) showFinSnack(context, e.message, erro: true);
          } catch (_) {
            setSheet(() => salvando = false);
            if (mounted) showFinSnack(context, 'Não foi possível criar a meta.', erro: true);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nova meta',
              style: FinType.titleL.copyWith(color: c.text, shadows: FinFx.emboss(c)),
            ),
            const SizedBox(height: 16),
            FinField(
              label: 'Título',
              hint: 'Ex.: Viagem de férias',
              controller: tituloController,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            FinField(
              label: 'Valor da meta',
              hint: 'R\$ 0,00',
              controller: valorMetaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            FinField(
              label: 'Valor inicial (opcional)',
              hint: 'R\$ 0,00',
              controller: valorInicialController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            Text('Ícone', style: FinType.titleS.copyWith(color: c.text)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final k in MetaIcones.chaves)
                  _IconeOpcao(
                    chave: k,
                    selecionado: k == icone,
                    onTap: () => setSheet(() => icone = k),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FinButton(
              label: 'Criar meta',
              height: 56,
              expand: true,
              loading: salvando,
              onPressed: criar,
            ),
          ],
        );
      },
    );

    if (criada == true && mounted) showFinSnack(context, 'Meta criada');
  }

  // ── Aporte ───────────────────────────────────────────────────

  Future<void> _abrirAporte(MetaModel meta) async {
    final valorController = TextEditingController();
    var salvando = false;

    final ok = await showFinDialog<bool>(
      context: context,
      titulo: meta.titulo,
      conteudo: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Emblem.meta(meta.icone, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${Fmt.brl(meta.valorAtual)} de ${Fmt.brl(meta.valorMeta)}',
                  style: FinType.bodyM.copyWith(color: ctx.fin.textVar),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FinField(
            label: 'Valor do aporte',
            hint: 'R\$ 0,00',
            controller: valorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      acoes: (ctx, setD) => [
        FinButton.text(
          label: 'Cancelar',
          onPressed: salvando ? null : () => Navigator.pop(ctx),
        ),
        FinButton.text(
          label: 'Confirmar',
          onPressed: salvando
              ? null
              : () async {
                  final valor = Fmt.parseValor(valorController.text);
                  if (valor == null || valor <= 0) {
                    showFinSnack(context, 'Informe um valor válido.', erro: true);
                    return;
                  }
                  setD(() => salvando = true);
                  try {
                    await MetaService.aportar(meta, valor);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (_) {
                    setD(() => salvando = false);
                    if (mounted) showFinSnack(context, 'Não foi possível registrar o aporte.', erro: true);
                  }
                },
        ),
      ],
    );

    if (ok == true && mounted) showFinSnack(context, 'Aporte registrado');
  }

  // ── Excluir ──────────────────────────────────────────────────

  Future<void> _confirmarExclusao(MetaModel meta) async {
    final confirmar = await finConfirm(
      context,
      titulo: 'Excluir meta',
      mensagem: 'Deseja excluir a meta "${meta.titulo}"?',
      confirmar: 'Excluir',
    );
    if (!confirmar) return;

    try {
      await MetaService.remover(meta.id);
      if (mounted) showFinSnack(context, 'Meta excluída');
    } catch (_) {
      if (mounted) showFinSnack(context, 'Não foi possível excluir a meta.', erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MetaService.revisao,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = context.fin;
    final metas = MetaService.metas;
    final guardado = metas.fold<double>(0, (s, m) => s + m.valorAtual);
    final alvo = metas.fold<double>(0, (s, m) => s + m.valorMeta);
    final concluidas = metas.where((m) => m.concluida).length;

    return FinScaffold(
      safeBottom: false,
      floatingActionButton: FinFab(label: 'Nova meta', onTap: _abrirNovaMeta),
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface,
        onRefresh: _carregarMetas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            FinTopBar(title: 'Metas', lead: _podeVoltar ? Icons.arrow_back : null),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _carregando && metas.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: c.primary)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FinGradCard(
                          tone: FinTone.primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Guardado nas metas',
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
                                  Fmt.brl(guardado),
                                  style: FinType.displayS.copyWith(
                                    color: Colors.white,
                                    shadows: FinFx.textOnColor(0.3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'de ${Fmt.brl(alvo)} · $concluidas de ${metas.length} '
                                '${concluidas == 1 ? 'concluída' : 'concluídas'}',
                                style: FinType.bodyS.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _ProgressoGeral(valor: alvo <= 0 ? 0 : guardado / alvo),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SectionHead(
                          title: 'Minhas metas',
                          trailing: metas.isEmpty
                              ? null
                              : Text(
                                  'Toque e segure para excluir',
                                  style: FinType.bodyS.copyWith(color: c.textVar),
                                ),
                        ),
                        const SizedBox(height: 16),
                        if (metas.isEmpty)
                          EmptyCard(
                            icon: Icons.flag,
                            texto: 'Nenhuma meta ainda.\nCrie sua primeira meta financeira!',
                            acao: FinButton.text(
                              label: 'Nova meta',
                              icon: Icons.add,
                              onPressed: _abrirNovaMeta,
                            ),
                          )
                        else
                          for (final meta in metas) ...[
                            MetaCard(
                              meta: meta,
                              onAporte: () => _abrirAporte(meta),
                              onLongPress: () => _confirmarExclusao(meta),
                            ),
                            const SizedBox(height: 16),
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

/// Barra branca de progresso dentro do card azul.
class _ProgressoGeral extends StatelessWidget {
  final double valor;

  const _ProgressoGeral({required this.valor});

  @override
  Widget build(BuildContext context) {
    final f = valor.isNaN ? 0.0 : valor.clamp(0.0, 1.0);
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: f,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xffDCE8FF)],
            ),
            boxShadow: [
              BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconeOpcao extends StatelessWidget {
  final String chave;
  final bool selecionado;
  final VoidCallback onTap;

  const _IconeOpcao({required this.chave, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = MetaIcones.estilo(chave).icon;
    const r = BorderRadius.all(Radius.circular(18));
    if (selecionado) {
      return FinSurface.colored(
        width: 56,
        height: 56,
        depth: 5,
        borderRadius: r,
        alignment: Alignment.center,
        onTap: onTap,
        child: Icon(icon, size: 24, color: Colors.white, shadows: FinFx.textOnColor(0.25)),
      );
    }
    return FinSurface.convex(
      width: 56,
      height: 56,
      depth: 4,
      borderRadius: r,
      alignment: Alignment.center,
      onTap: onTap,
      child: Icon(icon, size: 24, color: context.fin.textVar),
    );
  }
}
