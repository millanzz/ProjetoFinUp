// Fluxos de interface das funcionalidades novas, nas telas reais do app,
// contra a API real (porta 3999, banco de teste).
// Rodar (na pasta frontend, com a API de teste no ar):
//   flutter test ../testes/reteste/fluxos_novos_test.dart --dart-define=API_URL=http://127.0.0.1:3999 --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/services/auth_service.dart';
import '../02-funcionais/app/suporte.dart';

final _run = DateTime.now().millisecondsSinceEpoch;
String _email(String n) => '$n.$_run@teste.local';
Finder _tipo(String nome) => find.byWidgetPredicate((w) => w.runtimeType.toString() == nome);

Future<void> _entrar(WidgetTester t, String email, String senha) async {
  await telaDeCelular(t);
  await t.pumpWidget(comTela(const FinanceiroApp(logado: false)));
  await esperar(t, find.text('Entrar na sua conta'));
  await digitar(t, campo('E-mail'), email);
  await digitar(t, campo('Senha'), senha);
  await tocar(t, find.text('Entrar').last);
  await esperar(t, find.text('Início'));
  await assentar(t);
}

Future<void> _abrirPerfil(WidgetTester t) async {
  await tocar(t, _tipo('FinAvatar').first);
  await esperar(t, find.text('Sair da conta'));
}

Future<void> _capturar(WidgetTester t, String nome) async {
  await assentar(t, 400);
  await expectLater(find.byKey(telaKey), matchesGoldenFile('evidencias/telas/$nome.png'));
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(prepararAmbiente);
  tearDown(AuthService.logout);

  testWidgets('UI-CONTA-01 excluir conta pelo Perfil apaga a conta e volta ao login', (t) async {
    await criarUsuario('Ana Excluir', _email('ana'), 'senha123');
    await _entrar(t, _email('ana'), 'senha123');
    await _abrirPerfil(t);
    await tocar(t, find.text('Excluir conta'));
    await esperar(t, find.text('Senha atual'));
    await digitar(t, campo('Senha atual'), 'senha123');
    await _capturar(t, 'UI-CONTA-01a-confirmar-exclusao');
    await tocar(t, find.text('Excluir').last);
    await esperar(t, find.text('Entrar na sua conta'));
    await _capturar(t, 'UI-CONTA-01b-login-apos-excluir');
    final login = await api('POST', '/auth/login', body: {'email': _email('ana'), 'password': 'senha123'});
    expect(login['status'], 401, reason: 'a conta não existe mais');
  });

  testWidgets('UI-CONTA-02 senha errada ao excluir mostra aviso e a conta continua', (t) async {
    await criarUsuario('Beto Excluir', _email('beto'), 'senha123');
    await _entrar(t, _email('beto'), 'senha123');
    await _abrirPerfil(t);
    await tocar(t, find.text('Excluir conta'));
    await esperar(t, find.text('Senha atual'));
    await digitar(t, campo('Senha atual'), 'errada99');
    await tocar(t, find.text('Excluir').last);
    await esperar(t, find.text('Senha incorreta'));
    await _capturar(t, 'UI-CONTA-02-senha-incorreta');
    final login = await api('POST', '/auth/login', body: {'email': _email('beto'), 'password': 'senha123'});
    expect(login['status'], 200);
  });

  testWidgets('UI-PRIV-01 Perfil → Política de privacidade mostra o texto da API', (t) async {
    await criarUsuario('Caio Priv', _email('caio'), 'senha123');
    await _entrar(t, _email('caio'), 'senha123');
    await _abrirPerfil(t);
    await tocar(t, find.text('Política de privacidade'));
    await esperar(t, find.textContaining('Quem somos'));
    expect(find.textContaining('Quais dados coletamos'), findsOneWidget);
    await _capturar(t, 'UI-PRIV-01-politica');
  });

  testWidgets('UI-PRIV-02 no cadastro, "termos de uso" abre a política', (t) async {
    await telaDeCelular(t);
    await t.pumpWidget(comTela(const FinanceiroApp(logado: false)));
    await esperar(t, find.text('Entrar na sua conta'));
    await tocar(t, find.text('Criar conta'));
    await esperar(t, find.text('Nome completo'));
    await t.ensureVisible(_tipo('FinCheckbox'));
    await assentar(t, 300);
    await t.tapOnText(find.textRange.ofSubstring('termos de uso'));
    await esperar(t, find.textContaining('Quem somos'));
    await _capturar(t, 'UI-PRIV-02-politica-pelo-cadastro');
  });

  testWidgets('UI-SESS-01 trocar a senha no app mantém este aparelho conectado', (t) async {
    await criarUsuario('Duda Sessao', _email('duda'), 'antiga12');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await _entrar(t, _email('duda'), 'antiga12');
    await _abrirPerfil(t);
    await tocar(t, find.text('Alterar senha'));
    await esperar(t, find.text('Senha atual'));
    await digitar(t, campo('Senha atual'), 'antiga12');
    await digitar(t, campo('Nova senha'), 'nova12345');
    await tocar(t, find.text('Salvar'));
    await esperar(t, find.text('Senha alterada'));
    // Volta à Início e recarrega: com o token novo, os dados continuam acessíveis
    await tocar(t, find.byIcon(Icons.arrow_back).first);
    await esperar(t, find.text('Início'));
    expect(await AuthService.restaurarSessao(), isTrue, reason: 'sessão deste aparelho continua válida');
    await _capturar(t, 'UI-SESS-01-continua-conectado');
  });
}
