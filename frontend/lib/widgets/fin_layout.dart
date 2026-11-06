import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import 'fin_controls.dart';
import 'fin_surface.dart';

/// Barra superior (64px): ícone à esquerda, título e ações.
class FinTopBar extends StatelessWidget {
  final String title;
  final IconData? lead;
  final VoidCallback? onLead;
  final List<Widget> actions;

  const FinTopBar({
    super.key,
    this.title = '',
    this.lead,
    this.onLead,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (lead != null) ...[
              FinIconButton(
                icon: lead!,
                onTap: onLead ?? () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FinType.titleL.copyWith(
                  color: c.text,
                  shadows: FinFx.emboss(c),
                ),
              ),
            ),
            for (final a in actions) ...[const SizedBox(width: 12), a],
          ],
        ),
      ),
    );
  }
}

/// Título de seção (Title M) com ação de texto opcional.
class SectionHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHead({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: FinType.titleM.copyWith(color: c.text, shadows: FinFx.emboss(c)),
            ),
          ),
          if (action != null) FinButton.text(label: action!, onPressed: onAction),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Divisor "sulco": linha escura + linha clara (relevo).
class Groove extends StatelessWidget {
  final double inset;

  const Groove({super.key, this.inset = 72});

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return Padding(
      padding: EdgeInsets.only(left: inset, right: 16),
      child: Column(
        children: [
          Container(
            height: 1,
            color: (c.isDark ? c.shadowDark : c.outlineVar).withValues(alpha: 0.9),
          ),
          Container(
            height: 1,
            color: c.isDark
                ? const Color(0xff2B3B5E).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.95),
          ),
        ],
      ),
    );
  }
}

/// Card convexo com linhas separadas por sulcos.
class ListCard extends StatelessWidget {
  final List<Widget> rows;
  final double inset;

  const ListCard({super.key, required this.rows, this.inset = 72});

  @override
  Widget build(BuildContext context) {
    return FinSurface.convex(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) Groove(inset: inset),
          ],
        ],
      ),
    );
  }
}

/// Linha "categoria": emblema, nome, % e valor, barra de progresso.
class CatRow extends StatelessWidget {
  final String categoria;
  final double valor;
  final double total;
  final FinTone tone;

  const CatRow({
    super.key,
    required this.categoria,
    required this.valor,
    required this.total,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final frac = total <= 0 ? 0.0 : valor / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Emblem.categoria(categoria, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoria,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FinType.bodyL.copyWith(color: c.text),
                      ),
                    ),
                    Text('${(frac * 100).round()}%',
                        style: FinType.labelM.copyWith(color: c.textVar)),
                    const SizedBox(width: 8),
                    Text(Fmt.brl(valor), style: FinType.titleS.copyWith(color: c.text)),
                  ],
                ),
                const SizedBox(height: 8),
                FinProgress(value: frac, tone: tone, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de lançamento: emblema, descrição, subtítulo e valor colorido.
class LancRow extends StatelessWidget {
  final LancamentoModel lancamento;
  final String? subtitulo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const LancRow({
    super.key,
    required this.lancamento,
    this.subtitulo,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final l = lancamento;
    final sub = subtitulo ??
        '${l.categoria ?? 'Sem categoria'} · ${Fmt.dataCurta(l.data)}'
            '${l.parcelado ? ' · Parcelado' : ''}';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Emblem.categoria(l.categoria, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FinType.bodyL.copyWith(
                      color: c.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FinType.bodyM.copyWith(color: c.textVar),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${l.isReceita ? '+' : '−'} ${Fmt.brl(l.valor)}',
              style: FinType.titleS.copyWith(
                color: l.isReceita ? c.income : c.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio dentro de um card convexo.
class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Widget? acao;

  const EmptyCard({super.key, required this.icon, required this.texto, this.acao});

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return FinSurface.convex(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: FinSurface.pressed(
              width: 64,
              height: 64,
              depth: 4,
              borderRadius: BorderRadius.circular(32),
              alignment: Alignment.center,
              child: Icon(icon, color: c.textVar, size: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: FinType.bodyM.copyWith(color: c.textVar),
          ),
          if (acao != null) ...[const SizedBox(height: 12), Center(child: acao!)],
        ],
      ),
    );
  }
}

/// Chip de mês/ano ("Out 2026 ⌄").
class MonthChip extends StatelessWidget {
  final DateTime? mes;
  final VoidCallback onTap;

  const MonthChip({super.key, required this.mes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return FinSurface.convex(
      height: 36,
      depth: 4,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.only(left: 14, right: 10),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mes == null ? 'Tudo' : Fmt.mesAno(mes!),
            style: FinType.labelL.copyWith(color: c.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, size: 18, color: c.text),
        ],
      ),
    );
  }
}

/// Botão flutuante estendido (Nova receita / Nova despesa / Nova meta).
class FinFab extends StatelessWidget {
  final String label;
  final FinTone tone;
  final VoidCallback onTap;

  const FinFab({
    super.key,
    required this.label,
    required this.onTap,
    this.tone = FinTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2, bottom: 2),
      child: FinSurface.colored(
        tone: tone,
        height: 58,
        depth: 12,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.only(left: 18, right: 22),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 24, color: Colors.white, shadows: FinFx.textOnColor(0.25)),
            const SizedBox(width: 10),
            Text(
              label,
              style: FinType.labelL.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: FinFx.textOnColor(0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de navegação.
class FinNavItem {
  final String label;
  final IconData icon;

  const FinNavItem(this.label, this.icon);
}

/// Barra de navegação inferior de 5 abas.
class FinNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<FinNavItem> items;

  const FinNavBar({
    super.key,
    required this.index,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return Container(
      decoration: BoxDecoration(
        gradient: FinFx.diag(c.gConvex),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: c.isDark ? 0.12 : 0.95),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xff1D4ED8).withValues(alpha: 0.10),
            offset: const Offset(0, -6),
            blurRadius: 18,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        gradient: FinFx.gloss(c.isDark ? 0.05 : 0.8, 0.35),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _item(context, i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i) {
    final c = context.fin;
    final sel = i == index;
    final it = items[i];
    return Semantics(
      selected: sel,
      button: true,
      label: it.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 34,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: sel
                    ? FinSurface.colored(
                        key: const ValueKey('sel'),
                        width: 56,
                        height: 34,
                        depth: 4,
                        borderRadius: BorderRadius.circular(17),
                        alignment: Alignment.center,
                        child: Icon(it.icon,
                            size: 22,
                            color: Colors.white,
                            shadows: FinFx.textOnColor(0.25)),
                      )
                    : Center(
                        key: const ValueKey('off'),
                        child: Icon(it.icon, size: 22, color: c.textVar),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              it.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FinType.labelM.copyWith(
                color: sel ? c.primary : c.textVar,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
