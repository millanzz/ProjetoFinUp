import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/lancamento_service.dart';
import '../widgets/fin_layout.dart';
import 'historico_screen.dart';
import 'home_screen.dart';
import 'lancamentos_screen.dart';
import 'metas_screen.dart';
import '../models/lancamento_model.dart';

/// Índices das abas da barra inferior.
/// O Perfil não é aba: abre pelo avatar da Início.
class Abas {
  Abas._();

  static const int home = 0;
  static const int entradas = 1;
  static const int despesas = 2;
  static const int metas = 3;
  static const int historico = 4;
}

/// Dá às telas filhas acesso à troca de abas:
///
///     NavegacaoPrincipal.of(context)?.irParaAba(Abas.metas);
class NavegacaoPrincipal extends InheritedWidget {
  final void Function(int index) irParaAba;

  const NavegacaoPrincipal({
    super.key,
    required this.irParaAba,
    required super.child,
  });

  static NavegacaoPrincipal? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavegacaoPrincipal>();

  @override
  bool updateShouldNotify(NavegacaoPrincipal oldWidget) => false;
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = Abas.home;

  static const _itens = [
    FinNavItem('Início', Icons.home_rounded),
    FinNavItem('Entradas', Icons.arrow_downward),
    FinNavItem('Despesas', Icons.arrow_upward),
    FinNavItem('Metas', Icons.flag),
    FinNavItem('Histórico', Icons.history),
  ];

  static const List<Widget> _screens = [
    HomeScreen(),
    LancamentosScreen(tipo: TipoLancamento.receita),
    LancamentosScreen(tipo: TipoLancamento.despesa),
    MetasScreen(),
    HistoricoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // Sincroniza em segundo plano; as abas escutam LancamentoService.revisao.
    LancamentoService.carregar(force: true).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return NavegacaoPrincipal(
      irParaAba: _onItemTapped,
      // Fora da Início, o "voltar" do sistema retorna para a Início.
      child: PopScope(
        canPop: _selectedIndex == Abas.home,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _onItemTapped(Abas.home);
        },
        child: Scaffold(
          backgroundColor: context.fin.bg,
          body: IndexedStack(index: _selectedIndex, children: _screens),
          bottomNavigationBar: FinNavBar(
            index: _selectedIndex,
            onTap: _onItemTapped,
            items: _itens,
          ),
        ),
      ),
    );
  }
}
