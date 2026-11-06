import 'package:flutter/material.dart';

import '../models/lancamento_model.dart';
import '../screens/lancamento_form_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/metas_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/register_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String novaReceita = '/nova-receita';
  static const String novaDespesa = '/nova-despesa';
  static const String perfil = '/perfil';
  static const String metas = '/metas';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        home: (_) => const MainNavigationScreen(),
        novaReceita: (_) =>
            const LancamentoFormScreen(tipo: TipoLancamento.receita),
        novaDespesa: (_) =>
            const LancamentoFormScreen(tipo: TipoLancamento.despesa),
        perfil: (_) => const PerfilScreen(),
        metas: (_) => const MetasScreen(),
      };
}
