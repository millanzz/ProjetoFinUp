import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:FinUp/main.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('App abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const FinanceiroApp(logado: false));
    await tester.pump();

    expect(find.text('Entrar na sua conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
