import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/lancamento_service.dart';
import '../services/categoria_service.dart';
import '../widgets/skeu_button.dart';
import '../widgets/skeu_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _aceitouTermos = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
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

  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarErro("Preencha todos os campos para continuar.");
      return;
    }
    if (senha.length < 6) {
      _mostrarErro("A senha deve ter pelo menos 6 caracteres.");
      return;
    }
    if (!_aceitouTermos) {
      _mostrarErro("Você precisa aceitar os termos de uso.");
      return;
    }

    setState(() => _carregando = true);

    try {
      await AuthService.register(nome: nome, email: email, senha: senha);

      try {
        await Future.wait([
          LancamentoService.carregar(force: true),
          CategoriaService.carregar(force: true),
        ]);
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) _mostrarErro(e.message);
    } catch (_) {
      if (mounted) {
        _mostrarErro(
          "Não foi possível conectar ao servidor. Verifique se o back-end está rodando.",
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: AppTheme.blueShadow,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Criar conta",
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
                "Comece a organizar sua vida financeira",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.mediumText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              SkeuInput(
                label: "Nome completo",
                hint: "Seu nome",
                controller: _nomeController,
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.coolGray,
                  size: 20,
                ),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 18),
              SkeuInput(
                label: "Senha",
                hint: "Mínimo de 6 caracteres",
                controller: _senhaController,
                obscureText: true,
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.coolGray,
                  size: 20,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _aceitouTermos,
                      activeColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (v) =>
                          setState(() => _aceitouTermos = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Li e aceito os termos de uso e a política de privacidade",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mediumText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SkeuButton(
                text: "Criar conta",
                icon: Icons.check_rounded,
                loading: _carregando,
                onPressed: _cadastrar,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Já tem uma conta?",
                    style: TextStyle(
                      color: AppTheme.mediumText,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _carregando ? null : () => Navigator.pop(context),
                    child: const Text(
                      "Entrar",
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
    );
  }
}
