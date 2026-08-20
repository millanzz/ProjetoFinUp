import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_routes.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/skeu_input.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  void _mostrarMensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? AppTheme.dangerRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ── Editar perfil ────────────────────────────────────────────

  void _abrirEditarPerfil() {
    final nomeController = TextEditingController(text: AuthService.nome);
    final emailController = TextEditingController(text: AuthService.email);
    bool salvando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "Editar perfil",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeuInput(
                label: "Nome",
                controller: nomeController,
              ),
              const SizedBox(height: 14),
              SkeuInput(
                label: "E-mail",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: salvando ? null : () => Navigator.pop(ctx),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: AppTheme.coolGray),
              ),
            ),
            TextButton(
              onPressed: salvando
                  ? null
                  : () async {
                      final nome = nomeController.text.trim();
                      final email = emailController.text.trim();

                      if (nome.isEmpty || email.isEmpty) {
                        _mostrarMensagem(
                          "Preencha nome e e-mail.",
                          erro: true,
                        );
                        return;
                      }

                      setDialogState(() => salvando = true);

                      try {
                        await AuthService.atualizarPerfil(
                          nome: nome,
                          email: email,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) setState(() {});
                        _mostrarMensagem("Perfil atualizado!");
                      } on ApiException catch (e) {
                        setDialogState(() => salvando = false);
                        _mostrarMensagem(e.message, erro: true);
                      } catch (_) {
                        setDialogState(() => salvando = false);
                        _mostrarMensagem(
                          "Não foi possível atualizar o perfil.",
                          erro: true,
                        );
                      }
                    },
              child: const Text(
                "Salvar",
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Alterar senha ────────────────────────────────────────────

  void _abrirAlterarSenha() {
    final senhaAtualController = TextEditingController();
    final novaSenhaController = TextEditingController();
    bool salvando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "Alterar senha",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeuInput(
                label: "Senha atual",
                controller: senhaAtualController,
                obscureText: true,
              ),
              const SizedBox(height: 14),
              SkeuInput(
                label: "Nova senha",
                hint: "Mínimo de 6 caracteres",
                controller: novaSenhaController,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: salvando ? null : () => Navigator.pop(ctx),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: AppTheme.coolGray),
              ),
            ),
            TextButton(
              onPressed: salvando
                  ? null
                  : () async {
                      final senhaAtual = senhaAtualController.text;
                      final novaSenha = novaSenhaController.text;

                      if (senhaAtual.isEmpty || novaSenha.isEmpty) {
                        _mostrarMensagem(
                          "Preencha os dois campos.",
                          erro: true,
                        );
                        return;
                      }
                      if (novaSenha.length < 6) {
                        _mostrarMensagem(
                          "A nova senha deve ter pelo menos 6 caracteres.",
                          erro: true,
                        );
                        return;
                      }

                      setDialogState(() => salvando = true);

                      try {
                        await AuthService.alterarSenha(
                          senhaAtual: senhaAtual,
                          novaSenha: novaSenha,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _mostrarMensagem("Senha alterada com sucesso!");
                      } on ApiException catch (e) {
                        setDialogState(() => salvando = false);
                        _mostrarMensagem(e.message, erro: true);
                      } catch (_) {
                        setDialogState(() => salvando = false);
                        _mostrarMensagem(
                          "Não foi possível alterar a senha.",
                          erro: true,
                        );
                      }
                    },
              child: const Text(
                "Salvar",
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sobre ────────────────────────────────────────────────────

  void _abrirSobre() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          "Sobre o app",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        content: const Text(
          "Sistema de Gestão Financeira\nVersão 1.0.0\n\n"
          "Projeto de extensão do curso de Análise e "
          "Desenvolvimento de Sistemas.\n\n"
          "Desenvolvido com Flutter, Node.js, Express e SQLite.",
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.mediumText,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Fechar",
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sair ─────────────────────────────────────────────────────

  void _confirmarSaida() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Sair da conta",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        content: const Text(
          "Tem certeza que deseja sair?",
          style: TextStyle(color: AppTheme.mediumText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: AppTheme.coolGray),
            ),
          ),
          TextButton(
            onPressed: () {
              AuthService.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text(
              "Sair",
              style: TextStyle(
                color: AppTheme.dangerRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Perfil",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // Card do usuário
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.4),
                      offset: const Offset(0, 8),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AuthService.iniciais,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AuthService.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AuthService.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                "Configurações",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.cardLightGradient,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Column(
                  children: [
                    _opcao(
                      Icons.person_outline_rounded,
                      "Editar perfil",
                      "Nome e e-mail",
                      _abrirEditarPerfil,
                    ),
                    _divisor(),
                    _opcao(
                      Icons.lock_outline_rounded,
                      "Alterar senha",
                      "Atualize sua senha de acesso",
                      _abrirAlterarSenha,
                    ),
                    _divisor(),
                    _opcao(
                      Icons.info_outline_rounded,
                      "Sobre o app",
                      "Versão e informações do projeto",
                      _abrirSobre,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Botão sair
              GestureDetector(
                onTap: _confirmarSaida,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardLightGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.dangerRed.withOpacity(0.3),
                    ),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: AppTheme.dangerRed,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Sair da conta",
                        style: TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divisor() => Divider(
        height: 1,
        indent: 20,
        endIndent: 20,
        color: AppTheme.silverMist.withOpacity(0.4),
      );

  Widget _opcao(
    IconData icon,
    String titulo,
    String subtitulo,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.12),
                    AppTheme.primaryBlue.withOpacity(0.22),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.coolGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.coolGray,
            ),
          ],
        ),
      ),
    );
  }
}
