import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/categorias.dart';
import '../core/theme_controller.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_feedback.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';

/// Perfil — aberto pelo avatar da Início.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // ── Editar perfil ────────────────────────────────────────────

  Future<void> _abrirEditarPerfil() async {
    final nomeController = TextEditingController(text: AuthService.nome);
    final emailController = TextEditingController(text: AuthService.email);
    var salvando = false;

    final ok = await showFinDialog<bool>(
      context: context,
      titulo: 'Editar perfil',
      conteudo: (ctx, _) => Column(
        children: [
          FinField(
            label: 'Nome',
            controller: nomeController,
            icon: Icons.person,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          FinField(
            label: 'E-mail',
            controller: emailController,
            icon: Icons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      acoes: (ctx, setD) => [
        FinButton.text(
          label: 'Cancelar',
          onPressed: salvando ? null : () => Navigator.pop(ctx),
        ),
        FinButton.text(
          label: 'Salvar',
          onPressed: salvando
              ? null
              : () async {
                  final nome = nomeController.text.trim();
                  final email = emailController.text.trim();
                  if (nome.isEmpty || email.isEmpty) {
                    showFinSnack(context, 'Preencha nome e e-mail.', erro: true);
                    return;
                  }
                  setD(() => salvando = true);
                  try {
                    await AuthService.atualizarPerfil(nome: nome, email: email);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } on ApiException catch (e) {
                    setD(() => salvando = false);
                    if (mounted) showFinSnack(context, e.message, erro: true);
                  } catch (_) {
                    setD(() => salvando = false);
                    if (mounted) showFinSnack(context, 'Não foi possível atualizar o perfil.', erro: true);
                  }
                },
        ),
      ],
    );
    if (ok == true && mounted) showFinSnack(context, 'Perfil atualizado');
  }

  // ── Alterar senha ────────────────────────────────────────────

  Future<void> _abrirAlterarSenha() async {
    final atualController = TextEditingController();
    final novaController = TextEditingController();
    var salvando = false;

    final ok = await showFinDialog<bool>(
      context: context,
      titulo: 'Alterar senha',
      conteudo: (ctx, _) => Column(
        children: [
          FinField(
            label: 'Senha atual',
            controller: atualController,
            icon: Icons.lock,
            obscure: true,
          ),
          const SizedBox(height: 14),
          FinField(
            label: 'Nova senha',
            controller: novaController,
            icon: Icons.lock,
            obscure: true,
            helper: 'Mínimo de 6 caracteres',
          ),
        ],
      ),
      acoes: (ctx, setD) => [
        FinButton.text(
          label: 'Cancelar',
          onPressed: salvando ? null : () => Navigator.pop(ctx),
        ),
        FinButton.text(
          label: 'Salvar',
          onPressed: salvando
              ? null
              : () async {
                  final atual = atualController.text;
                  final nova = novaController.text;
                  if (atual.isEmpty || nova.isEmpty) {
                    showFinSnack(context, 'Preencha os dois campos.', erro: true);
                    return;
                  }
                  if (nova.length < 6) {
                    showFinSnack(context, 'A nova senha deve ter pelo menos 6 caracteres.',
                        erro: true);
                    return;
                  }
                  setD(() => salvando = true);
                  try {
                    await AuthService.alterarSenha(senhaAtual: atual, novaSenha: nova);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } on ApiException catch (e) {
                    setD(() => salvando = false);
                    if (mounted) showFinSnack(context, e.message, erro: true);
                  } catch (_) {
                    setD(() => salvando = false);
                    if (mounted) showFinSnack(context, 'Não foi possível alterar a senha.', erro: true);
                  }
                },
        ),
      ],
    );
    if (ok == true && mounted) showFinSnack(context, 'Senha alterada');
  }

  // ── Sobre ────────────────────────────────────────────────────

  void _abrirSobre() {
    showFinDialog<void>(
      context: context,
      titulo: 'Sobre o FinUp',
      conteudo: (ctx, _) => Text(
        'Sistema de Gestão Financeira\nVersão 1.0\n\n'
        'Projeto de extensão do curso de Análise e Desenvolvimento de Sistemas.\n\n'
        'Desenvolvido com Flutter, Node.js, Express e SQLite.',
        style: FinType.bodyM.copyWith(color: ctx.fin.textVar),
      ),
      acoes: (ctx, _) => [
        FinButton.text(label: 'Fechar', onPressed: () => Navigator.pop(ctx)),
      ],
    );
  }

  // ── Sair ─────────────────────────────────────────────────────

  Future<void> _confirmarSaida() async {
    final sair = await finConfirm(
      context,
      titulo: 'Sair da conta',
      mensagem: 'Tem certeza que deseja sair?',
      confirmar: 'Sair',
    );
    if (!sair || !mounted) return;
    AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fin;

    return FinScaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([AuthService.usuarioRevisao, ThemeController.mode]),
        builder: (context, _) {
          final escuro = ThemeController.mode.value == ThemeMode.system
              ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
              : ThemeController.mode.value == ThemeMode.dark;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const FinTopBar(title: 'Perfil', lead: Icons.arrow_back),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                  children: [
                    FinAvatar(iniciais: AuthService.iniciais, size: 96),
                    const SizedBox(height: 16),
                    Text(
                      AuthService.nome,
                      textAlign: TextAlign.center,
                      style: FinType.titleL.copyWith(color: c.text, shadows: FinFx.emboss(c)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AuthService.email,
                      textAlign: TextAlign.center,
                      style: FinType.bodyM.copyWith(color: c.textVar),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _titulo(c, 'Conta'),
                    ListCard(
                      inset: 68,
                      rows: [
                        _Opcao(
                          estilo: const EmblemaStyle(
                              Icons.edit, Color(0xff8DB7FF), Color(0xff2F66E0)),
                          titulo: 'Editar perfil',
                          subtitulo: 'Nome e e-mail',
                          onTap: _abrirEditarPerfil,
                        ),
                        _Opcao(
                          estilo: const EmblemaStyle(
                              Icons.lock, Color(0xffC6A2FF), Color(0xff7B4FE0)),
                          titulo: 'Alterar senha',
                          subtitulo: 'Senha de acesso',
                          onTap: _abrirAlterarSenha,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _titulo(c, 'Aparência'),
                    ListCard(
                      inset: 68,
                      rows: [
                        _Opcao(
                          estilo: const EmblemaStyle(
                              Icons.dark_mode, Color(0xff9AA6FF), Color(0xff4A55D6)),
                          titulo: 'Tema escuro',
                          subtitulo: ThemeController.mode.value == ThemeMode.system
                              ? 'Seguindo o sistema'
                              : (escuro ? 'Ativado' : 'Desativado'),
                          onTap: () => ThemeController.definir(
                            escuro ? ThemeMode.light : ThemeMode.dark,
                          ),
                          trailing: FinSwitch(
                            value: escuro,
                            onChanged: (v) => ThemeController.definir(
                              v ? ThemeMode.dark : ThemeMode.light,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _titulo(c, 'Sobre'),
                    ListCard(
                      inset: 68,
                      rows: [
                        _Opcao(
                          estilo: const EmblemaStyle(
                              Icons.info, Color(0xff74E0FA), Color(0xff1A9EC4)),
                          titulo: 'Sobre o FinUp',
                          subtitulo: 'Versão 1.0',
                          onTap: _abrirSobre,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ListCard(
                      inset: 68,
                      rows: [
                        _Opcao(
                          estilo: const EmblemaStyle(
                              Icons.logout, Color(0xffF7A68B), Color(0xffDC7457)),
                          titulo: 'Sair da conta',
                          perigo: true,
                          onTap: _confirmarSaida,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _titulo(FinColors c, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t,
          style: FinType.titleS.copyWith(color: c.textVar, shadows: FinFx.emboss(c)),
        ),
      );
}

class _Opcao extends StatelessWidget {
  final EmblemaStyle estilo;
  final String titulo;
  final String? subtitulo;
  final bool perigo;
  final VoidCallback onTap;
  final Widget? trailing;

  const _Opcao({
    required this.estilo,
    required this.titulo,
    required this.onTap,
    this.subtitulo,
    this.perigo = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Emblem(estilo: estilo, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: FinType.bodyL.copyWith(
                      color: perigo ? c.expense : c.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitulo != null)
                    Text(subtitulo!, style: FinType.bodyM.copyWith(color: c.textVar)),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (!perigo)
              Icon(Icons.chevron_right, size: 22, color: c.textVar),
          ],
        ),
      ),
    );
  }
}
