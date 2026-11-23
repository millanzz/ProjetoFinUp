import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/categoria_service.dart';
import '../services/lancamento_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_feedback.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';

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
  // Abre a Política de Privacidade (termos de uso e tratamento de dados)
  late final _linkTermos = TapGestureRecognizer()
    ..onTap = () => Navigator.pushNamed(context, AppRoutes.privacidade);
  bool _carregando = false;

  @override
  void dispose() {
    _linkTermos.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _erro(String m) => showFinSnack(context, m, erro: true);

  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _erro('Preencha todos os campos para continuar.');
      return;
    }
    if (senha.length < 6) {
      _erro('A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (!_aceitouTermos) {
      _erro('Você precisa aceitar os termos de uso.');
      return;
    }

    FocusScope.of(context).unfocus();
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
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } on ApiException catch (e) {
      if (mounted) _erro(e.message);
    } catch (_) {
      if (mounted) {
        _erro('Não foi possível conectar ao servidor. Verifique se o back-end está rodando.');
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
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FinTopBar(lead: Icons.arrow_back),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Criar conta',
                      style: FinType.headlineS.copyWith(
                        color: c.text,
                        shadows: FinFx.emboss(c),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comece a organizar sua vida financeira.',
                      style: FinType.bodyL.copyWith(color: c.textVar),
                    ),
                    const SizedBox(height: 28),
                    FinField(
                      label: 'Nome completo',
                      hint: 'Seu nome',
                      controller: _nomeController,
                      icon: Icons.person,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: 18),
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
                      hint: 'Crie uma senha',
                      controller: _senhaController,
                      icon: Icons.lock,
                      obscure: true,
                      helper: 'Mínimo de 6 caracteres',
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _aceitouTermos = !_aceitouTermos),
                      child: Row(
                        children: [
                          FinCheckbox(
                            value: _aceitouTermos,
                            onChanged: (v) => setState(() => _aceitouTermos = v),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: FinType.bodyM.copyWith(color: c.text),
                                children: [
                                  const TextSpan(text: 'Li e aceito os '),
                                  TextSpan(
                                    text: 'termos de uso',
                                    recognizer: _linkTermos,
                                    style: FinType.labelL.copyWith(
                                      color: c.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FinButton(
                      label: 'Criar conta',
                      height: 56,
                      expand: true,
                      loading: _carregando,
                      onPressed: _cadastrar,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Já tem conta?', style: FinType.bodyM.copyWith(color: c.textVar)),
                        FinButton.text(
                          label: 'Entrar',
                          onPressed: _carregando ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
