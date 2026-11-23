// Testes unitários dos cálculos feitos no app (Flutter):
// saldo do mês (SaldoCard), progresso de metas (MetaModel) e
// leitura de valores vindos da API (LancamentoModel / MetaModel).
//
// Roda a partir da pasta frontend:  flutter test ../testes/01-unitarios-calculos/frontend/calculos_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:FinUp/core/app_theme.dart';
import 'package:FinUp/core/formatters.dart';
import 'package:FinUp/models/lancamento_model.dart';
import 'package:FinUp/models/meta_model.dart';
import 'package:FinUp/widgets/saldo_card.dart';

LancamentoModel _l(double valor, TipoLancamento tipo, int dia) => LancamentoModel(
      titulo: 'x',
      valor: valor,
      data: DateTime(2026, 11, dia),
      tipo: tipo,
    );

const _r = TipoLancamento.receita;
const _d = TipoLancamento.despesa;

Future<void> _pumpSaldo(WidgetTester t, List<LancamentoModel> ls) async {
  await t.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SaldoCard(mes: DateTime(2026, 11), lancamentosDoMes: ls)),
  ));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Saldo do mês (SaldoCard)', () {
    testWidgets('CT-FE-SAL-01 sem lançamentos mostra R\$ 0,00', (t) async {
      await _pumpSaldo(t, []);
      expect(find.text('R\$ 0,00'), findsWidgets);
      expect(find.text('Saldo de novembro'), findsOneWidget);
    });

    testWidgets('CT-FE-SAL-02 saldo = entradas − saídas (R\$ 6.500,50 − R\$ 1.500,25)', (t) async {
      await _pumpSaldo(t, [
        _l(5000, _r, 5),
        _l(1500.50, _r, 10),
        _l(1200, _d, 6),
        _l(300.25, _d, 7),
      ]);
      expect(find.text('R\$ 5.000,25'), findsOneWidget); // saldo
      expect(find.text('R\$ 6.500,50'), findsOneWidget); // entradas
      expect(find.text('R\$ 1.500,25'), findsOneWidget); // saídas
    });

    testWidgets('CT-FE-SAL-03 saldo negativo exibe sinal de menos', (t) async {
      await _pumpSaldo(t, [_l(1000, _r, 1), _l(1500.75, _d, 2)]);
      expect(find.text('−R\$ 500,75'), findsOneWidget);
    });

    testWidgets('CT-FE-SAL-04 saldo zerado por centavos não aparece como negativo', (t) async {
      // 0,10 + 0,20 − 0,30 deveria ser exatamente zero
      await _pumpSaldo(t, [_l(0.1, _r, 1), _l(0.2, _r, 2), _l(0.3, _d, 3)]);
      expect(find.text('−R\$ 0,00'), findsNothing,
          reason: 'saldo zero não deve ser exibido como "−R\$ 0,00"');
      expect(find.text('R\$ 0,00'), findsOneWidget);
    });

    testWidgets('CT-FE-SAL-05 saldo zerado por centavos (ordem inversa) não aparece como negativo', (t) async {
      // 0,30 − (0,10 + 0,20) também deveria ser exatamente zero
      await _pumpSaldo(t, [_l(0.3, _r, 1), _l(0.1, _d, 2), _l(0.2, _d, 3)]);
      expect(find.text('−R\$ 0,00'), findsNothing,
          reason: 'saldo zero não deve ser exibido como "−R\$ 0,00"');
    });
  });

  group('Progresso de metas (MetaModel)', () {
    test('CT-FE-MET-01 progresso = guardado / alvo (R\$ 250 de R\$ 1.000 = 25%)', () {
      final m = MetaModel(titulo: 'm', valorAtual: 250, valorMeta: 1000);
      expect(m.progresso, 0.25);
      expect(m.concluida, isFalse);
    });

    test('CT-FE-MET-02 alvo zero não divide por zero (progresso 0)', () {
      expect(MetaModel(titulo: 'm', valorAtual: 50, valorMeta: 0).progresso, 0);
    });

    test('CT-FE-MET-03 meta concluída ao atingir ou ultrapassar o alvo', () {
      expect(MetaModel(titulo: 'm', valorAtual: 1000, valorMeta: 1000).concluida, isTrue);
      final passou = MetaModel(titulo: 'm', valorAtual: 1200, valorMeta: 1000);
      expect(passou.concluida, isTrue);
      expect(passou.progresso, closeTo(1.2, 1e-9));
      // o card limita a 100% na exibição
      expect((passou.progresso.clamp(0.0, 1.0) * 100).round(), 100);
    });

    test('CT-FE-MET-04 fromApi trata current_amount nulo como 0 e inteiros como double', () {
      final m = MetaModel.fromApi({'id': 7, 'title': 'Viagem', 'target_amount': 5000, 'current_amount': null, 'icon': 'flight'});
      expect(m.valorAtual, 0.0);
      expect(m.valorMeta, 5000.0);
      expect(m.progresso, 0);
    });

    test('CT-FE-MET-05 aportes de centavos concluem a meta (0,10 + 0,20 ≥ 0,30)', () {
      final m = MetaModel(titulo: 'm', valorAtual: 0.1 + 0.2, valorMeta: 0.3);
      expect(m.concluida, isTrue);
      expect(m.progresso, closeTo(1.0, 1e-9));
    });
  });

  group('Valores de receitas e despesas no app', () {
    test('CT-FE-LAN-01 fromApi converte amount inteiro/decimal e identifica o tipo', () {
      final r = LancamentoModel.fromApi({'id': 1, 'amount': 4500, 'date': '2026-11-05', 'description': 'Salário'}, _r);
      final d = LancamentoModel.fromApi({'id': 2, 'amount': 33.34, 'date': '2026-01-31', 'category_name': 'Mercado', 'parcela_grupo': 'g', 'parcela_numero': 1, 'parcela_total': 3}, _d);
      expect(r.valor, 4500.0);
      expect(r.isReceita, isTrue);
      expect(d.valor, 33.34);
      expect(d.isReceita, isFalse);
      expect(d.titulo, 'Mercado');
      expect(d.rotuloParcela, 'Parcela 1/3');
    });

    test('CT-FE-LAN-02 divisão de parcelas no app bate com o backend (R\$ 100 em 3x)', () {
      expect(Fmt.dividirParcelas(100, 3), [33.34, 33.33, 33.33]);
      final soma = Fmt.dividirParcelas(1999.99, 12).fold<int>(0, (s, v) => s + (v * 100).round());
      expect(soma, 199999);
    });

    test('CT-FE-LAN-03 toApiJson envia o valor e a data no formato do backend', () {
      final l = LancamentoModel(titulo: 'Aluguel', valor: 1200.5, data: DateTime(2026, 2, 3), tipo: _d);
      final j = l.toApiJson(categoryId: 4, parcelas: 1);
      expect(j['amount'], 1200.5);
      expect(j['date'], '2026-02-03');
      expect(j.containsKey('parcelas'), isFalse);
    });
  });
}
