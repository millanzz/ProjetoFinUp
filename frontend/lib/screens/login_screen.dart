import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/lancamento_service.dart';
import '../services/categoria_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/skeu_button.dart';
import '../widgets/skeu_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
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

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarErro("Preencha e-mail e senha para entrar.");
      return;
    }

    setState(() => _carregando = true);

    try {
      await AuthService.login(email: email, senha: senha);

      // pré-carrega os dados do usuário
      try {
        await Future.wait([
          LancamentoService.carregar(force: true),
          CategoriaService.carregar(force: true),
        ]);
      } catch (_) {
        // se falhar aqui, as telas recarregam depois
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on ApiException catch (e) {
      if (mounted) _mostrarErro(e.message);
    } catch (_) {
      if (mounted) {
        _mostrarErro(
          "Não foi possível conectar ao servidor. "
          "Verifique se o back-end está rodando.",
        );
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo do app
                const Center(child: AppLogo(size: 116)),
                const SizedBox(height: 24),
                const Text(
                  "Seja bem-vindo!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Entre para gerenciar suas finanças",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.mediumText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),
                SkeuInput(
                  label: "E-mail",
                  hint: "seuemail@exemplo.com",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppTheme.coolGray,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 20),
                SkeuInput(
                  label: "Senha",
                  hint: "Sua senha",
                  controller: _senhaController,
                  obscureText: true,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.coolGray,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 32),
                SkeuButton(
                  text: "Entrar",
                  icon: Icons.login_rounded,
                  loading: _carregando,
                  onPressed: _fazerLogin,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Não tem uma conta?",
                      style: TextStyle(
                        color: AppTheme.mediumText,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _carregando
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                AppRoutes.register,
                              ),
                      child: const Text(
                        "Cadastre-se",
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
