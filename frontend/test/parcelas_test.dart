import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/core/formatters.dart';
import 'package:FinUp/models/lancamento_model.dart';

void main() {
  group('Fmt.dividirParcelas', () {
    test('divisão exata', () {
      expect(Fmt.dividirParcelas(1200, 12), List.filled(12, 100.0));
    });

    test('centavos que sobram vão para a 1ª parcela e a soma fecha', () {
      final v = Fmt.dividirParcelas(100, 3);
      expect(v, [33.34, 33.33, 33.33]);
      expect((v.reduce((a, b) => a + b) * 100).round(), 10000);
    });
  });

  group('Fmt.resumoParcelas', () {
    test('parcelas iguais', () {
      expect(Fmt.resumoParcelas(1200, 12), '12x de R\$ 100,00');
    });

    test('1ª parcela diferente', () {
      expect(Fmt.resumoParcelas(100, 3), '1x de R\$ 33,34 + 2x de R\$ 33,33');
    });
  });

  group('LancamentoModel', () {
    test('lê as colunas de parcela da API e envia "parcelas" ao criar', () {
      final l = LancamentoModel.fromApi({
        'id': 7,
        'description': 'Notebook',
        'amount': 300,
        'date': '2026-12-10',
        'category_name': 'Compras',
        'parcelado': 1,
        'parcela_grupo': 'abc',
        'parcela_numero': 2,
        'parcela_total': 10,
      }, TipoLancamento.despesa);

      expect(l.isParcela, isTrue);
      expect(l.rotuloParcela, 'Parcela 2/10');
      expect(l.toApiJson(categoryId: 1, parcelas: 10)['parcelas'], 10);
      expect(l.toApiJson(categoryId: 1).containsKey('parcelas'), isFalse);
    });

    test('lançamento comum não é parcela', () {
      final l = LancamentoModel.fromApi({
        'id': 1,
        'description': 'Mercado',
        'amount': 50,
        'date': '2026-11-01',
        'category_name': 'Alimentação',
        'parcelado': 0,
      }, TipoLancamento.despesa);
      expect(l.isParcela, isFalse);
      expect(l.rotuloParcela, isNull);
    });
  });
}
