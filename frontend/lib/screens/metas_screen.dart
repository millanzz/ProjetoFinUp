import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/meta_model.dart';
import '../services/api_client.dart';
import '../services/meta_service.dart';
import '../widgets/meta_card.dart';
import '../widgets/skeu_button.dart';
import '../widgets/skeu_input.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  bool _carregando = true;
  List<MetaModel> _metas = [];

  static const List<String> _icones = [
    '🎯', '💰', '🏠', '🚗', '✈️', '📱', '🎓', '💻', '🏖️', '🎁',
  ];

  @override
  void initState() {
    super.initState();
    _carregarMetas();
  }

  Future<void> _carregarMetas() async {
    try {
      final metas = await MetaService.carregar();
      if (mounted) {
        setState(() {
          _metas = metas;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarMensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? AppTheme.dangerRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  double get _progressoGeral {
    if (_metas.isEmpty) return 0;
    final soma = _metas.fold<double>(
      0,
      (s, m) => s + m.progresso.clamp(0.0, 1.0),
    );
    return soma / _metas.length;
  }

  // ── Nova meta ────────────────────────────────────────────────

  void _abrirNovaMeta() {
    final tituloController = TextEditingController();
    final valorMetaController = TextEditingController();
    final valorInicialController = TextEditingController();
    String iconeSelecionado = _icones.first;
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: AppTheme.cardLightGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.silverMist,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Nova meta",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SkeuInput(
                    label: "Título",
                    hint: "Ex.: Viagem de férias",
                    controller: tituloController,
                  ),
                  const SizedBox(height: 16),
                  SkeuInput(
                    label: "Valor da meta (R\$)",
                    hint: "0,00",
                    controller: valorMetaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SkeuInput(
                    label: "Valor inicial (opcional)",
                    hint: "0,00",
                    controller: valorInicialController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "Ícone",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final icone in _icones)
                        GestureDetector(
                          onTap: () => setModalState(
                            () => iconeSelecionado = icone,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: iconeSelecionado == icone
                                  ? AppTheme.primaryGradient
                                  : AppTheme.cardLightGradient,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: iconeSelecionado == icone
                                    ? AppTheme.primaryBlue
                                    : AppTheme.silverMist.withOpacity(0.6),
                                width: iconeSelecionado == icone ? 2 : 1,
                              ),
                              boxShadow: iconeSelecionado == icone
                                  ? AppTheme.blueShadow
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                icone,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SkeuButton(
                    text: "Criar meta",
                    icon: Icons.flag_rounded,
                    loading: salvando,
                    onPressed: () async {
                      final titulo = tituloController.text.trim();
                      final valorMeta = double.tryParse(
                        valorMetaController.text.trim().replaceAll(',', '.'),
                      );
                      final valorInicial = double.tryParse(
                            valorInicialController.text
                                .trim()
                                .replaceAll(',', '.'),
                          ) ??
                          0;

                      if (titulo.isEmpty) {
                        _mostrarMensagem("Informe o título da meta.",
                            erro: true);
                        return;
                      }
                      if (valorMeta == null || valorMeta <= 0) {
                        _mostrarMensagem(
                          "Informe um valor de meta válido.",
                          erro: true,
                        );
                        return;
                      }

                      setModalState(() => salvando = true);

                      try {
                        await MetaService.criar(
                          titulo: titulo,
                          valorMeta: valorMeta,
                          valorInicial: valorInicial,
                          icone: iconeSelecionado,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _mostrarMensagem("Meta criada com sucesso!");
                        await _carregarMetas();
                      } on ApiException catch (e) {
                        setModalState(() => salvando = false);
                        _mostrarMensagem(e.message, erro: true);
                      } catch (_) {
                        setModalState(() => salvando = false);
                        _mostrarMensagem(
                          "Não foi possível criar a meta.",
                          erro: true,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Aporte ───────────────────────────────────────────────────

  void _abrirAporte(MetaModel meta) {
    final valorController = TextEditingController();
    bool salvando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Text(meta.icone, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meta.titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "R\$ ${meta.valorAtual.toStringAsFixed(2)} de "
                "R\$ ${meta.valorMeta.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mediumText,
                ),
              ),
              const SizedBox(height: 16),
              SkeuInput(
                label: "Valor do aporte (R\$)",
                hint: "0,00",
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: salvando ? null : () => Navigator.pop(ctx),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: AppTheme.coolGray),
              ),
            ),
            TextButton(
              onPressed: salvando
                  ? null
                  : () async {
                      final valor = double.tryParse(
                        valorController.text.trim().replaceAll(',', '.'),
                      );
                      if (valor == null || valor <= 0) {
                        _mostrarMensagem(
                          "Informe um valor válido.",
                          erro: true,
                        );
                        return;
                      }

                      setDialogState(() => salvando = true);

                      try {
                        await MetaService.aportar(meta, valor);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _mostrarMensagem("Aporte registrado!");
                        await _carregarMetas();
                      } catch (_) {
                        setDialogState(() => salvando = false);
                        _mostrarMensagem(
                          "Não foi possível registrar o aporte.",
                          erro: true,
                        );
                      }
                    },
              child: const Text(
                "Confirmar",
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Excluir ──────────────────────────────────────────────────

  Future<void> _confirmarExclusao(MetaModel meta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Excluir meta",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        content: Text(
          'Deseja excluir a meta "${meta.titulo}"?',
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
      await MetaService.remover(meta.id);
      _mostrarMensagem("Meta excluída.");
      await _carregarMetas();
    } catch (_) {
      _mostrarMensagem("Não foi possível excluir a meta.", erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryBlue,
          onRefresh: _carregarMetas,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Metas",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: _abrirNovaMeta,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          boxShadow: AppTheme.blueShadow,
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Nova meta",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_carregando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  )
                else ...[
                  // Resumo geral
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.4),
                          offset: const Offset(0, 8),
                          blurRadius: 20,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Progresso geral",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                                "${_metas.length} ${_metas.length == 1 ? 'meta' : 'metas'}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${(_progressoGeral * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progressoGeral,
                            minHeight: 10,
                            backgroundColor:
                                Colors.white.withOpacity(0.25),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_metas.isEmpty)
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
                      child: const Column(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: AppTheme.coolGray,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Nenhuma meta ainda.\nCrie sua primeira meta financeira!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                    for (final meta in _metas)
                      MetaCard(
                        meta: meta,
                        onTap: () => _abrirAporte(meta),
                        onLongPress: () => _confirmarExclusao(meta),
                      ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
