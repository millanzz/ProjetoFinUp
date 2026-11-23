import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'services/auth_service.dart';
import 'services/categoria_service.dart';
import 'services/lancamento_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeController.carregar();

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'FinUp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: logado ? AppRoutes.home : AppRoutes.login,
        // Na Web o endereço (#/home, #/login…) virava a rota inicial e ignorava
        // a sessão (DEF-11). A tela inicial passa a depender só de estar logado.
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            settings: RouteSettings(name: logado ? AppRoutes.home : AppRoutes.login),
            builder: AppRoutes.routes[logado ? AppRoutes.home : AppRoutes.login]!,
          ),
        ],
        routes: AppRoutes.routes,
      ),
    );
  }
}
