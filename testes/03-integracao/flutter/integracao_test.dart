// Testes de INTEGRAÇÃO: camada de serviços do app Flutter + API Express + SQLite.
//
//   AuthService / LancamentoService / CategoriaService / MetaService (Flutter)
//        │  ApiClient (http + JWT + shared_preferences)
//        ▼
//   API real (backend/src/app.js)  ──sqlite3──▶  arquivo .db do teste
//
// Cada caso usa o código de produção do app, a API real e um arquivo SQLite
// real, e confere o resultado nas TRÊS camadas. O que trafega e o que fica
// gravado vai para evidencias/rastros/<caso>.md.
//
// Rodar (na pasta frontend):
//   flutter test ../testes/03-integracao/flutter/integracao_test.dart --dart-define=API_URL=http://127.0.0.1:3999
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:FinUp/core/formatters.dart';
import 'package:FinUp/models/lancamento_model.dart';
import 'package:FinUp/services/api_client.dart';
import 'package:FinUp/services/auth_service.dart';
import 'package:FinUp/services/categoria_service.dart';
import 'package:FinUp/services/consulta_lancamentos.dart';
import 'package:FinUp/services/lancamento_service.dart';
import 'package:FinUp/services/meta_service.dart';

import 'suporte.dart';

final bancoPrincipal = '$pastaEvidencias/banco-integracao.db';
final bancoLegado = '$pastaEvidencias/banco-legado-migrado.db';
late Servidor srv;
final _cliente = ClienteRastreado();

/// Registra um caso: roda o corpo com o HTTP do app passando pelo rastro.
void caso(String id, String titulo, Future<void> Function() corpo) {
  test('$id $titulo', () async {
    final r = Rastro.atual = Rastro(id, titulo);
    try {
      await http.runWithClient(corpo, () => _cliente);
      r.resultado('APROVADO ✅');
    } catch (e, st) {
      r.resultado('REPROVADO ❌', '$e\n${st.toString().split('\n').take(4).join('\n')}');
      rethrow;
    } finally {
      Rastro.atual = null;
    }
  }, timeout: const Timeout(Duration(seconds: 90)));
}

LancamentoModel _lanc(String titulo, double valor, String data, TipoLancamento tipo, [String? cat]) =>
    LancamentoModel(titulo: titulo, valor: valor, data: DateTime.parse(data), tipo: tipo, categoria: cat);

const _r = TipoLancamento.receita;
const _d = TipoLancamento.despesa;

Future<int> _idUsuario(String email) async =>
    (await srv.sql('SELECT id FROM users WHERE email = ?', [email])).single['id'] as int;

Future<String?> _tokenSalvo() async => (await SharedPreferences.getInstance()).getString('auth_token');

/// Simula "fechar e abrir o app": zera a memória, mas mantém o que estava
/// gravado no shared_preferences (o disco do aparelho).
Future<void> _reabrirApp() async {
  final token = await _tokenSalvo();
  AuthService.logout();
  MetaService.limpar();
  SharedPreferences.setMockInitialValues({if (token != null) 'auth_token': token});
}

/// Outro aparelho do mesmo usuário chamando a API (fora do app em teste).
Future<int> _outroAparelho(String metodo, String rota, String token) async {
  final req = http.Request(metodo, Uri.parse('${'http://127.0.0.1:$portaApi'}$rota'))
    ..headers['Authorization'] = 'Bearer $token';
  final r = await IOClient().send(req);
  Rastro.atual?.nota('Outro aparelho do mesmo usuário: `$metodo $rota` → ${r.statusCode}');
  return r.statusCode;
}

void main() {
  setUpAll(() async {
    for (final f in [bancoPrincipal, bancoLegado]) {
      if (File(f).existsSync()) File(f).deleteSync();
    }
    srv = Servidor(bancoPrincipal);
    await srv.iniciar();
  });

  tearDownAll(() async {
    await srv.parar();
    File('$pastaEvidencias/api-log.txt').writeAsStringSync(srv.log);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    AuthService.logout();
    MetaService.limpar();
  });

  // ── Autenticação e sessão ──────────────────────────────────────
  group('Autenticação e sessão', () {
    caso('CT-INT-01', 'cadastro pelo app grava usuário (senha com hash) e categorias no SQLite e salva o token no aparelho', () async {
      await AuthService.register(nome: 'Ana Souza', email: 'Ana@Teste.Local', senha: 'senha123');
      expect(AuthService.isLogged(), isTrue);
      expect(AuthService.nome, 'Ana Souza');
      final u = (await srv.sql('SELECT id, name, email, password FROM users WHERE email = ?', ['ana@teste.local'])).single;
      expect(u['name'], 'Ana Souza');
      expect(u['password'], startsWith(r'$2b$10$'));
      final cats = await srv.sql('SELECT type, COUNT(*) AS n FROM categories WHERE user_id = ? GROUP BY type ORDER BY type', [u['id']]);
      expect(cats, [{'type': 'expense', 'n': 9}, {'type': 'income', 'n': 5}]);
      final token = await _tokenSalvo();
      expect(token, isNotNull);
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token!.split('.')[1]))));
      expect(payload['id'], u['id'], reason: 'o token salvo no aparelho é do usuário gravado no banco');
    });

    caso('CT-INT-02', 'reabrir o app restaura a sessão a partir do token salvo e dos dados do SQLite', () async {
      await AuthService.login(email: 'ana@teste.local', senha: 'senha123');
      await _reabrirApp();
      expect(AuthService.isLogged(), isFalse);
      expect(await AuthService.restaurarSessao(), isTrue);
      expect(AuthService.nome, 'Ana Souza');
      expect(AuthService.email, 'ana@teste.local');
    });

    caso('CT-INT-03', 'token expirado: a sessão não é restaurada e o token é apagado do aparelho', () async {
      final id = await _idUsuario('ana@teste.local');
      final expirado = await srv.token(id: id, email: 'ana@teste.local', expiradoHaSegundos: 60);
      SharedPreferences.setMockInitialValues({'auth_token': expirado});
      expect(await AuthService.restaurarSessao(), isFalse);
      expect(await _tokenSalvo(), isNull);
      expect(AuthService.isLogged(), isFalse);
    });

    caso('CT-INT-04', 'login com senha errada: o erro da API chega ao app e nada é salvo', () async {
      final antes = await srv.sql('SELECT password FROM users WHERE email = ?', ['ana@teste.local']);
      await expectLater(
        AuthService.login(email: 'ana@teste.local', senha: 'errada'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Email ou senha inválidos')),
      );
      expect(await _tokenSalvo(), isNull);
      expect(AuthService.isLogged(), isFalse);
      expect(await srv.sql('SELECT password FROM users WHERE email = ?', ['ana@teste.local']), antes);
    });

    caso('CT-INT-05', 'editar perfil no app atualiza o SQLite e o novo e-mail passa a valer no login', () async {
      await AuthService.register(nome: 'Bruno', email: 'bruno@teste.local', senha: 'senha123');
      await AuthService.atualizarPerfil(nome: 'Bruno Lima', email: 'Bruno.Lima@Teste.Local');
      final row = (await srv.sql('SELECT name, email FROM users WHERE email LIKE ?', ['bruno%'])).single;
      expect(row, {'name': 'Bruno Lima', 'email': 'bruno.lima@teste.local'});
      expect(AuthService.nome, 'Bruno Lima');
      AuthService.logout();
      await AuthService.login(email: 'bruno.lima@teste.local', senha: 'senha123');
      expect(AuthService.nome, 'Bruno Lima');
    });

    caso('CT-INT-06', 'trocar senha no app troca o hash no SQLite', () async {
      await AuthService.login(email: 'bruno.lima@teste.local', senha: 'senha123');
      final antes = (await srv.sql('SELECT password FROM users WHERE email = ?', ['bruno.lima@teste.local'])).single['password'];
      await AuthService.alterarSenha(senhaAtual: 'senha123', novaSenha: 'nova4567');
      final depois = (await srv.sql('SELECT password FROM users WHERE email = ?', ['bruno.lima@teste.local'])).single['password'];
      expect(depois, isNot(antes));
      expect(depois, startsWith(r'$2b$10$'));
      AuthService.logout();
      await AuthService.login(email: 'bruno.lima@teste.local', senha: 'nova4567');
      expect(AuthService.isLogged(), isTrue);
    });

    caso('CT-INT-07', 'trocar de usuário no mesmo aparelho não mostra dados do anterior', () async {
      await AuthService.login(email: 'ana@teste.local', senha: 'senha123');
      await LancamentoService.adicionar(_lanc('Salário da Ana', 4000, '2026-11-05', _r, 'Salário'));
      expect(LancamentoService.getAll(), hasLength(1));
      AuthService.logout();
      await AuthService.register(nome: 'Carla', email: 'carla@teste.local', senha: 'senha123');
      await LancamentoService.carregar(force: true);
      await CategoriaService.carregar(force: true);
      expect(LancamentoService.getAll(), isEmpty);
      expect(LancamentoService.saldo, 0);
      final idCarla = await _idUsuario('carla@teste.local');
      final doBanco = await srv.sql('SELECT user_id, description FROM incomes WHERE description = ?', ['Salário da Ana']);
      expect(doBanco.single['user_id'], isNot(idCarla));
    });
  });

  // ── Lançamentos ────────────────────────────────────────────────
  group('Receitas e despesas', () {
    setUp(() async {
      await AuthService.login(email: 'carla@teste.local', senha: 'senha123');
      await LancamentoService.carregar(force: true);
      await CategoriaService.carregar(force: true);
    });

    caso('CT-INT-08', 'receita com acentos e emoji: Flutter → API → SQLite → Flutter sem perder nada', () async {
      const titulo = 'Salário de novembro — açaí, pão & café ☕🍇';
      final criado = await LancamentoService.adicionar(_lanc(titulo, 4500.75, '2026-11-08', _r, 'Salário'));
      final row = (await srv.sql(
        '''SELECT i.id, i.amount, typeof(i.amount) AS tipo_amount, i.description, i.date, i.parcelado,
                  c.name AS categoria, c.type AS tipo_categoria, u.email
           FROM incomes i JOIN categories c ON c.id = i.category_id JOIN users u ON u.id = i.user_id
           WHERE i.id = ?''',
        [int.parse(criado.id)],
      )).single;
      expect(row['amount'], 4500.75);
      expect(row['tipo_amount'], 'real');
      expect(row['description'], titulo);
      expect(row['date'], '2026-11-08');
      expect(row['categoria'], 'Salário');
      expect(row['tipo_categoria'], 'income');
      expect(row['email'], 'carla@teste.local');
      await LancamentoService.carregar(force: true);
      final lido = LancamentoService.getReceitas().singleWhere((l) => l.id == criado.id);
      expect([lido.titulo, lido.valor, lido.dataApi, lido.categoria, lido.isReceita], [titulo, 4500.75, '2026-11-08', 'Salário', true]);
    });

    caso('CT-INT-09', 'despesa sem categoria: o app usa "Outros" e o SQLite liga à categoria de despesa', () async {
      final criado = await LancamentoService.adicionar(_lanc('Sem categoria', 12.5, '2026-11-08', _d));
      final row = (await srv.sql(
        'SELECT c.name, c.type FROM expenses e JOIN categories c ON c.id = e.category_id WHERE e.id = ?',
        [int.parse(criado.id)],
      )).single;
      expect(row, {'name': 'Outros', 'type': 'expense'});
    });

    caso('CT-INT-10', 'categoria nova digitada no app é criada uma única vez no SQLite', () async {
      await LancamentoService.adicionar(_lanc('Ração', 120, '2026-11-08', _d, 'Pets'));
      await LancamentoService.adicionar(_lanc('Veterinário', 250, '2026-11-09', _d, 'Pets'));
      final uid = await _idUsuario('carla@teste.local');
      final cats = await srv.sql("SELECT id, type FROM categories WHERE name = 'Pets' AND user_id = ?", [uid]);
      expect(cats, hasLength(1));
      expect(cats.single['type'], 'expense');
      final usos = await srv.sql('SELECT COUNT(*) AS n FROM expenses WHERE category_id = ?', [cats.single['id']]);
      expect(usos.single['n'], 2);
    });

    caso('CT-INT-11', 'compra parcelada: 3 linhas no SQLite ligadas pelo grupo e o app lê as mesmas parcelas', () async {
      final primeira = await LancamentoService.adicionar(
          _lanc('Geladeira', 1000, '2026-11-30', _d, 'Compras'), parcelas: 3);
      final linhas = await srv.sql(
        'SELECT id, amount, date, parcelado, parcela_numero, parcela_total FROM expenses WHERE parcela_grupo = ? ORDER BY parcela_numero',
        [primeira.parcelaGrupo],
      );
      expect(linhas.map((l) => [l['amount'], l['date'], l['parcelado'], l['parcela_numero'], l['parcela_total']]).toList(), [
        [333.34, '2026-11-30', 1, 1, 3],
        [333.33, '2026-12-30', 1, 2, 3],
        [333.33, '2027-01-30', 1, 3, 3],
      ]);
      final noCache = LancamentoService.getDespesas().where((l) => l.parcelaGrupo == primeira.parcelaGrupo).toList();
      await LancamentoService.carregar(force: true);
      final daApi = LancamentoService.getDespesas().where((l) => l.parcelaGrupo == primeira.parcelaGrupo).toList();
      String resumo(List<LancamentoModel> ls) =>
          (ls.map((l) => '${l.id}|${l.valor}|${l.dataApi}|${l.rotuloParcela}').toList()..sort()).join(';');
      expect(resumo(daApi), resumo(noCache), reason: 'cache local após criar = dados relidos da API');
      expect(daApi.map((l) => l.id).toSet(), linhas.map((l) => '${l['id']}').toSet());
    });

    caso('CT-INT-12', 'editar lançamento no app altera a mesma linha no SQLite (id e quantidade preservados)', () async {
      final criado = await LancamentoService.adicionar(_lanc('Mercado', 80, '2026-11-10', _d, 'Alimentação'));
      final antes = (await srv.sql('SELECT COUNT(*) AS n FROM expenses')).single['n'];
      await LancamentoService.editar(LancamentoModel(
        id: criado.id, titulo: 'Mercado do mês', valor: 95.5, data: DateTime(2026, 11, 12), tipo: _d, categoria: 'Alimentação'));
      final row = (await srv.sql(
        'SELECT e.amount, e.description, e.date, c.name AS categoria FROM expenses e JOIN categories c ON c.id = e.category_id WHERE e.id = ?',
        [int.parse(criado.id)],
      )).single;
      expect(row, {'amount': 95.5, 'description': 'Mercado do mês', 'date': '2026-11-12', 'categoria': 'Alimentação'});
      expect((await srv.sql('SELECT COUNT(*) AS n FROM expenses')).single['n'], antes);
      await LancamentoService.carregar(force: true);
      final lido = LancamentoService.getDespesas().singleWhere((l) => l.id == criado.id);
      expect([lido.titulo, lido.valor, lido.dataApi], ['Mercado do mês', 95.5, '2026-11-12']);
    });

    caso('CT-INT-13', 'excluir lançamento e parcelamento no app apaga as linhas do SQLite', () async {
      final avulso = await LancamentoService.adicionar(_lanc('Cinema', 45, '2026-11-14', _d, 'Lazer'));
      final parcela = await LancamentoService.adicionar(_lanc('Curso', 600, '2026-11-15', _d, 'Outros'), parcelas: 6);
      await LancamentoService.remover(avulso);
      expect(await srv.sql('SELECT id FROM expenses WHERE id = ?', [int.parse(avulso.id)]), isEmpty);
      final n = await LancamentoService.removerParcelamento(parcela);
      expect(n, 6);
      expect(await srv.sql('SELECT id FROM expenses WHERE parcela_grupo = ?', [parcela.parcelaGrupo]), isEmpty);
      expect(LancamentoService.getAll().where((l) => l.id == avulso.id || l.parcelaGrupo == parcela.parcelaGrupo), isEmpty);
    });

    caso('CT-INT-14', 'saldo igual nas três camadas: app (cache), API (/dashboard) e SQLite (SUM)', () async {
      await LancamentoService.adicionar(_lanc('Freela', 1200.5, '2026-11-20', _r, 'Freelance'));
      await LancamentoService.adicionar(_lanc('Luz', 250.25, '2026-11-21', _d, 'Moradia'));
      await LancamentoService.carregar(force: true);
      final uid = await _idUsuario('carla@teste.local');
      final soma = (await srv.sql(
        '''SELECT (SELECT COALESCE(SUM(amount),0) FROM incomes WHERE user_id = ?) AS receitas,
                  (SELECT COALESCE(SUM(amount),0) FROM expenses WHERE user_id = ?) AS despesas''',
        [uid, uid],
      )).single;
      final dash = await ApiClient.get('/dashboard');
      final saldoSql = (soma['receitas'] as num) - (soma['despesas'] as num);
      expect(LancamentoService.totalReceitas, closeTo(soma['receitas'] as num, 1e-9));
      expect(LancamentoService.totalDespesas, closeTo(soma['despesas'] as num, 1e-9));
      expect(LancamentoService.saldo, closeTo(saldoSql, 1e-9));
      expect(dash['balance'], closeTo(saldoSql, 1e-9));
      Rastro.atual?.nota('Saldo — app: ${LancamentoService.saldo} | API: ${dash['balance']} | SQLite: $saldoSql');
    });

    caso('CT-INT-15', 'valores-limite (R\$ 0,01 e R\$ 999.999.999,99) chegam iguais ao SQLite e voltam iguais ao app', () async {
      final a = await LancamentoService.adicionar(_lanc('Centavo', 0.01, '2026-11-01', _r, 'Outros'));
      final b = await LancamentoService.adicionar(_lanc('Prêmio', 999999999.99, '2026-11-01', _r, 'Outros'));
      final rows = await srv.sql('SELECT id, amount FROM incomes WHERE id IN (?, ?) ORDER BY amount', [int.parse(a.id), int.parse(b.id)]);
      expect(rows.map((r) => r['amount']), [0.01, 999999999.99]);
      await LancamentoService.carregar(force: true);
      final lidoB = LancamentoService.getReceitas().singleWhere((l) => l.id == b.id);
      expect(lidoB.valor, 999999999.99);
      expect(Fmt.brl(lidoB.valor), 'R\$ 999.999.999,99');
    });

    caso('CT-INT-16', 'datas especiais (29/02, virada de ano) chegam iguais ao SQLite, ao filtro por mês e ao app', () async {
      final datas = ['2028-02-29', '2026-12-31', '2027-01-01'];
      final ids = <String>[];
      for (final d in datas) {
        ids.add((await LancamentoService.adicionar(_lanc('Data $d', 10, d, _d, 'Outros'))).id);
      }
      final rows = await srv.sql('SELECT date FROM expenses WHERE id IN (${ids.join(',')}) ORDER BY id');
      expect(rows.map((r) => r['date']), datas);
      final fev = await ApiClient.get('/expenses?month=2028-02') as List;
      expect(fev.map((e) => e['date']), ['2028-02-29']);
      await LancamentoService.carregar(force: true);
      for (var i = 0; i < ids.length; i++) {
        expect(LancamentoService.getDespesas().singleWhere((l) => l.id == ids[i]).dataApi, datas[i]);
      }
    });

    caso('CT-INT-17', 'erro de validação da API chega ao app como ApiException e nada é gravado', () async {
      final antes = (await srv.sql('SELECT COUNT(*) AS n FROM incomes')).single['n'];
      final cache = LancamentoService.getAll().length;
      await expectLater(
        LancamentoService.adicionar(_lanc('Negativo', -10, '2026-11-01', _r, 'Outros')),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'amount deve ser um número positivo')),
      );
      expect((await srv.sql('SELECT COUNT(*) AS n FROM incomes')).single['n'], antes);
      expect(LancamentoService.getAll().length, cache);
    });

    caso('CT-INT-18', 'categoria excluída em outro aparelho: o app ainda consegue lançar nessa categoria', () async {
      final uid = await _idUsuario('carla@teste.local');
      final assinaturas = (await srv.sql("SELECT id FROM categories WHERE user_id = ? AND name = 'Assinaturas'", [uid])).single['id'];
      // O app já tem "Assinaturas" no cache (CategoriaService.carregar no setUp).
      expect(CategoriaService.nomes(_d), contains('Assinaturas'));
      final status = await _outroAparelho('DELETE', '/categories/$assinaturas', (await _tokenSalvo())!);
      expect(status, 204);
      final criado = await LancamentoService.adicionar(_lanc('Streaming', 39.9, '2026-11-08', _d, 'Assinaturas'));
      final row = (await srv.sql(
        'SELECT c.name FROM expenses e JOIN categories c ON c.id = e.category_id WHERE e.id = ?', [int.parse(criado.id)])).single;
      expect(row['name'], 'Assinaturas');
    });
  });

  // ── Metas ──────────────────────────────────────────────────────
  group('Metas', () {
    setUp(() => AuthService.login(email: 'carla@teste.local', senha: 'senha123'));

    caso('CT-INT-19', 'criar meta no app grava no SQLite e o app lê o progresso correto', () async {
      await MetaService.criar(titulo: 'Viagem à Bahia', valorMeta: 5000, valorInicial: 1250, icone: 'flight');
      final row = (await srv.sql("SELECT title, target_amount, current_amount, icon FROM goals WHERE title = 'Viagem à Bahia'")).single;
      expect(row, {'title': 'Viagem à Bahia', 'target_amount': 5000, 'current_amount': 1250, 'icon': 'flight'});
      final m = MetaService.metas.singleWhere((m) => m.titulo == 'Viagem à Bahia');
      expect([m.valorMeta, m.valorAtual, m.progresso, m.icone], [5000.0, 1250.0, 0.25, 'flight']);
    });

    caso('CT-INT-20', '5 aportes disparados ao mesmo tempo pelo app somam todos no SQLite', () async {
      final m = MetaService.metas.isEmpty ? (await MetaService.carregar()).first : MetaService.metas.first;
      final antes = (await srv.sql('SELECT current_amount FROM goals WHERE id = ?', [int.parse(m.id)])).single['current_amount'] as num;
      await Future.wait(List.generate(5, (_) => MetaService.aportar(m, 100)));
      final depois = (await srv.sql('SELECT current_amount FROM goals WHERE id = ?', [int.parse(m.id)])).single['current_amount'];
      expect(depois, antes + 500);
      await MetaService.carregar();
      expect(MetaService.metas.singleWhere((x) => x.id == m.id).valorAtual, antes + 500);
    });

    caso('CT-INT-21', 'excluir meta no app apaga a linha do SQLite', () async {
      final m = (await MetaService.carregar()).first;
      await MetaService.remover(m.id);
      expect(await srv.sql('SELECT id FROM goals WHERE id = ?', [int.parse(m.id)]), isEmpty);
      expect(MetaService.metas.where((x) => x.id == m.id), isEmpty);
    });
  });

  // ── Arquitetura: banco, persistência e disponibilidade ─────────
  group('Banco, persistência e disponibilidade', () {
    caso('CT-INT-22', 'integridade referencial do SQLite está ativa (foreign_keys e RESTRICT)', () async {
      expect((await srv.sql('PRAGMA foreign_keys')).single['foreign_keys'], 1);
      final usada = (await srv.sql('SELECT category_id FROM expenses LIMIT 1')).single['category_id'];
      final r = await srv.exec('DELETE FROM categories WHERE id = ?', [usada]);
      expect(r['error'], contains('FOREIGN KEY constraint failed'));
      expect(await srv.sql('SELECT id FROM categories WHERE id = ?', [usada]), hasLength(1));
      final fks = await srv.sql("SELECT \"table\", \"on_delete\" FROM pragma_foreign_key_list('expenses') ORDER BY \"table\"");
      expect(fks, [{'table': 'categories', 'on_delete': 'RESTRICT'}, {'table': 'users', 'on_delete': 'CASCADE'}]);
    });

    caso('CT-INT-23', 'API reiniciada: os dados continuam no arquivo SQLite e a sessão do app continua válida', () async {
      await AuthService.login(email: 'carla@teste.local', senha: 'senha123');
      await LancamentoService.carregar(force: true);
      final antes = LancamentoService.getAll().map((l) => '${l.id}|${l.valor}|${l.dataApi}').toSet();
      final contagem = await srv.sql('SELECT (SELECT COUNT(*) FROM incomes) AS r, (SELECT COUNT(*) FROM expenses) AS d, (SELECT COUNT(*) FROM goals) AS m');
      await srv.parar();
      Rastro.atual?.nota('API derrubada e iniciada de novo sobre o mesmo arquivo: $bancoPrincipal');
      await srv.iniciar();
      expect(await srv.sql('SELECT (SELECT COUNT(*) FROM incomes) AS r, (SELECT COUNT(*) FROM expenses) AS d, (SELECT COUNT(*) FROM goals) AS m'), contagem);
      await _reabrirApp();
      expect(await AuthService.restaurarSessao(), isTrue);
      await LancamentoService.carregar(force: true);
      expect(LancamentoService.getAll().map((l) => '${l.id}|${l.valor}|${l.dataApi}').toSet(), antes);
    });

    caso('CT-INT-24', 'API fora do ar: o app recebe erro amigável, mantém o cache e volta a funcionar quando a API sobe', () async {
      await AuthService.login(email: 'carla@teste.local', senha: 'senha123');
      await LancamentoService.carregar(force: true);
      final cache = LancamentoService.getAll().length;
      await srv.parar();
      Rastro.atual?.nota('API derrubada.');
      await expectLater(
        LancamentoService.carregar(force: true),
        throwsA(isA<ApiException>().having((e) => e.message, 'message',
            'Não foi possível conectar ao servidor. Verifique o baseUrl e a rede.')),
      );
      expect(LancamentoService.getAll().length, cache);
      await srv.iniciar();
      Rastro.atual?.nota('API iniciada de novo.');
      await LancamentoService.carregar(force: true);
      expect(LancamentoService.getAll().length, cache);
    });

    caso('CT-INT-25', 'banco de versão anterior é migrado pela API e lido corretamente pelo app', () async {
      await srv.parar();
      final criar = await Process.run('node', ['$raiz/servidor/criar-banco-legado.js', bancoLegado]);
      Rastro.atual?.nota('Banco antigo criado (sem colunas de parcela, metas com emoji): ${criar.stdout.toString().trim()}');
      final legado = Servidor(bancoLegado);
      await legado.iniciar();
      try {
        final cols = (await legado.sql("SELECT name FROM pragma_table_info('incomes')")).map((c) => c['name']).toList();
        expect(cols, containsAll(['parcelado', 'parcela_grupo', 'parcela_numero', 'parcela_total']));
        await AuthService.login(email: 'legado@teste.local', senha: 'legado123');
        await LancamentoService.carregar(force: true);
        // Os lançamentos antigos (12/2025) ficam fora do cache da janela recente
        // e são lidos pela consulta paginada, como no Histórico "Tudo".
        final consulta = ConsultaLancamentos();
        await consulta.primeiraPagina;
        final ls = consulta.itens;
        consulta.dispose();
        expect(ls.map((l) => '${l.titulo}|${l.valor}|${l.dataApi}|${l.isParcela}').toList(),
            ['Aluguel antigo|1500.0|2025-12-10|false', 'Salário antigo|5000.0|2025-12-05|false']);
        final metas = await MetaService.carregar();
        expect({for (final m in metas) m.titulo: m.icone},
            {'Reserva': 'flag', 'Viagem': 'flight', 'Praia': 'flight', 'Sem ícone': 'flag'});
        final p = await LancamentoService.adicionar(_lanc('Sofá', 900, '2026-11-08', _d, 'Moradia'), parcelas: 3);
        expect((await legado.sql('SELECT COUNT(*) AS n FROM expenses WHERE parcela_grupo = ?', [p.parcelaGrupo])).single['n'], 3);
      } finally {
        File('$pastaEvidencias/api-log-legado.txt').writeAsStringSync(legado.log);
        await legado.parar();
        await srv.iniciar();
      }
    });
  });
}
