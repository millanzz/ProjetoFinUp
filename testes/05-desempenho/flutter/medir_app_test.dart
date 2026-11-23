// Mede o desempenho do lado do APP para um cenário (a API do cenário precisa
// estar rodando). Usa o código real do app: serviços e telas.
//
// Rodar (na pasta frontend):
//   flutter test ../testes/05-desempenho/flutter/medir_app_test.dart \
//     --dart-define=API_URL=http://127.0.0.1:3999 --dart-define=CENARIO=V3
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FinUp/core/api_config.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/models/lancamento_model.dart';
import 'package:FinUp/services/auth_service.dart';
import 'package:FinUp/services/api_client.dart';
import 'package:FinUp/services/categoria_service.dart';
import 'package:FinUp/services/consulta_lancamentos.dart';
import 'package:FinUp/services/lancamento_service.dart';
import '../../02-funcionais/app/suporte.dart' show prepararAmbiente, telaDeCelular, comTela, esperar;

const cenario = String.fromEnvironment('CENARIO', defaultValue: 'sem-nome');
final saida = File('${Directory('../testes/05-desempenho/evidencias/resultados').absolute.path}/app-$cenario.json');

double _ms(Stopwatch s) => (s.elapsedMicroseconds / 100).round() / 10;
double _mediana(List<double> v) => (List.of(v)..sort())[v.length ~/ 2];

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(prepararAmbiente);

  testWidgets('desempenho do app — cenário $cenario', (t) async {
    final r = <String, Object>{'cenario': cenario, 'medido_em': DateTime.now().toIso8601String()};
    void salvar() => saida
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(r));
    // Passos que passam de 30 s não são repetidos (o tempo já está registrado).
    const lento = 30000.0;

    // 1) Entrar: o que a tela de login faz (login + carregar lançamentos e categorias)
    var sw = Stopwatch()..start();
    await AuthService.login(email: 'perf@teste.local', senha: 'senha123');
    await Future.wait([LancamentoService.carregar(force: true), CategoriaService.carregar(force: true)]);
    r['entrar_ms'] = _ms(sw);
    // Desde a paginação o aparelho guarda só o mês atual em diante
    r['lancamentos_no_app'] = LancamentoService.getAll().length;
    final totalUsuario = ((await ApiClient.get('/lancamentos?limit=0')) as Map)['total'] as int;
    r['lancamentos_do_usuario'] = totalUsuario;
    salvar();

    // 2) Recarregar o cache (mês atual em diante; o que a troca de aba faz se o
    //    cache tiver mais de 1 min)
    final cargas = <double>[];
    for (var i = 0; i < 5; i++) {
      sw = Stopwatch()..start();
      await LancamentoService.carregar(force: true);
      cargas.add(_ms(sw));
    }
    r['recarga_mediana_ms'] = _mediana(cargas);
    r['recarga_ms'] = cargas;
    salvar();

    // 3) Separar rede × processamento no app (JSON → modelos), para o cache
    final token = (await SharedPreferences.getInstance()).getString('auth_token')!;
    final rede = <double>[], proc = <double>[];
    var bytes = 0;
    final base = '${ApiConfig.baseUrl}/lancamentos?from=${LancamentoService.dia(LancamentoService.janelaDesde)}'
        '&limit=${LancamentoService.tamanhoPaginaJanela}';
    for (var i = 0; i < 3; i++) {
      sw = Stopwatch()..start();
      final cli = IOClient();
      final h = {'Authorization': 'Bearer $token'};
      final corpos = <List<int>>[];
      Object? proximo = 0;
      while (proximo != null) {
        final resp = await cli.get(Uri.parse('$base&offset=$proximo'), headers: h);
        corpos.add(resp.bodyBytes);
        proximo = (jsonDecode(utf8.decode(resp.bodyBytes)) as Map)['proximo_offset'];
      }
      rede.add(_ms(sw));
      bytes = corpos.fold(0, (s, c) => s + c.length);
      sw = Stopwatch()..start();
      final todos = [
        for (final c in corpos)
          for (final m in (jsonDecode(utf8.decode(c)) as Map)['itens'] as List) LancamentoService.doExtrato(m as Map),
      ]..sort((a, b) => b.data.compareTo(a.data));
      proc.add(_ms(sw));
      expect(todos.length, LancamentoService.getAll().length);
      cli.close();
    }
    r['rede_mediana_ms'] = _mediana(rede);
    r['processamento_mediana_ms'] = _mediana(proc);
    r['kb_baixados_por_recarga'] = (bytes / 102.4).round() / 10;
    salvar();

    // 4) Abrir a tela inicial (primeiro quadro com os dados já carregados)
    await telaDeCelular(t);
    sw = Stopwatch()..start();
    await t.pumpWidget(comTela(const FinanceiroApp(logado: true)));
    r['abrir_inicio_primeiro_quadro_ms'] = _ms(sw);
    await esperar(t, find.textContaining('Saldo de'));
    r['abrir_inicio_ate_saldo_ms'] = _ms(sw);
    salvar();

    // 5) Trocar de aba (Despesas ↔ Início) até a tela redesenhar. Depois da
    //    correção do DEF-09 a troca só recarrega se o cache tiver mais de 1 min;
    //    se nenhuma recarga começar em 1 s, mede só o redesenho.
    final trocas = <double>[], primeiroQuadro = <double>[];
    for (var i = 0; i < 3; i++) {
      for (final aba in ['Despesas', 'Início']) {
        final rev = LancamentoService.revisao.value;
        sw = Stopwatch()..start();
        await t.tap(find.text(aba).last, warnIfMissed: false);
        await t.pump();
        primeiroQuadro.add(_ms(sw));
        while (LancamentoService.revisao.value == rev && sw.elapsed.inMilliseconds < 1000) {
          await t.pump(const Duration(milliseconds: 5));
        }
        await t.pump();
        // Sem recarga: o tempo da troca é o do primeiro quadro (a espera de 1 s não conta)
        trocas.add(LancamentoService.revisao.value == rev ? primeiroQuadro.last : _ms(sw));
        r['troca_aba_ms'] = trocas;
        salvar();
      }
      if (trocas.first > lento) break;
    }
    r['troca_aba_primeiro_quadro_mediana_ms'] = _mediana(primeiroQuadro);
    r['troca_aba_ate_atualizar_mediana_ms'] = _mediana(trocas);
    r['troca_aba_ms'] = trocas;
    salvar();

    // 6) Histórico com o filtro "Tudo" (a lista inteira na tela)
    final rev = LancamentoService.revisao.value;
    await t.tap(find.text('Histórico').last, warnIfMissed: false);
    final espera = Stopwatch()..start();
    while (LancamentoService.revisao.value == rev && espera.elapsedMilliseconds < 1000) {
      await t.pump(const Duration(milliseconds: 5));
    }
    await t.pump();
    // Mede até a tela mostrar a quantidade total (1ª página + totais da API).
    final contagem = find.text('$totalUsuario ${totalUsuario == 1 ? 'lançamento' : 'lançamentos'}');
    final tudo = <double>[];
    for (var i = 0; i < 3; i++) {
      for (final filtro in ['Tudo', 'Este mês']) {
        sw = Stopwatch()..start();
        await t.tap(find.text(filtro).last, warnIfMissed: false);
        await t.pump();
        if (filtro == 'Tudo') {
          while (contagem.evaluate().isEmpty && sw.elapsedMilliseconds < 60000) {
            await t.pump(const Duration(milliseconds: 5));
          }
          expect(contagem, findsOneWidget);
          tudo.add(_ms(sw));
          r['historico_tudo_ms'] = tudo;
          r['historico_tudo_mediana_ms'] = _mediana(tudo);
          salvar();
        }
      }
      if (tudo.first > lento) break;
    }

    // 7) "Carregar mais" no Histórico "Tudo": tempo de buscar e converter uma
    //    página (o que acontece quando o fim da lista aparece)
    final consulta = ConsultaLancamentos();
    await consulta.primeiraPagina;
    final paginas = <double>[];
    for (var i = 0; i < 3 && consulta.temMais; i++) {
      sw = Stopwatch()..start();
      await consulta.carregarMais();
      paginas.add(_ms(sw));
    }
    consulta.dispose();
    if (paginas.isNotEmpty) {
      r['historico_rolar_pagina_ms'] = paginas;
      r['historico_rolar_pagina_mediana_ms'] = _mediana(paginas);
    }
    r['historico_tudo_mediana_ms'] = _mediana(tudo);
    r['historico_tudo_ms'] = tudo;

    r['concluido'] = true;
    salvar();
    // ignore: avoid_print
    print('RESULTADO $cenario ${jsonEncode(r)}');
  }, timeout: const Timeout(Duration(minutes: 90)));
}
