import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_feedback.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';

/// Esqueci minha senha, em duas etapas:
/// 1) informa o e-mail e recebe um código de 6 dígitos;
/// 2) digita o código e a nova senha.
///
/// Ao concluir, volta para o Login devolvendo o e-mail usado.
class EsqueciSenhaScreen extends StatefulWidget {
  final String? emailInicial;

  const EsqueciSenhaScreen({super.key, this.emailInicial});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  late final _emailController = TextEditingController(text: widget.emailInicial ?? '');
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaController = TextEditingController();

  bool _codigoEnviado = false;
  bool _carregando = false;
  int _reenviarEm = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmaController.dispose();
    super.dispose();
  }

  void _erro(String m) => showFinSnack(context, m, erro: true);

  void _iniciarContagem(int segundos) {
    _timer?.cancel();
    setState(() => _reenviarEm = segundos);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _reenviarEm--);
      if (_reenviarEm <= 0) t.cancel();
    });
  }

  /// "g••••••@exemplo.com"
  String get _emailMascarado {
    final e = _emailController.text.trim();
    final at = e.indexOf('@');
    if (at <= 1) return e;
    return '${e[0]}${'•' * (at - 1)}${e.substring(at)}';
  }

  Future<void> _enviarCodigo() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _erro('Informe um e-mail válido.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _carregando = true);
    try {
      final espera = await AuthService.solicitarCodigoSenha(email);
      if (!mounted) return;
      setState(() => _codigoEnviado = true);
      _iniciarContagem(espera);
      showFinSnack(context, 'Se o e-mail estiver cadastrado, enviamos um código.');
    } on ApiException catch (e) {
      if (mounted) _erro(e.message);
    } catch (_) {
      if (mounted) _erro('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _redefinir() async {
    final codigo = _codigoController.text.trim();
    final senha = _senhaController.text;

    if (codigo.length != 6) {
      _erro('Digite o código de 6 dígitos.');
      return;
    }
    if (senha.length < 6) {
      _erro('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (senha != _confirmaController.text) {
      _erro('As senhas não conferem.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _carregando = true);
    try {
      await AuthService.redefinirSenha(
        email: _emailController.text.trim(),
        codigo: codigo,
        novaSenha: senha,
      );
      if (mounted) Navigator.pop(context, _emailController.text.trim());
    } on ApiException catch (e) {
      if (mounted) _erro(e.message);
    } catch (_) {
      if (mounted) _erro('Não foi possível conectar ao servidor.');
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
            FinTopBar(
              lead: Icons.arrow_back,
              onLead: () {
                if (_codigoEnviado && !_carregando) {
                  setState(() => _codigoEnviado = false);
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _codigoEnviado ? _etapaCodigo(c) : _etapaEmail(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(FinColors c, IconData icone, String titulo, String texto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FinSurface.colored(
            width: 56,
            height: 56,
            depth: 6,
            borderRadius: BorderRadius.circular(18),
            alignment: Alignment.center,
            child: Icon(icone, color: Colors.white, size: 26, shadows: FinFx.textOnColor(0.25)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          titulo,
          style: FinType.headlineS.copyWith(color: c.text, shadows: FinFx.emboss(c)),
        ),
        const SizedBox(height: 4),
        Text(texto, style: FinType.bodyL.copyWith(color: c.textVar)),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _etapaEmail(FinColors c) {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecalho(
          c,
          Icons.lock_reset,
          'Esqueci minha senha',
          'Informe o e-mail da sua conta. Vamos enviar um código de 6 dígitos para criar uma nova senha.',
        ),
        FinField(
          label: 'E-mail',
          hint: 'seuemail@exemplo.com',
          controller: _emailController,
          icon: Icons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _enviarCodigo(),
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 28),
        FinButton(
          label: 'Enviar código',
          height: 56,
          expand: true,
          loading: _carregando,
          onPressed: _enviarCodigo,
        ),
      ],
    );
  }

  Widget _etapaCodigo(FinColors c) {
    return Column(
      key: const ValueKey('codigo'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecalho(
          c,
          Icons.mark_email_read,
          'Digite o código',
          'Enviamos um código para $_emailMascarado. Ele vale por 15 minutos.',
        ),
        FinField(
          label: 'Código de 6 dígitos',
          hint: '000000',
          controller: _codigoController,
          icon: Icons.pin,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        const SizedBox(height: 18),
        FinField(
          label: 'Nova senha',
          hint: 'Crie uma senha',
          controller: _senhaController,
          icon: Icons.lock,
          obscure: true,
          helper: 'Mínimo de 6 caracteres',
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: 18),
        FinField(
          label: 'Confirmar nova senha',
          hint: 'Repita a senha',
          controller: _confirmaController,
          icon: Icons.lock,
          obscure: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _redefinir(),
        ),
        const SizedBox(height: 28),
        FinButton(
          label: 'Redefinir senha',
          height: 56,
          expand: true,
          loading: _carregando,
          onPressed: _redefinir,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Não recebeu?', style: FinType.bodyM.copyWith(color: c.textVar)),
            FinButton.text(
              label: _reenviarEm > 0
                  ? 'Reenviar em ${_reenviarEm ~/ 60}:${(_reenviarEm % 60).toString().padLeft(2, '0')}'
                  : 'Reenviar código',
              onPressed: _reenviarEm > 0 || _carregando ? null : _enviarCodigo,
            ),
          ],
        ),
        Center(
          child: FinButton.text(
            label: 'Usar outro e-mail',
            onPressed: _carregando ? null : () => setState(() => _codigoEnviado = false),
          ),
        ),
      ],
    );
  }
}
