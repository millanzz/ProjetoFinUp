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
import 'package:FinUp/services/categoria_service.dart';
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
    r['lancamentos_no_app'] = LancamentoService.getAll().length;
    salvar();

    // 2) Recarregar todos os lançamentos (o que acontece a cada troca de aba)
    final cargas = <double>[];
    for (var i = 0; i < 5; i++) {
      sw = Stopwatch()..start();
      await LancamentoService.carregar(force: true);
      cargas.add(_ms(sw));
    }
    r['recarga_mediana_ms'] = _mediana(cargas);
    r['recarga_ms'] = cargas;
    salvar();

    // 3) Separar rede × processamento no app (JSON → modelos)
    final token = (await SharedPreferences.getInstance()).getString('auth_token')!;
    final rede = <double>[], proc = <double>[];
    var bytes = 0;
    for (var i = 0; i < 3; i++) {
      sw = Stopwatch()..start();
      final cli = IOClient();
      final h = {'Authorization': 'Bearer $token'};
      final rs = await Future.wait([
        cli.get(Uri.parse('${ApiConfig.baseUrl}/incomes'), headers: h),
        cli.get(Uri.parse('${ApiConfig.baseUrl}/expenses'), headers: h),
      ]);
      rede.add(_ms(sw));
      bytes = rs[0].bodyBytes.length + rs[1].bodyBytes.length;
      sw = Stopwatch()..start();
      final rec = (jsonDecode(utf8.decode(rs[0].bodyBytes)) as List)
          .map((m) => LancamentoModel.fromApi(Map<String, dynamic>.from(m as Map), TipoLancamento.receita));
      final des = (jsonDecode(utf8.decode(rs[1].bodyBytes)) as List)
          .map((m) => LancamentoModel.fromApi(Map<String, dynamic>.from(m as Map), TipoLancamento.despesa));
      final todos = [...rec, ...des]..sort((a, b) => b.data.compareTo(a.data));
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
    final tudo = <double>[];
    for (var i = 0; i < 3; i++) {
      for (final filtro in ['Tudo', 'Este mês']) {
        sw = Stopwatch()..start();
        await t.tap(find.text(filtro).last, warnIfMissed: false);
        await t.pump();
        if (filtro == 'Tudo') {
          tudo.add(_ms(sw));
          r['historico_tudo_ms'] = tudo;
          r['historico_tudo_mediana_ms'] = _mediana(tudo);
          salvar();
        }
      }
      if (tudo.first > lento) break;
    }
    r['historico_tudo_mediana_ms'] = _mediana(tudo);
    r['historico_tudo_ms'] = tudo;

    r['concluido'] = true;
    salvar();
    // ignore: avoid_print
    print('RESULTADO $cenario ${jsonEncode(r)}');
  }, timeout: const Timeout(Duration(minutes: 90)));
}
