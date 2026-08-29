import 'dart:async';

import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../services/auth_service.dart';
import '../services/lancamento_service.dart';
import '../widgets/saldo_card.dart';
import '../widgets/resumo_card.dart';
import '../widgets/opcao_button.dart';
import '../widgets/grafico_pizza.dart';
import '../widgets/grafico_barras.dart';
import 'main_navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _timerSaudacao;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agendarViradaDaSaudacao();
  }

  @override
  void dispose() {
    _timerSaudacao?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ao voltar do segundo plano o horário pode ter mudado de faixa
    // (e o timer pode ter sido suspenso pelo sistema).
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
      _agendarViradaDaSaudacao();
      AuthService.recarregarPerfil();
    }
  }

  // ── Saudação ─────────────────────────────────────────────────

  /// Faixas: 5h–11h59 bom dia, 12h–17h59 boa tarde, 18h–4h59 boa noite.
  String get _saudacao {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return "Bom dia";
    if (hora >= 12 && hora < 18) return "Boa tarde";
    return "Boa noite";
  }

  /// Momento da próxima troca de saudação (5h, 12h ou 18h).
  DateTime _proximaVirada() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    for (final hora in [5, 12, 18]) {
      final marco = hoje.add(Duration(hours: hora));
      if (marco.isAfter(agora)) return marco;
    }
    // Passou das 18h: a próxima virada é às 5h de amanhã.
    return hoje.add(const Duration(days: 1, hours: 5));
  }

  /// Reagenda o rebuild para o instante exato da virada, em vez de
  /// ficar checando o relógio a cada segundo.
  void _agendarViradaDaSaudacao() {
    _timerSaudacao?.cancel();
    final espera = _proximaVirada().difference(DateTime.now());
    _timerSaudacao = Timer(espera + const Duration(seconds: 1), () {
      if (mounted) setState(() {});
      _agendarViradaDaSaudacao();
    });
  }

  // ── Navegação ────────────────────────────────────────────────

  Future<void> _recarregar() async {
    try {
      await LancamentoService.carregar(force: true);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  /// Abre uma tela empilhada (formulários) e recarrega ao voltar.
  Future<void> _abrirRota(String rota) async {
    await Navigator.pushNamed(context, rota);
    await _recarregar();
  }

  /// Troca a aba da barra inferior em vez de empilhar a tela.
  void _irParaAba(int aba, String rotaFallback) {
    final nav = NavegacaoPrincipal.of(context);
    if (nav != null) {
      nav.irParaAba(aba);
    } else {
      _abrirRota(rotaFallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldo = LancamentoService.saldo;
    final totalReceitas = LancamentoService.totalReceitas;
    final totalDespesas = LancamentoService.totalDespesas;
    final receitas = LancamentoService.getReceitas();
    final despesas = LancamentoService.getDespesas();

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
              // Header — escuta AuthService para refletir edições
              // feitas na aba Perfil.
              ValueListenableBuilder<int>(
                valueListenable: AuthService.usuarioRevisao,
                builder: (context, _, __) {
                  final primeiroNome = AuthService.primeiroNome;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "FinUp",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkText,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              primeiroNome.isEmpty
                                  ? "$_saudacao!"
                                  : "$_saudacao, $primeiroNome!",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.mediumText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _irParaAba(Abas.perfil, AppRoutes.perfil),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: AppTheme.blueShadow,
                          ),
                          child: Center(
                            child: Text(
                              AuthService.iniciais,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Saldo
              SaldoCard(saldo: saldo),
              const SizedBox(height: 16),

              // Resumo entrada/saída
              Row(
                children: [
                  Expanded(
                    child: ResumoCard(
                      titulo: "Entradas",
                      valor: totalReceitas,
                      cor: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ResumoCard(
                      titulo: "Saídas",
                      valor: totalDespesas,
                      cor: AppTheme.dangerRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Ações rápidas
              const Text(
                "Ações rápidas",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OpcaoButton(
                      icon: Icons.add_rounded,
                      label: "Receita",
                      cor: AppTheme.successGreen,
                      onTap: () => _abrirRota(AppRoutes.novaReceita),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OpcaoButton(
                      icon: Icons.remove_rounded,
                      label: "Despesa",
                      cor: AppTheme.dangerRed,
                      onTap: () => _abrirRota(AppRoutes.novaDespesa),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OpcaoButton(
                      icon: Icons.flag_rounded,
                      label: "Metas",
                      cor: AppTheme.primaryBlue,
                      onTap: () => _irParaAba(Abas.metas, AppRoutes.metas),
                    ),
                  ),
                ],
              ),

              // Gráficos
              GraficoPizza(
                entrada: totalReceitas,
                saida: totalDespesas,
              ),
              GraficoBarras(
                titulo: "Receitas por categoria",
                lancamentos: receitas,
                corBarra: AppTheme.primaryBlue,
              ),
              GraficoBarras(
                titulo: "Despesas por categoria",
                lancamentos: despesas,
                corBarra: AppTheme.dangerRed,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
