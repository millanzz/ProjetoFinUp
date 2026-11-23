import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/core/formatters.dart';

int _soma(List<String> p) =>
    p.where((s) => !s.startsWith('<')).map((s) => int.parse(s.replaceAll('%', ''))).fold(0, (a, b) => a + b);

void main() {
  group('Fmt.percentuais', () {
    test('aluguel 80% e compras 20% do total de despesas', () {
      expect(Fmt.percentuais([1600, 400]), ['80%', '20%']);
    });

    test('recalcula a cada nova despesa', () {
      expect(Fmt.percentuais([1600, 400, 2000]), ['40%', '10%', '50%']);
    });

    test('sempre fecha 100% (sem 99% ou 101% de arredondamento)', () {
      final p = Fmt.percentuais([1, 1, 1]);
      expect(_soma(p), 100);
      expect(p, ['34%', '33%', '33%']);

      // dados do exemplo do Figma: 1200 + 680 + 350 + 320 = 2550
      final f = Fmt.percentuais([1200, 680, 350, 320]);
      expect(f, ['47%', '27%', '14%', '12%']);
      expect(_soma(f), 100);
    });

    test('valor pequeno aparece como <1% e não 0%', () {
      final p = Fmt.percentuais([1200, 728.90, 350, 320, 10]);
      expect(p.last, '<1%');
    });

    test('sem valores ou total zero', () {
      expect(Fmt.percentuais([]), <String>[]);
      expect(Fmt.percentuais([0, 0]), ['0%', '0%']);
    });

    test('uma única categoria é 100%', () {
      expect(Fmt.percentuais([2550]), ['100%']);
    });
  });
}
