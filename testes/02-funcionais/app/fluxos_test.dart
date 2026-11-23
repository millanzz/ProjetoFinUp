// Testes funcionais de INTERFACE: as telas reais do app, operadas como um
// usuário faria (digitar, tocar, confirmar), conversando com a API real
// (banco em memória). Cada passo importante gera uma captura em
// testes/02-funcionais/evidencias/telas.
//
// Precisa da API de teste rodando:  node testes/02-funcionais/api/servidor.js 3999
// Rodar (na pasta frontend):
//   flutter test ../testes/02-funcionais/app/fluxos_test.dart --dart-define=API_URL=http://127.0.0.1:3999 --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/services/auth_service.dart';
import 'suporte.dart';

final _run = DateTime.now().millisecondsSinceEpoch;
String _email(String nome) => '$nome.$_run@teste.local';

Finder _valorLancamento() =>
    find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == '0,00');
Finder _tipo(String nome) => find.byWidgetPredicate((w) => w.runtimeType.toString() == nome);

Future<void> _abrirApp(WidgetTester t) async {
  await telaDeCelular(t);
  await t.pumpWidget(comTela(const FinanceiroApp(logado: false)));
  await esperar(t, find.text('Entrar na sua conta'));
}

Future<void> _entrar(WidgetTester t, String email, String senha) async {
  await _abrirApp(t);
  await digitar(t, campo('E-mail'), email);
  await digitar(t, campo('Senha'), senha);
  await tocar(t, find.text('Entrar').last);
  await esperar(t, find.text('Início'));
  await assentar(t);
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(prepararAmbiente);
  tearDown(AuthService.logout);

  group('Login', () {
    testWidgets('CT-UI-LOG-01 login válido abre a tela inicial com o nome do usuário', (t) async {
      await criarUsuario('Ana Souza', _email('ana'), 'senha123');
      await _abrirApp(t);
      await digitar(t, campo('E-mail'), _email('ana'));
      await digitar(t, campo('Senha'), 'senha123');
      await capturar(t, 'CT-UI-LOG-01a-login-preenchido');
      await tocar(t, find.text('Entrar').last);
      await esperar(t, find.textContaining(', Ana'));
      await assentar(t); // espera a transição de tela terminar
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsNothing);
      await capturar(t, 'CT-UI-LOG-01b-inicio');
    });

    testWidgets('CT-UI-LOG-02 campos vazios mostram aviso e não saem da tela', (t) async {
      await _abrirApp(t);
      await tocar(t, find.text('Entrar').last);
      await esperar(t, find.text('Preencha e-mail e senha para entrar.'));
      expect(find.text('Entrar na sua conta'), findsOneWidget);
      await capturar(t, 'CT-UI-LOG-02-campos-vazios');
    });

    testWidgets('CT-UI-LOG-03 senha errada mostra a mensagem da API e não entra', (t) async {
      await criarUsuario('Beto', _email('beto'), 'senha123');
      await _abrirApp(t);
      await digitar(t, campo('E-mail'), _email('beto'));
      await digitar(t, campo('Senha'), 'errada99');
      await tocar(t, find.text('Entrar').last);
      await esperar(t, find.text('Email ou senha inválidos'));
      expect(find.text('Entrar na sua conta'), findsOneWidget);
      await capturar(t, 'CT-UI-LOG-03-senha-errada');
    });

    testWidgets('CT-UI-LOG-04 sair da conta volta para o login', (t) async {
      await criarUsuario('Caio Reis', _email('caio'), 'senha123');
      await _entrar(t, _email('caio'), 'senha123');
      await tocar(t, _tipo('FinAvatar').first);
      await esperar(t, find.text('Sair da conta'));
      await tocar(t, find.text('Sair da conta'));
      await esperar(t, find.text('Sair').last);
      await capturar(t, 'CT-UI-LOG-04a-confirmar-saida');
      await tocar(t, find.text('Sair').last);
      await esperar(t, find.text('Entrar na sua conta'));
      await capturar(t, 'CT-UI-LOG-04b-login');
    });
  });

  group('Cadastro', () {
    Future<void> irParaCadastro(WidgetTester t) async {
      await _abrirApp(t);
      await tocar(t, find.text('Criar conta'));
      await esperar(t, find.text('Nome completo'));
    }

    testWidgets('CT-UI-CAD-01 cadastro completo entra no app e a conta existe na API', (t) async {
      await irParaCadastro(t);
      await digitar(t, campo('Nome completo'), 'Daniela Prado');
      await digitar(t, campo('E-mail'), _email('dani'));
      await digitar(t, campo('Senha'), 'minhasenha');
      await tocar(t, _tipo('FinCheckbox'));
      await capturar(t, 'CT-UI-CAD-01a-cadastro-preenchido');
      await tocar(t, find.text('Criar conta').last);
      await esperar(t, find.textContaining(', Daniela'));
      await capturar(t, 'CT-UI-CAD-01b-inicio');
      final l = await api('POST', '/auth/login', body: {'email': _email('dani'), 'password': 'minhasenha'});
      expect(l['status'], 200);
    });

    testWidgets('CT-UI-CAD-02 senha com menos de 6 caracteres é barrada na tela', (t) async {
      await irParaCadastro(t);
      await digitar(t, campo('Nome completo'), 'Eva');
      await digitar(t, campo('E-mail'), _email('eva'));
      await digitar(t, campo('Senha'), '12345');
      await tocar(t, _tipo('FinCheckbox'));
      await tocar(t, find.text('Criar conta').last);
      await esperar(t, find.text('A senha deve ter pelo menos 6 caracteres.'));
      await capturar(t, 'CT-UI-CAD-02-senha-curta');
      final l = await api('POST', '/auth/login', body: {'email': _email('eva'), 'password': '12345'});
      expect(l['status'], 401, reason: 'a conta não pode ter sido criada');
    });

    testWidgets('CT-UI-CAD-03 sem aceitar os termos o cadastro não continua', (t) async {
      await irParaCadastro(t);
      await digitar(t, campo('Nome completo'), 'Fabio');
      await digitar(t, campo('E-mail'), _email('fabio'));
      await digitar(t, campo('Senha'), 'senha123');
      await tocar(t, find.text('Criar conta').last);
      await esperar(t, find.text('Você precisa aceitar os termos de uso.'));
      await capturar(t, 'CT-UI-CAD-03-sem-termos');
    });

    testWidgets('CT-UI-CAD-04 e-mail já cadastrado mostra a mensagem da API', (t) async {
      await criarUsuario('Gabi', _email('gabi'), 'senha123');
      await irParaCadastro(t);
      await digitar(t, campo('Nome completo'), 'Outra Gabi');
      await digitar(t, campo('E-mail'), _email('gabi'));
      await digitar(t, campo('Senha'), 'senha123');
      await tocar(t, _tipo('FinCheckbox'));
      await tocar(t, find.text('Criar conta').last);
      await esperar(t, find.text('Email já cadastrado'));
      expect(find.text('Nome completo'), findsOneWidget);
      await capturar(t, 'CT-UI-CAD-04-email-duplicado');
    });

    testWidgets('CT-UI-CAD-05 cadastrar despesa pelo formulário atualiza o saldo e grava na API', (t) async {
      final token = await criarUsuario('Hugo', _email('hugo'), 'senha123');
      await _entrar(t, _email('hugo'), 'senha123');
      await tocar(t, find.text('Despesa'));
      await esperar(t, find.text('Nova despesa'));
      await digitar(t, _valorLancamento(), '1.250,90');
      await digitar(t, campo('Descrição'), 'Aluguel');
      await tocar(t, find.text('Moradia'));
      await capturar(t, 'CT-UI-CAD-05a-form-despesa');
      await tocar(t, find.text('Salvar despesa'));
      await esperar(t, find.text('Despesa salva'));
      expect(find.text('−R\$ 1.250,90'), findsOneWidget);
      await capturar(t, 'CT-UI-CAD-05b-saldo-atualizado');
      final lista = await api('GET', '/expenses', token: token);
      expect((lista['body'] as List).single['amount'], 1250.9);
      expect((lista['body'] as List).single['category_name'], 'Moradia');
    });

    testWidgets('CT-UI-CAD-06 formulário sem valor ou sem categoria não salva', (t) async {
      final token = await criarUsuario('Iris', _email('iris'), 'senha123');
      await _entrar(t, _email('iris'), 'senha123');
      await tocar(t, find.text('Receita'));
      await esperar(t, find.text('Nova receita'));
      await tocar(t, find.text('Salvar receita'));
      await esperar(t, find.text('Informe um valor válido maior que zero.'));
      await digitar(t, _valorLancamento(), '500');
      await digitar(t, campo('Descrição'), 'Freela');
      await tocar(t, find.text('Salvar receita'));
      await esperar(t, find.text('Selecione uma categoria.'));
      await capturar(t, 'CT-UI-CAD-06-sem-categoria');
      expect((await api('GET', '/incomes', token: token))['body'], isEmpty);
    });
  });

  group('Edição', () {
    testWidgets('CT-UI-EDI-01 editar nome no perfil atualiza a tela e a API', (t) async {
      final token = await criarUsuario('Joao', _email('joao'), 'senha123');
      await _entrar(t, _email('joao'), 'senha123');
      await tocar(t, _tipo('FinAvatar').first);
      await esperar(t, find.text('Editar perfil'));
      await tocar(t, find.text('Editar perfil'));
      await esperar(t, find.text('Nome'));
      await digitar(t, campo('Nome'), 'João Pedro');
      await capturar(t, 'CT-UI-EDI-01a-editar-perfil');
      await tocar(t, find.text('Salvar'));
      await esperar(t, find.text('Perfil atualizado'));
      expect(find.text('João Pedro'), findsWidgets);
      await capturar(t, 'CT-UI-EDI-01b-perfil-atualizado');
      expect((await api('GET', '/users/me', token: token))['body']['name'], 'João Pedro');
    });

    testWidgets('CT-UI-EDI-02 alterar senha: a nova passa a valer no login', (t) async {
      await criarUsuario('Kel', _email('kel'), 'antiga1');
      await _entrar(t, _email('kel'), 'antiga1');
      await tocar(t, _tipo('FinAvatar').first);
      await esperar(t, find.text('Alterar senha'));
      await tocar(t, find.text('Alterar senha'));
      await esperar(t, find.text('Senha atual'));
      await digitar(t, campo('Senha atual'), 'antiga1');
      await digitar(t, campo('Nova senha'), 'nova1234');
      await tocar(t, find.text('Salvar'));
      await esperar(t, find.text('Senha alterada'));
      await capturar(t, 'CT-UI-EDI-02-senha-alterada');
      final nova = await api('POST', '/auth/login', body: {'email': _email('kel'), 'password': 'nova1234'});
      final antiga = await api('POST', '/auth/login', body: {'email': _email('kel'), 'password': 'antiga1'});
      expect([nova['status'], antiga['status']], [200, 401]);
    });

    testWidgets('CT-UI-EDI-03 editar despesa pela lista atualiza o valor na tela e na API', (t) async {
      final token = await criarUsuario('Lia', _email('lia'), 'senha123');
      final cats = (await api('GET', '/categories?type=expense', token: token))['body'] as List;
      final mercado = cats.firstWhere((c) => c['name'] == 'Alimentação')['id'];
      final criado = await api('POST', '/expenses', token: token,
          body: {'amount': 80, 'date': hojeApi(), 'description': 'Mercado', 'category_id': mercado});
      await _entrar(t, _email('lia'), 'senha123');
      await tocar(t, find.text('Despesas').last);
      await esperar(t, find.text('Mercado'));
      await tocar(t, find.text('Mercado').last);
      await esperar(t, find.text('Editar lançamento'));
      await capturar(t, 'CT-UI-EDI-03a-menu-lancamento');
      await tocar(t, find.text('Editar lançamento'));
      await esperar(t, find.text('Editar despesa'));
      await digitar(t, _valorLancamento(), '95,50');
      await capturar(t, 'CT-UI-EDI-03b-form-edicao');
      await tocar(t, find.text('Salvar alterações'));
      await esperar(t, find.text('Lançamento atualizado'));
      expect(find.textContaining('95,50'), findsWidgets);
      await capturar(t, 'CT-UI-EDI-03c-lista-atualizada');
      final lista = (await api('GET', '/expenses', token: token))['body'] as List;
      expect(lista.single['id'], criado['body']['id']);
      expect(lista.single['amount'], 95.5);
    });
  });

  group('Exclusão', () {
    Future<(String, int)> comDespesa(String nome) async {
      final token = await criarUsuario(nome, _email(nome.toLowerCase()), 'senha123');
      final cats = (await api('GET', '/categories?type=expense', token: token))['body'] as List;
      final lazer = cats.firstWhere((c) => c['name'] == 'Lazer')['id'];
      final r = await api('POST', '/expenses', token: token,
          body: {'amount': 45, 'date': hojeApi(), 'description': 'Cinema', 'category_id': lazer});
      return (token, r['body']['id'] as int);
    }

    testWidgets('CT-UI-EXC-01 excluir despesa com confirmação remove da tela e da API', (t) async {
      final (token, _) = await comDespesa('Max');
      await _entrar(t, _email('max'), 'senha123');
      await tocar(t, find.text('Despesas').last);
      await esperar(t, find.text('Cinema'));
      await tocar(t, find.text('Cinema').last);
      await esperar(t, find.text('Excluir lançamento'));
      await tocar(t, find.text('Excluir lançamento'));
      await esperar(t, find.textContaining('Deseja excluir "Cinema"'));
      await capturar(t, 'CT-UI-EXC-01a-confirmar-exclusao');
      await tocar(t, find.text('Excluir').last);
      await esperar(t, find.text('Lançamento excluído'));
      expect(find.text('Cinema'), findsNothing);
      await capturar(t, 'CT-UI-EXC-01b-lista-sem-item');
      expect((await api('GET', '/expenses', token: token))['body'], isEmpty);
    });

    testWidgets('CT-UI-EXC-02 cancelar a exclusão mantém o lançamento', (t) async {
      final (token, _) = await comDespesa('Nina');
      await _entrar(t, _email('nina'), 'senha123');
      await tocar(t, find.text('Despesas').last);
      await esperar(t, find.text('Cinema'));
      await tocar(t, find.text('Cinema').last);
      await esperar(t, find.text('Excluir lançamento'));
      await tocar(t, find.text('Excluir lançamento'));
      await esperar(t, find.text('Cancelar'));
      await tocar(t, find.text('Cancelar').last);
      await assentar(t);
      expect(find.text('Cinema'), findsWidgets);
      await capturar(t, 'CT-UI-EXC-02-exclusao-cancelada');
      expect((await api('GET', '/expenses', token: token))['body'], hasLength(1));
    });

    testWidgets('CT-UI-EXC-03 excluir meta (tocar e segurar) remove da tela e da API', (t) async {
      final token = await criarUsuario('Otto', _email('otto'), 'senha123');
      await api('POST', '/goals', token: token, body: {'title': 'Viagem', 'target_amount': 5000, 'current_amount': 1200, 'icon': 'flight'});
      await _entrar(t, _email('otto'), 'senha123');
      await tocar(t, find.text('Metas').last);
      await esperar(t, find.text('Viagem'));
      await capturar(t, 'CT-UI-EXC-03a-metas');
      await t.ensureVisible(find.text('Viagem').last);
      await t.longPress(find.text('Viagem').last);
      await esperar(t, find.text('Excluir meta'));
      await capturar(t, 'CT-UI-EXC-03b-confirmar-exclusao');
      await tocar(t, find.text('Excluir').last);
      await esperar(t, find.text('Meta excluída'));
      expect(find.text('Viagem'), findsNothing);
      await capturar(t, 'CT-UI-EXC-03c-sem-metas');
      expect((await api('GET', '/goals', token: token))['body'], isEmpty);
    });
  });
}
