import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/neu.dart';
import 'neu_surface.dart';

/// Card padrão do app. API preservada — agora com relevo, bisel e grão.
class SkeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Novos (opcionais): permitem variar o relevo sem criar outro widget.
  final NeuShape shape;
  final double depth;
  final double radius;
  final VoidCallback? onTap;

  const SkeuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin,
    this.shape = NeuShape.convex,
    this.depth = AppTheme.depthMd,
    this.radius = AppTheme.cardRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      margin: margin,
      padding: padding,
      shape: shape,
      depth: depth,
      radius: radius,
      onTap: onTap,
      child: child,
    );
  }
}
