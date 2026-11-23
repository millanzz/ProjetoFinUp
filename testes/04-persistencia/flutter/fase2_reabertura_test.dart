// FASE 2 — reabertura a frio, depois de reiniciar a API.
// Processo novo: a memória do app começa vazia. Repete o que o main() do app
// faz ao abrir (carrega o tema, restaura a sessão, carrega os dados) e compara
// TUDO com o estado guardado na fase 1. No fim, sai da conta.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:FinUp/core/api_config.dart';
import 'package:FinUp/core/theme_controller.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/services/api_client.dart';
import 'package:FinUp/services/auth_service.dart';
import 'package:FinUp/services/categoria_service.dart';
import 'package:FinUp/services/lancamento_service.dart';
import 'package:FinUp/services/meta_service.dart';
import 'suporte.dart';

Future<int> _loginStatus(String email, String senha) async {
  final r = await IOClient().post(Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': senha}));
  return r.statusCode;
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(prepararAparelho);

  testWidgets('FASE 2 — reabrir o app após reiniciar a API', (t) async {
    cabecalhoFase('Fase 2 — app reaberto do zero, API reiniciada',
        'Processo novo do app (memória vazia) e API derrubada e iniciada de novo sobre o mesmo arquivo SQLite. Repete o que o `main()` faz ao abrir o app.');
    final esperado = jsonDecode(arquivoEsperado.readAsStringSync()) as Map<String, dynamic>;
    conferir('Memória do app começa vazia (sem sessão)', AuthService.isLogged(), false);

    // Arquivo do aparelho
    final prefs = preferenciasNoDisco();
    conferir('Arquivo do aparelho ainda tem o tema', prefs['flutter.theme_mode'], 'dark');
    conferir('Arquivo do aparelho ainda tem o token', prefs.containsKey('flutter.auth_token'), true);

    // Igual ao main(): tema → sessão → dados
    await ThemeController.carregar();
    conferir('Tema restaurado ao abrir', ThemeController.mode.value.name, 'dark');
    final logado = await AuthService.restaurarSessao();
    conferir('Sessão restaurada sem pedir login', logado, true);
    conferir('Nome editado continua (vindo do SQLite)', AuthService.nome, 'Paula M. Ribeiro');
    await LancamentoService.carregar(force: true);
    await CategoriaService.carregar(force: true);
    await MetaService.carregar();

    // Dados: cada lista igual à da fase 1, campo a campo (ids, valores, datas, created_at…)
    for (final (chave, rota) in [
      ('usuario', '/users/me'),
      ('categorias', '/categories'),
      ('receitas', '/incomes'),
      ('despesas', '/expenses'),
      ('metas', '/goals'),
      ('dashboard', '/dashboard'),
      ('dashboard_mes', '/dashboard?month=${esperado['mes']}'),
    ]) {
      conferir('`$rota` idêntico ao de antes do reinício', await ApiClient.get(rota), esperado[chave]);
    }
    conferir('Saldo calculado pelo app igual ao de antes', LancamentoService.saldo, esperado['saldo_no_app']);
    conferir('Metas no app', [for (final m in MetaService.metas) '${m.titulo}|${m.valorAtual}|${m.icone}'],
        [for (final m in esperado['metas'] as List) '${m['title']}|${(m['current_amount'] as num).toDouble()}|${m['icon']}']);

    // O que foi excluído continua excluído
    final ex = esperado['excluidos'] as Map<String, dynamic>;
    conferir('Despesa excluída (Cinema) continua fora do SQLite',
        await sql('SELECT id FROM expenses WHERE id = ?', [ex['despesa_cinema']]), []);
    conferir('Parcela 2 excluída continua fora do SQLite',
        await sql('SELECT id FROM expenses WHERE id = ?', [ex['parcela_2_notebook']]), []);
    conferir('Meta excluída (Carro) continua fora do SQLite',
        await sql('SELECT id FROM goals WHERE id = ?', [ex['meta_carro']]), []);
    conferir('Categoria criada pelo usuário (Projetos) persistiu',
        await sql("SELECT type FROM categories WHERE name = 'Projetos'"), [{'type': 'income'}]);

    // Senha trocada continua valendo
    conferir('Senha nova entra', await _loginStatus('paula@teste.local', 'definitiva9'), 200);
    conferir('Senha antiga continua recusada', await _loginStatus('paula@teste.local', 'inicial1'), 401);

    // A tela inicial reaberta deve ser idêntica, pixel a pixel, à da fase 1
    await telaDeCelular(t);
    await t.pumpWidget(comTela(const FinanceiroApp(logado: true)));
    await esperar(t, find.textContaining(', Paula'));
    await assentar(t, 1500);
    await salvarTela(t, 'fase2-inicio-depois');
    await expectLater(find.byKey(telaKey), matchesGoldenFile('../evidencias/telas/inicio-referencia.png'));
    diario('| ✅ | Tela inicial reaberta idêntica, pixel a pixel, à da fase 1 | `inicio-referencia.png` | `fase2-inicio-depois.png` |');

    // Sair da conta: o token deve sair do disco; o tema deve ficar
    AuthService.logout();
    await assentar(t, 500);
    final depois = preferenciasNoDisco();
    conferir('Após sair, o token foi apagado do arquivo do aparelho', depois.containsKey('flutter.auth_token'), false);
    conferir('Após sair, o tema continua no arquivo do aparelho', depois['flutter.theme_mode'], 'dark');
  });
}
