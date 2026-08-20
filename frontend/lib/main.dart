import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/app_routes.dart';
import 'services/auth_service.dart';
import 'services/lancamento_service.dart';
import 'services/categoria_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tenta restaurar a sessão salva (token JWT no shared_preferences)
  final logado = await AuthService.restaurarSessao();

  if (logado) {
    // Pré-carrega os dados; se falhar, as telas recarregam depois.
    try {
      await Future.wait([
        LancamentoService.carregar(force: true),
        CategoriaService.carregar(force: true),
      ]);
    } catch (_) {}
  }

  runApp(FinanceiroApp(logado: logado));
}

class FinanceiroApp extends StatelessWidget {
  final bool logado;

  const FinanceiroApp({super.key, this.logado = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão Financeira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: logado ? AppRoutes.home : AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
