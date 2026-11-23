// FASE 3 — reabrir o app depois de ter saído da conta (e de outro reinício da API).
// O app deve abrir no login, com o tema salvo, e os dados devem estar todos
// lá quando a pessoa entra de novo.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/core/theme_controller.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/services/api_client.dart';
import 'package:FinUp/services/auth_service.dart';
import 'package:FinUp/services/lancamento_service.dart';
import 'suporte.dart';

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(prepararAparelho);

  testWidgets('FASE 3 — reabrir após sair da conta', (t) async {
    cabecalhoFase('Fase 3 — app reaberto depois de sair da conta',
        'Processo novo do app e a API reiniciada mais uma vez. O app deve abrir no login, mantendo o tema, e os dados devem estar intactos ao entrar.');
    final esperado = jsonDecode(arquivoEsperado.readAsStringSync()) as Map<String, dynamic>;

    await ThemeController.carregar();
    conferir('Tema continua escuro', ThemeController.mode.value.name, 'dark');
    final logado = await AuthService.restaurarSessao();
    conferir('Sem token no aparelho: abre no login (não restaura sessão)', logado, false);

    await telaDeCelular(t);
    await t.pumpWidget(comTela(FinanceiroApp(logado: logado)));
    await esperar(t, find.text('Entrar na sua conta'));
    await assentar(t, 800);
    await salvarTela(t, 'fase3-login-tema-escuro');
    diario('| ✅ | App abriu na tela de login, no tema escuro | tela de login | `telas/fase3-login-tema-escuro.png` |');

    await AuthService.login(email: 'paula@teste.local', senha: 'definitiva9');
    conferir('Login com a senha trocada na fase 1', AuthService.nome, 'Paula M. Ribeiro');
    await LancamentoService.carregar(force: true);
    for (final (chave, rota) in [
      ('receitas', '/incomes'),
      ('despesas', '/expenses'),
      ('metas', '/goals'),
      ('categorias', '/categories'),
      ('dashboard', '/dashboard'),
    ]) {
      conferir('`$rota` idêntico ao da fase 1', await ApiClient.get(rota), esperado[chave]);
    }
    conferir('Saldo no app igual ao da fase 1', LancamentoService.saldo, esperado['saldo_no_app']);
    conferir('Integridade do arquivo SQLite', await sql('PRAGMA integrity_check'), [{'integrity_check': 'ok'}]);
    AuthService.logout();
    await assentar(t, 300);
  });
}
