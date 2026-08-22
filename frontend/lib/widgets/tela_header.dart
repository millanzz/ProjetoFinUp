import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Cabeçalho padrão das telas.
///
/// O botão de voltar aparece **automaticamente** quando a tela foi
/// empilhada (`Navigator.canPop == true`) e some quando ela está sendo
/// exibida como aba do [MainNavigationScreen]. Assim a mesma tela serve
/// aos dois casos sem ficar com um "voltar" que não leva a lugar nenhum.
class TelaHeader extends StatelessWidget {
  final String titulo;

  /// Widget opcional alinhado à direita (ex.: botão "Nova meta").
  final Widget? acao;

  /// Força o botão de voltar mesmo que `canPop` seja falso.
  final bool forcarVoltar;

  /// Chamado no lugar do `Navigator.pop` padrão, se informado.
  final VoidCallback? aoVoltar;

  const TelaHeader({
    super.key,
    required this.titulo,
    this.acao,
    this.forcarVoltar = false,
    this.aoVoltar,
  });

  @override
  Widget build(BuildContext context) {
    final podeVoltar = forcarVoltar || Navigator.of(context).canPop();

    return Row(
      children: [
        if (podeVoltar) ...[
          GestureDetector(
            onTap: aoVoltar ?? () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.cardLightGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.8)),
                boxShadow: AppTheme.softShadow,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.darkText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (acao != null) acao!,
      ],
    );
  }
}
