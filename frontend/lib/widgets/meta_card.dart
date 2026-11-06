import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/meta_model.dart';
import 'fin_controls.dart';
import 'fin_surface.dart';

/// Card de meta: emblema, título, progresso e ação de aporte.
class MetaCard extends StatelessWidget {
  final MetaModel meta;
  final bool compact;
  final VoidCallback? onAporte;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MetaCard({
    super.key,
    required this.meta,
    this.compact = false,
    this.onAporte,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final p = meta.progresso;
    final done = meta.concluida;

    return FinSurface.convex(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Emblem.meta(meta.icone, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FinType.titleM.copyWith(color: c.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Fmt.brl(meta.valorAtual)} de ${Fmt.brl(meta.valorMeta)}',
                      style: FinType.bodyM.copyWith(color: c.textVar),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(p.clamp(0.0, 1.0) * 100).round()}%',
                style: FinType.titleS.copyWith(
                  color: done ? c.done : c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FinProgress(value: p, tone: done ? FinTone.green : FinTone.primary),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                if (done) ...[
                  Icon(Icons.check, size: 18, color: c.done),
                  const SizedBox(width: 6),
                  Text(
                    'Meta concluída',
                    style: FinType.labelL.copyWith(color: c.done, fontWeight: FontWeight.w700),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      'Faltam ${Fmt.brl(meta.valorMeta - meta.valorAtual)}',
                      style: FinType.bodyM.copyWith(color: c.textVar),
                    ),
                  ),
                  if (!compact && onAporte != null)
                    FinButton.text(
                      label: 'Adicionar aporte',
                      icon: Icons.add,
                      onPressed: onAporte,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
