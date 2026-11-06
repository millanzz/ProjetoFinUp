import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import '../screens/lancamento_form_screen.dart';
import '../services/lancamento_service.dart';
import 'fin_feedback.dart';
import 'fin_surface.dart';

/// Fluxos de lançamento usados em várias telas.
class LancamentoAcoes {
  LancamentoAcoes._();

  /// Abre o formulário de criação e, ao salvar, mostra a snackbar
  /// "Despesa salva · Desfazer".
  static Future<void> novo(
    BuildContext context,
    TipoLancamento tipo, {
    bool acimaDoFab = false,
  }) async {
    final criado = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (_) => LancamentoFormScreen(tipo: tipo)),
    );
    if (criado is! LancamentoModel || !context.mounted) return;

    showFinSnack(
      context,
      criado.isReceita ? 'Receita salva' : 'Despesa salva',
      acao: 'Desfazer',
      acimaDoFab: acimaDoFab,
      onAcao: () async {
        try {
          await LancamentoService.remover(criado);
        } catch (_) {
          if (context.mounted) {
            showFinSnack(context, 'Não foi possível desfazer.', erro: true);
          }
        }
      },
    );
  }

  static Future<void> editar(BuildContext context, LancamentoModel l) async {
    final ok = await LancamentoFormScreen.abrirEdicao(context, l);
    if (ok == true && context.mounted) {
      showFinSnack(context, 'Lançamento atualizado');
    }
  }

  static Future<void> excluir(BuildContext context, LancamentoModel l) async {
    final confirmar = await finConfirm(
      context,
      titulo: 'Excluir lançamento',
      mensagem: 'Deseja excluir "${l.titulo}" (${Fmt.brl(l.valor)})?',
      confirmar: 'Excluir',
    );
    if (!confirmar || !context.mounted) return;

    try {
      await LancamentoService.remover(l);
      if (context.mounted) showFinSnack(context, 'Lançamento excluído');
    } catch (_) {
      if (context.mounted) {
        showFinSnack(context, 'Não foi possível excluir. Tente novamente.', erro: true);
      }
    }
  }

  /// Folha com Editar / Excluir.
  static Future<void> menu(BuildContext context, LancamentoModel l) {
    return showFinSheet<void>(
      context: context,
      builder: (ctx, _) {
        final c = ctx.fin;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Emblem.categoria(l.categoria, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FinType.titleM.copyWith(color: c.text),
                      ),
                      Text(
                        '${l.isReceita ? '+' : '−'} ${Fmt.brl(l.valor)} · ${Fmt.dataCurta(l.data)}',
                        style: FinType.bodyM.copyWith(color: c.textVar),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SheetAction(
              icon: Icons.edit,
              label: 'Editar lançamento',
              onTap: () {
                Navigator.pop(ctx);
                editar(context, l);
              },
            ),
            SheetAction(
              icon: Icons.delete_outline,
              label: 'Excluir lançamento',
              perigo: true,
              onTap: () {
                Navigator.pop(ctx);
                excluir(context, l);
              },
            ),
          ],
        );
      },
    );
  }
}
