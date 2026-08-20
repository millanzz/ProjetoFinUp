import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/lancamento_model.dart';
import '../services/api_client.dart';
import '../services/lancamento_service.dart';
import '../widgets/skeu_button.dart';
import '../widgets/skeu_input.dart';
import '../widgets/skeu_dropdown.dart';

/// Formulário de novo lançamento (receita ou despesa).
class LancamentoFormScreen extends StatefulWidget {
  final String titulo;
  final String textoBotao;
  final TipoLancamento tipo;
  final List<String> categorias;

  const LancamentoFormScreen({
    super.key,
    required this.titulo,
    required this.textoBotao,
    required this.tipo,
    required this.categorias,
  });

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
  Color get _cor => _isReceita ? AppTheme.primaryBlue : AppTheme.dangerRed;

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _cor),
        ),
        child: child!,
      ),
    );
    if (selecionada != null) {
      setState(() => _data = selecionada);
    }
  }

  Future<void> _salvar() async {
    final descricao = _descricaoController.text.trim();
    // aceita tanto "10,50" quanto "10.50"
    final valor = double.tryParse(
      _valorController.text.trim().replaceAll(',', '.'),
    );

    if (descricao.isEmpty) {
      _mostrarErro("Informe uma descrição.");
      return;
    }
    if (valor == null || valor <= 0) {
      _mostrarErro("Informe um valor válido maior que zero.");
      return;
    }
    if (_categoria == null) {
      _mostrarErro("Selecione uma categoria.");
      return;
    }

    setState(() => _carregando = true);

    try {
      await LancamentoService.adicionar(
        LancamentoModel(
          id: '',
          titulo: descricao,
          valor: valor,
          data: _data,
          tipo: widget.tipo,
          categoria: _categoria,
          parcelado: _parcelado,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isReceita
                ? "Receita registrada com sucesso!"
                : "Despesa registrada com sucesso!",
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) _mostrarErro(e.message);
    } catch (_) {
      if (mounted) {
        _mostrarErro("Não foi possível salvar. Verifique sua conexão.");
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header com voltar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardLightGradient,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                        ),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.darkText,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_cor.withOpacity(0.85), _cor],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _cor.withOpacity(0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isReceita
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SkeuInput(
                label: "Valor (R\$)",
                hint: "0,00",
                controller: _valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(
                  Icons.attach_money_rounded,
                  color: AppTheme.coolGray,
                  size: 20,
                ),
              ),
              const SizedBox(height: 20),

              SkeuInput(
                label: "Descrição",
                hint: _isReceita ? "Ex.: Salário de julho" : "Ex.: Mercado",
                controller: _descricaoController,
                prefixIcon: const Icon(
                  Icons.notes_rounded,
                  color: AppTheme.coolGray,
                  size: 20,
                ),
              ),
              const SizedBox(height: 20),

              SkeuDropdown<String>(
                label: "Categoria",
                hint: "Selecione uma categoria",
                value: _categoria,
                items: widget.categorias
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v),
              ),
              const SizedBox(height: 20),

              // Data
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "Data",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfff8fafc),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.silverMist.withOpacity(0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.silverMist.withOpacity(0.35),
                            offset: const Offset(0, 2),
                            blurRadius: 3,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.coolGray,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${_data.day.toString().padLeft(2, '0')}/"
                            "${_data.month.toString().padLeft(2, '0')}/"
                            "${_data.year}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.coolGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Parcelado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardLightGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.credit_card_rounded,
                      color: AppTheme.coolGray,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Lançamento parcelado",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                    Switch(
                      value: _parcelado,
                      activeColor: _cor,
                      onChanged: (v) => setState(() => _parcelado = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SkeuButton(
                text: widget.textoBotao,
                icon: Icons.check_rounded,
                loading: _carregando,
                variant: _isReceita
                    ? SkeuButtonVariant.primary
                    : SkeuButtonVariant.danger,
                onPressed: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
