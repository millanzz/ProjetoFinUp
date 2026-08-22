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

class _HomeScreenState extends State<HomeScreen> {
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
  ///
  /// Isso mantém a barra visível e evita o caso em que a tela abria
  /// por cima de tudo, sem botão de voltar. Se por algum motivo a Home
  /// não estiver dentro do [MainNavigationScreen], cai no push normal
  /// (e aí o [TelaHeader] da tela de destino mostra o botão de voltar).
  void _irParaAba(int aba, String rotaFallback) {
    final nav = NavegacaoPrincipal.of(context);
    if (nav != null) {
      nav.irParaAba(aba);
    } else {
      _abrirRota(rotaFallback);
    }
  }

  String get _saudacao {
    final hora = DateTime.now().hour;
    if (hora < 12) return "Bom dia";
    if (hora < 18) return "Boa tarde";
    return "Boa noite";
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dashboard",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$_saudacao, ${AuthService.nome.split(' ').first}!",
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.mediumText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
