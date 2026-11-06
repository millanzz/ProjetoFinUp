import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/categorias.dart';
import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import '../services/api_client.dart';
import '../services/lancamento_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_feedback.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';

/// Formulário de lançamento (receita ou despesa).
///
/// - **Criação** (`lancamento == null`): `LancamentoService.adicionar`;
///   devolve o [LancamentoModel] criado no `Navigator.pop`.
/// - **Edição**: `LancamentoService.editar`; devolve `true`.
class LancamentoFormScreen extends StatefulWidget {
  final TipoLancamento tipo;
  final LancamentoModel? lancamento;

  const LancamentoFormScreen({super.key, required this.tipo, this.lancamento});

  static Future<bool?> abrirEdicao(BuildContext context, LancamentoModel lancamento) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LancamentoFormScreen(tipo: lancamento.tipo, lancamento: lancamento),
      ),
    );
  }

  @override
  State<LancamentoFormScreen> createState() => _LancamentoFormScreenState();
}

class _LancamentoFormScreenState extends State<LancamentoFormScreen> {
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  String? _categoria;
  DateTime _data = DateTime.now();
  bool _parcelado = false;
  bool _carregando = false;

  bool get _isReceita => widget.tipo == TipoLancamento.receita;
  bool get _isEdicao => widget.lancamento != null;

  String get _titulo {
    if (_isEdicao) return _isReceita ? 'Editar receita' : 'Editar despesa';
    return _isReceita ? 'Nova receita' : 'Nova despesa';
  }

  String get _textoBotao {
    if (_isEdicao) return 'Salvar alterações';
    return _isReceita ? 'Salvar receita' : 'Salvar despesa';
  }

  /// Lista fixa + a categoria atual (se foi criada fora da lista).
  List<String> get _categorias {
    final base = _isReceita ? Categorias.receita : Categorias.despesa;
    final atual = widget.lancamento?.categoria;
    if (atual != null && atual.isNotEmpty && !base.contains(atual)) {
      return [atual, ...base];
    }
    return base;
  }

  @override
  void initState() {
    super.initState();
    final l = widget.lancamento;
    if (l != null) {
      _descricaoController.text = l.titulo;
      _valorController.text = Fmt.valorCampo(l.valor);
      _categoria = l.categoria;
      _data = l.data;
      _parcelado = l.parcelado;
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) setState(() => _data = selecionada);
  }

  Future<void> _salvar() async {
    final descricao = _descricaoController.text.trim();
    final valor = Fmt.parseValor(_valorController.text);

    if (valor == null || valor <= 0) {
      showFinSnack(context, 'Informe um valor válido maior que zero.', erro: true);
      return;
    }
    if (descricao.isEmpty) {
      showFinSnack(context, 'Informe uma descrição.', erro: true);
      return;
    }
    if (_categoria == null) {
      showFinSnack(context, 'Selecione uma categoria.', erro: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _carregando = true);

    try {
      final dados = LancamentoModel(
        id: widget.lancamento?.id ?? '',
        titulo: descricao,
        valor: valor,
        data: _data,
        tipo: widget.tipo,
        categoria: _categoria,
        parcelado: _parcelado,
      );

      if (_isEdicao) {
        await LancamentoService.editar(dados);
        if (mounted) Navigator.pop(context, true);
      } else {
        final criado = await LancamentoService.adicionar(dados);
        if (mounted) Navigator.pop(context, criado);
      }
    } on ApiException catch (e) {
      if (mounted) showFinSnack(context, e.message, erro: true);
    } catch (_) {
      if (mounted) {
        showFinSnack(context, 'Não foi possível salvar. Verifique sua conexão.', erro: true);
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final corValor = _isReceita ? c.income : c.expense;
    final estiloValor = FinType.displayS.copyWith(
      fontSize: 42,
      height: 50 / 42,
      color: corValor,
    );

    return FinScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FinTopBar(title: _titulo, lead: Icons.close),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Valor em destaque, numa cuia côncava
                  FinSurface.pressed(
                    depth: 6,
                    borderRadius: BorderRadius.circular(22),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Column(
                      children: [
                        Text('Valor', style: FinType.labelL.copyWith(color: c.textVar)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('R\$ ', style: estiloValor),
                            IntrinsicWidth(
                              child: TextField(
                                controller: _valorController,
                                autofocus: !_isEdicao,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: estiloValor,
                                cursorColor: corValor,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: '0,00',
                                  hintStyle: estiloValor.copyWith(
                                    color: corValor.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FinField(
                    label: 'Descrição',
                    hint: _isReceita ? 'Ex.: Salário de outubro' : 'Ex.: Mercado',
                    controller: _descricaoController,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Categoria',
                    style: FinType.titleS.copyWith(color: c.text, shadows: FinFx.emboss(c)),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, box) {
                      // 4 colunas com 10px de espaço, como no Figma (86px cada).
                      final w = ((box.maxWidth - 30) / 4).floorToDouble();
                      return Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: [
                          for (final cat in _categorias)
                            _CategoriaTile(
                              categoria: cat,
                              width: w,
                              selecionada: cat == _categoria,
                              onTap: () => setState(() => _categoria = cat),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  FinPickerField(
                    label: 'Data',
                    value: Fmt.dataCurta(_data),
                    icon: Icons.calendar_today,
                    onTap: _selecionarData,
                  ),
                  const SizedBox(height: 18),
                  FinSurface.convex(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    onTap: () => setState(() => _parcelado = !_parcelado),
                    child: Row(
                      children: [
                        Icon(Icons.repeat, size: 22, color: c.textVar),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isReceita ? 'Receita parcelada' : 'Compra parcelada',
                                style: FinType.bodyL.copyWith(
                                  color: c.text,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Divide o valor em parcelas mensais',
                                style: FinType.bodyM.copyWith(color: c.textVar),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FinSwitch(
                          value: _parcelado,
                          onChanged: (v) => setState(() => _parcelado = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  FinButton(
                    label: _textoBotao,
                    kind: _isReceita ? FinButtonKind.primary : FinButtonKind.coral,
                    height: 56,
                    expand: true,
                    loading: _carregando,
                    onPressed: _salvar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaTile extends StatelessWidget {
  final String categoria;
  final double width;
  final bool selecionada;
  final VoidCallback onTap;

  const _CategoriaTile({
    required this.categoria,
    required this.width,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final conteudo = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Emblem.categoria(categoria, size: 36),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            categoria,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: FinType.labelS.copyWith(
              color: selecionada ? c.primary : c.textVar,
              fontWeight: selecionada ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );

    if (selecionada) {
      return FinSurface.pressed(
        width: width,
        height: 82,
        depth: 3.5,
        borderRadius: BorderRadius.circular(16),
        border: c.primary,
        onTap: onTap,
        child: conteudo,
      );
    }
    return Semantics(
      button: true,
      label: categoria,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: width, height: 82, child: conteudo),
      ),
    );
  }
}
