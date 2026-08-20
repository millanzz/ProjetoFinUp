import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_financeira/main.dart';

void main() {
  testWidgets('App abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const FinanceiroApp(logado: false));

    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
