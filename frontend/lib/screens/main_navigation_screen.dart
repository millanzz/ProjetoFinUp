import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/lancamento_model.dart';
import '../services/lancamento_service.dart';
import 'home_screen.dart';
import 'lancamentos_screen.dart';
import 'metas_screen.dart';
import 'historico_screen.dart';
import 'perfil_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    LancamentosScreen(
      tipo: TipoLancamento.receita,
      titulo: "Entradas",
    ),
    LancamentosScreen(
      tipo: TipoLancamento.despesa,
      titulo: "Despesas",
    ),
    MetasScreen(),
    HistoricoScreen(),
    PerfilScreen(),
  ];

  Future<void> _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);

    // Recarrega os dados ao trocar de aba, para refletir
    // alterações feitas em outras telas.
    try {
      await LancamentoService.carregar(force: true);
      if (mounted) setState(() {});
    } catch (_) {
      // silencioso: mantém o cache atual
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardLightGradient,
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.9),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepBlue.withOpacity(0.10),
              offset: const Offset(0, -6),
              blurRadius: 18,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, "Home"),
                _navItem(1, Icons.arrow_downward_rounded, "Entrada"),
                _navItem(2, Icons.arrow_upward_rounded, "Despesa"),
                _navItem(3, Icons.flag_rounded, "Metas"),
                _navItem(4, Icons.history_rounded, "Histórico"),
                _navItem(5, Icons.person_rounded, "Perfil"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selecionado = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: selecionado ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selecionado
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.35),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: selecionado ? Colors.white : AppTheme.coolGray,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        selecionado ? FontWeight.w700 : FontWeight.w500,
                    color: selecionado ? Colors.white : AppTheme.coolGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
