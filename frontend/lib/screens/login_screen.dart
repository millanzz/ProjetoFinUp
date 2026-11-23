import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/categoria_service.dart';
import '../services/lancamento_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_feedback.dart';
import '../widgets/fin_surface.dart';
import 'esqueci_senha_screen.dart';

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

  /// Abre "Esqueci minha senha"; ao concluir, preenche o e-mail aqui.
  Future<void> _esqueciSenha() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EsqueciSenhaScreen(emailInicial: _emailController.text.trim()),
      ),
    );
    if (email == null || !mounted) return;
    _emailController.text = email;
    _senhaController.clear();
    showFinSnack(context, 'Senha redefinida. Entre com a nova senha.');
  }

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      showFinSnack(context, 'Preencha e-mail e senha para entrar.', erro: true);
      return;
    }

    FocusScope.of(context).unfocus();
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
      if (mounted) showFinSnack(context, e.message, erro: true);
    } catch (_) {
      if (mounted) {
        showFinSnack(
          context,
          'Não foi possível conectar ao servidor. Verifique se o back-end está rodando.',
          erro: true,
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fin;

    return FinScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 48, 26, 32),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: FinSurface.convex(
                  width: 184,
                  height: 184,
                  depth: 12,
                  borderRadius: BorderRadius.circular(48),
                  alignment: Alignment.center,
                  child: Image.asset(
                    c.isDark
                        ? 'assets/images/logo_dark.png'
                        : 'assets/images/logo_light.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Entrar na sua conta',
                textAlign: TextAlign.center,
                style: FinType.headlineS.copyWith(
                  color: c.text,
                  shadows: FinFx.emboss(c),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Organize, planeje e evolua.',
                textAlign: TextAlign.center,
                style: FinType.bodyM.copyWith(color: c.textVar),
              ),
              const SizedBox(height: 28),
              FinField(
                label: 'E-mail',
                hint: 'seuemail@exemplo.com',
                controller: _emailController,
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 18),
              FinField(
                label: 'Senha',
                hint: 'Sua senha',
                controller: _senhaController,
                icon: Icons.lock,
                obscure: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _fazerLogin(),
                autofillHints: const [AutofillHints.password],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FinButton.text(
                  label: 'Esqueci minha senha',
                  onPressed: _carregando ? null : _esqueciSenha,
                ),
              ),
              const SizedBox(height: 18),
              FinButton(
                label: 'Entrar',
                height: 56,
                expand: true,
                loading: _carregando,
                onPressed: _fazerLogin,
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Ainda não tem conta?',
                    style: FinType.bodyM.copyWith(color: c.textVar),
                  ),
                  FinButton.text(
                    label: 'Criar conta',
                    onPressed: _carregando
                        ? null
                        : () => Navigator.pushNamed(context, AppRoutes.register),
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
