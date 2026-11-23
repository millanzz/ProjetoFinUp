import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import 'fin_surface.dart';

enum FinButtonKind { primary, coral, soft, text, danger }

/// Botões do sistema: principal (azul), coral, suave (convexo) e texto.
class FinButton extends StatelessWidget {
  final FinButtonKind kind;
  final String label;
  final IconData? icon;
  final double height;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  const FinButton({
    super.key,
    required this.label,
    this.kind = FinButtonKind.primary,
    this.icon,
    this.height = 52,
    this.onPressed,
    this.loading = false,
    this.expand = false,
  });

  const FinButton.text({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 40,
    bool danger = false,
  })  : kind = danger ? FinButtonKind.danger : FinButtonKind.text,
        loading = false,
        expand = false;

  bool get _colored => kind == FinButtonKind.primary || kind == FinButtonKind.coral;

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final disabled = onPressed == null || loading;

    if (kind == FinButtonKind.text || kind == FinButtonKind.danger) {
      final fg = kind == FinButtonKind.danger ? c.expense : c.primary;
      return Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: FinType.labelL.copyWith(color: fg)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final fg = _colored ? Colors.white : c.primary;
    final textStyle = _colored
        ? FinType.titleS.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            shadows: FinFx.textOnColor(0.35),
          )
        : FinType.labelL.copyWith(color: c.primary, fontWeight: FontWeight.w700);

    final content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: fg,
                  shadows: _colored ? FinFx.textOnColor(0.2) : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final radius = BorderRadius.circular(height / 2 < 18 ? height / 2 : 18);
    final padding = EdgeInsets.only(
      left: icon != null ? 18 : 26,
      right: icon != null ? 22 : 26,
    );

    final surface = _colored
        ? FinSurface.colored(
            tone: kind == FinButtonKind.coral ? FinTone.coral : FinTone.primary,
            height: height,
            borderRadius: radius,
            padding: padding,
            alignment: expand ? Alignment.center : null,
            onTap: disabled ? null : onPressed,
            child: Center(widthFactor: 1, child: content),
          )
        : FinSurface.convex(
            depth: 6,
            height: height,
            borderRadius: radius,
            padding: padding,
            alignment: expand ? Alignment.center : null,
            onTap: disabled ? null : onPressed,
            child: Center(widthFactor: 1, child: content),
          );

    return Opacity(
      opacity: onPressed == null && !loading ? 0.6 : 1,
      child: expand ? SizedBox(width: double.infinity, child: surface) : surface,
    );
  }
}

/// Botão de ícone 44×44 convexo (voltar, fechar).
class FinIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const FinIconButton({super.key, required this.icon, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final btn = FinSurface.convex(
      width: 44,
      height: 44,
      depth: 4,
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: context.fin.text),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Campo côncavo com rótulo interno (Figma: "Campo").
class FinField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? helper;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final List<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  const FinField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.helper,
    this.textInputAction,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
  });

  @override
  State<FinField> createState() => _FinFieldState();
}

class _FinFieldState extends State<FinField> {
  final _focus = FocusNode();
  late bool _oculto = widget.obscure;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    final focado = _focus.hasFocus;
    final cor = focado ? c.primary : c.textVar;

    final campo = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: focado
            ? [
                BoxShadow(
                  color: const Color(0xff3B82F6).withValues(alpha: 0.28),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      // Altura mínima (e não fixa) de 58: com a fonte do sistema ampliada o
      // campo cresce em vez de cortar o texto (DEF-12).
      child: FinSurface.pressed(
        borderRadius: BorderRadius.circular(16),
        padding: EdgeInsets.fromLTRB(widget.icon != null ? 14 : 18, 9, 16, 9),
        onTap: () => _focus.requestFocus(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 22, color: cor),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: FinType.bodyS.copyWith(
                      color: cor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    obscureText: _oculto,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    onSubmitted: widget.onSubmitted,
                    textCapitalization: widget.textCapitalization,
                    autofillHints: widget.autofillHints,
                    inputFormatters: widget.inputFormatters,
                    style: FinType.bodyL.copyWith(color: c.text),
                    cursorColor: c.primary,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: FinType.bodyL.copyWith(color: c.textVar),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.obscure)
              GestureDetector(
                onTap: () => setState(() => _oculto = !_oculto),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    _oculto ? Icons.visibility : Icons.visibility_off,
                    size: 22,
                    color: c.textVar,
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );

    if (widget.helper == null) return campo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        campo,
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(widget.helper!, style: FinType.bodyS.copyWith(color: c.textVar)),
        ),
      ],
    );
  }
}

/// Campo côncavo que abre um seletor (ex.: data).
class FinPickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const FinPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    // Altura mínima (e não fixa): com fonte ampliada o campo cresce (DEF-12)
    return FinSurface.pressed(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.fromLTRB(14, 9, 16, 9),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
        children: [
          Icon(icon, size: 22, color: c.textVar),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: FinType.bodyS.copyWith(
                        color: c.textVar, fontWeight: FontWeight.w500)),
                Text(value, style: FinType.bodyL.copyWith(color: c.text)),
              ],
            ),
          ),
          Icon(Icons.expand_more, size: 22, color: c.textVar),
        ],
      ),
      ),
    );
  }
}

/// Chip de filtro (selecionado = azul com check).
class FinChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const FinChip({super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    const r = BorderRadius.all(Radius.circular(12));
    if (selected) {
      return FinSurface.colored(
        height: 34,
        depth: 4,
        borderRadius: r,
        padding: const EdgeInsets.only(left: 10, right: 14),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: FinType.labelL.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: FinFx.textOnColor(0.2),
              ),
            ),
          ],
        ),
      );
    }
    return FinSurface.convex(
      height: 34,
      depth: 4,
      borderRadius: r,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: onTap,
      child: Center(
        widthFactor: 1,
        child: Text(label, style: FinType.labelL.copyWith(color: c.textVar)),
      ),
    );
  }
}

/// Caixa de seleção 22×22 em relevo.
class FinCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const FinCheckbox({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.all(Radius.circular(7));
    return value
        ? FinSurface.colored(
            width: 22,
            height: 22,
            depth: 3,
            borderRadius: r,
            alignment: Alignment.center,
            onTap: () => onChanged(false),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          )
        : FinSurface.pressed(
            width: 22,
            height: 22,
            depth: 2,
            borderRadius: r,
            onTap: () => onChanged(true),
          );
  }
}

/// Interruptor: trilho côncavo com botão convexo.
class FinSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const FinSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: SizedBox(
        width: 54,
        height: 32,
        child: Stack(
          children: [
            FinSurface.pressed(
              width: 54,
              height: 32,
              depth: 3,
              borderRadius: BorderRadius.circular(16),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              left: value ? 26 : 4,
              top: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: FinFx.diag(value ? c.gPrimary : c.gConvex),
                  boxShadow: value
                      ? FinFx.glow(c, FinColors.glowOf(FinTone.primary), 3)
                      : FinFx.raised(c, 3),
                ),
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: FinFx.gloss(c.isDark && !value ? 0.08 : 0.5, 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar circular azul com as iniciais.
class FinAvatar extends StatelessWidget {
  final String iniciais;
  final double size;
  final VoidCallback? onTap;

  const FinAvatar({super.key, required this.iniciais, this.size = 44, this.onTap});

  @override
  Widget build(BuildContext context) {
    final grande = size >= 80;
    return FinSurface.colored(
      width: size,
      height: size,
      depth: grande ? 12 : 5,
      borderRadius: BorderRadius.circular(size / 2),
      alignment: Alignment.center,
      onTap: onTap,
      child: Text(
        iniciais,
        style: (grande ? FinType.headlineL : FinType.labelL).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          shadows: FinFx.textOnColor(grande ? 0.3 : 0.25),
        ),
      ),
    );
  }
}
