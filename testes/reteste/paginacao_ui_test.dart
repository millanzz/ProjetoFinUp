// Paginação nas telas reais do app, contra a API real (porta 3999, banco de teste).
// Rodar (na pasta frontend, com a API de teste no ar):
//   flutter test ../testes/reteste/paginacao_ui_test.dart --dart-define=API_URL=http://127.0.0.1:3999 --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/core/formatters.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/services/auth_service.dart';
import 'package:FinUp/services/lancamento_service.dart';
import 'package:FinUp/widgets/fin_layout.dart';
import '../02-funcionais/app/suporte.dart';

final _run = DateTime.now().millisecondsSinceEpoch;
String _email(String n) => '$n.$_run@teste.local';

Future<void> _capturar(WidgetTester t, String nome) async {
  await assentar(t, 400);
  await expectLater(find.byKey(telaKey), matchesGoldenFile('evidencias/telas/$nome.png'));
}

/// 6 compras de 48 parcelas (jan/2022 a dez/2025) + 1 despesa mais antiga:
/// 289 despesas, todas FORA do cache do app (que guarda só o mês atual em diante).
Future<String> _semear(String email) async {
  final token = await criarUsuario('Paula Pagina', email, 'senha123');
  final cats = (await api('GET', '/categories?type=expense', token: token))['body'] as List;
  final compras = cats.firstWhere((c) => c['name'] == 'Compras')['id'];
  for (var i = 0; i < 6; i++) {
    final r = await api('POST', '/expenses', token: token, body: {
      'amount': 480 + i * 48, 'date': '2022-01-1$i', 'description': 'Compra $i',
      'category_id': compras, 'parcelas': 48,
    });
    expect(r['status'], 201);
  }
  await api('POST', '/expenses', token: token, body: {
    'amount': 77.7, 'date': '2021-06-15', 'description': 'A mais antiga', 'category_id': compras,
  });
  return token;
}

Future<void> _entrar(WidgetTester t, String email) async {
  await telaDeCelular(t);
  await t.pumpWidget(comTela(const FinanceiroApp(logado: false)));
  await esperar(t, find.text('Entrar na sua conta'));
  await digitar(t, campo('E-mail'), email);
  await digitar(t, campo('Senha'), 'senha123');
  await tocar(t, find.text('Entrar').last);
  await esperar(t, find.text('Início'));
  await assentar(t);
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(prepararAmbiente);
  tearDown(AuthService.logout);

  testWidgets('UI-PAG-01 Histórico "Tudo": totais do período inteiro e rolagem carrega as páginas seguintes', (t) async {
    final token = await _semear(_email('paula'));
    final resumo = (await api('GET', '/lancamentos?limit=0', token: token))['body'] as Map;
    expect(resumo['total'], 289);

    await _entrar(t, _email('paula'));
    expect(LancamentoService.getAll(), isEmpty, reason: 'nada do mês atual: o aparelho não guarda os antigos');

    await tocar(t, find.text('Histórico').last);
    await tocar(t, find.text('Tudo'));
    await esperar(t, find.text('289 lançamentos'));
    expect(find.text('− ${Fmt.brl((resumo['despesas'] as num).toDouble())}'), findsOneWidget,
        reason: 'Saídas é o total do período inteiro, não só da 1ª página');
    await _capturar(t, 'UI-PAG-01a-historico-tudo');

    // Rola até o fim: as páginas 2 e 3 vêm sob demanda, até a despesa mais antiga
    var paginas = 0;
    for (var i = 0; i < 400 && find.text('A mais antiga').evaluate().isEmpty; i++) {
      if (find.byType(CarregandoMais).evaluate().isNotEmpty) paginas++;
      await t.drag(find.byType(Scrollable).first, const Offset(0, -700), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('A mais antiga'), findsOneWidget);
    expect(paginas, greaterThan(0), reason: 'o indicador de "carregando mais" apareceu');
    await _capturar(t, 'UI-PAG-01b-historico-fim-da-lista');
  });

  testWidgets('UI-PAG-02 Despesas → mês antigo: lista e total do mês vêm da API', (t) async {
    final token = await _semear(_email('quim'));
    final mes = (await api('GET', '/lancamentos?tipo=despesa&month=2025-12&limit=0', token: token))['body'] as Map;
    expect(mes['total'], 6);

    await _entrar(t, _email('quim'));
    await tocar(t, find.text('Despesas').last);
    await tocar(t, find.byType(MonthChip));
    final chip = find.text(Fmt.mesAno(DateTime(2025, 12)));
    await esperar(t, chip);
    await t.ensureVisible(chip);
    await assentar(t, 300);
    await tocar(t, chip);
    await esperar(t, find.text('6 lançamentos'));
    expect(find.text(Fmt.brl((mes['despesas'] as num).toDouble())), findsWidgets);
    expect(find.text('Compra 5'), findsOneWidget);
    await _capturar(t, 'UI-PAG-02-despesas-mes-antigo');
  });
}
