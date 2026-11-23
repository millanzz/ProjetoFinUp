import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import 'fin_surface.dart';

/// Card de saldo da Início: saldo do mês, linha do saldo diário e
/// caixas de Entradas / Saídas.
class SaldoCard extends StatelessWidget {
  final DateTime mes;
  final List<LancamentoModel> lancamentosDoMes;

  const SaldoCard({super.key, required this.mes, required this.lancamentosDoMes});

  @override
  Widget build(BuildContext context) {
    final entradas = lancamentosDoMes
        .where((l) => l.isReceita)
        .fold<double>(0, (s, l) => s + l.valor);
    final saidas = lancamentosDoMes
        .where((l) => !l.isReceita)
        .fold<double>(0, (s, l) => s + l.valor);
    // Arredonda para centavos: evita resíduo de ponto flutuante e "−R$ 0,00" (DEF-01/02)
    final saldo = Fmt.centavos(entradas - saidas);

    final diasNoMes = DateTime(mes.year, mes.month + 1, 0).day;
    final pontos = <double>[];
    var acumulado = 0.0;
    for (var d = 1; d <= diasNoMes; d++) {
      for (final l in lancamentosDoMes.where((l) => l.data.day == d)) {
        acumulado += l.isReceita ? l.valor : -l.valor;
      }
      pontos.add(acumulado);
    }

    final branco = FinType.labelS.copyWith(color: Colors.white.withValues(alpha: 0.75));
    final mesCurto = Fmt.mesesCurtos[mes.month - 1];

    return FinGradCard(
      tone: FinTone.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: FinFx.diag([
                    Colors.white.withValues(alpha: 0.34),
                    Colors.white.withValues(alpha: 0.12),
                  ]),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              // Flexible: com fonte grande o texto quebra em vez de estourar (DEF-12)
              Flexible(
                child: Text(
                  'Saldo de ${Fmt.meses[mes.month - 1]}',
                  style: FinType.bodyM.copyWith(
                    color: const Color(0xffEEF4FF),
                    shadows: FinFx.textOnColor(0.45),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${saldo < 0 ? '−' : ''}${Fmt.brl(saldo)}',
              style: FinType.displayS.copyWith(
                color: Colors.white,
                shadows: FinFx.textOnColor(0.35),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: CustomPaint(painter: _SaldoDiarioPainter(pontos)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 $mesCurto', style: branco),
              Text('$diasNoMes $mesCurto', style: branco),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Caixa(
                  label: 'Entradas',
                  valor: entradas,
                  icon: Icons.arrow_downward,
                  iconColor: const Color(0xffD6E6FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Caixa(
                  label: 'Saídas',
                  valor: saidas,
                  icon: Icons.arrow_upward,
                  iconColor: const Color(0xffFFD3C4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Caixa extends StatelessWidget {
  final String label;
  final double valor;
  final IconData icon;
  final Color iconColor;

  const _Caixa({
    required this.label,
    required this.valor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: FinType.bodyS.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.brl(valor),
              style: FinType.titleM.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: FinFx.textOnColor(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha do saldo acumulado dia a dia, com área em degradê.
class _SaldoDiarioPainter extends CustomPainter {
  final List<double> pontos;

  _SaldoDiarioPainter(this.pontos);

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;
    final cw = size.width, ch = size.height;
    final maxV = pontos.reduce(math.max);
    final minV = math.min(0.0, pontos.reduce(math.min));
    final faixa = (maxV - minV).abs() < 0.01 ? 1.0 : maxV - minV;
    final base = ch - 6;

    final xy = <Offset>[
      for (var i = 0; i < pontos.length; i++)
        Offset(
          i / (pontos.length - 1) * cw,
          base - ((pontos[i] - minV) / faixa) * (ch - 14),
        ),
    ];

    final linha = Path()..moveTo(xy.first.dx, xy.first.dy);
    for (final p in xy.skip(1)) {
      linha.lineTo(p.dx, p.dy);
    }
    final area = Path.from(linha)
      ..lineTo(cw, base)
      ..lineTo(0, base)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );

    final traco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      linha.shift(const Offset(0, 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xff0B2A7A).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(linha, traco..color = Colors.white);

    final ultimo = xy.last;
    canvas.drawCircle(
      ultimo,
      8,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(ultimo, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SaldoDiarioPainter old) => old.pontos != pontos;
}
