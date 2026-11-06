import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'fin_controls.dart';
import 'fin_surface.dart';

/// Snackbar invertida do FinUp (Figma: "Snackbar").
void showFinSnack(
  BuildContext context,
  String mensagem, {
  bool erro = false,
  String? acao,
  VoidCallback? onAcao,
  bool acimaDoFab = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final c = context.fin;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        // Com FAB na tela, a snackbar fica 14px acima dele (como no Figma).
        margin: EdgeInsets.fromLTRB(18, 0, 18, acimaDoFab ? 90 : 14),
        duration: Duration(seconds: acao != null ? 5 : 3),
        content: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: FinFx.diag(
              c.isDark
                  ? const [Color(0xffEEF2FA), Color(0xffD5DCEA)]
                  : const [Color(0xff2B3650), Color(0xff18202F)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 8),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                erro ? Icons.error_outline : Icons.check,
                size: 18,
                color: erro ? c.gCoral[1] : c.invPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    mensagem,
                    style: FinType.bodyM.copyWith(color: c.onInvSurface),
                  ),
                ),
              ),
              if (acao != null)
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onAcao?.call();
                  },
                  child: Text(
                    acao,
                    style: FinType.labelL.copyWith(
                      color: c.invPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
}

/// Diálogo em superfície convexa.
Future<T?> showFinDialog<T>({
  required BuildContext context,
  required String titulo,
  IconData? icone,
  required Widget Function(BuildContext ctx, StateSetter setState) conteudo,
  required List<Widget> Function(BuildContext ctx, StateSetter setState) acoes,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: context.fin.scrim.withValues(alpha: 0.45),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final c = ctx.fin;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: FinSurface.convex(
            depth: 12,
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        if (icone != null) ...[
                          Icon(icone, color: c.primary, size: 24),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            titulo,
                            style: FinType.titleL.copyWith(
                              color: c.text,
                              shadows: FinFx.emboss(c),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: conteudo(ctx, setState),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    children: acoes(ctx, setState),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Confirmação simples (excluir, sair…). Retorna true se confirmou.
Future<bool> finConfirm(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String confirmar,
  bool perigo = true,
}) async {
  final r = await showFinDialog<bool>(
    context: context,
    titulo: titulo,
    conteudo: (ctx, _) => Text(
      mensagem,
      style: FinType.bodyM.copyWith(color: ctx.fin.textVar),
    ),
    acoes: (ctx, _) => [
      FinButton.text(label: 'Cancelar', onPressed: () => Navigator.pop(ctx, false)),
      FinButton.text(
        label: confirmar,
        danger: perigo,
        onPressed: () => Navigator.pop(ctx, true),
      ),
    ],
  );
  return r == true;
}

/// Bottom sheet convexo com alça.
Future<T?> showFinSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext ctx, StateSetter setState) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.fin.scrim.withValues(alpha: 0.45),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final c = ctx.fin;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              gradient: FinFx.diag(c.gConvex),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, -10),
                  blurRadius: 30,
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              gradient: FinFx.gloss(c.isDark ? 0.05 : 0.8, 0.2),
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: FinSurface.pressed(
                          width: 40,
                          height: 5,
                          depth: 1.5,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      builder(ctx, setState),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Linha de opção usada nas folhas de ações.
class SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool perigo;
  final VoidCallback onTap;

  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.perigo = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final cor = perigo ? c.expense : c.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: cor, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: FinType.bodyL.copyWith(color: cor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
