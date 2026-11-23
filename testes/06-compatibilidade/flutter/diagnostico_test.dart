// Diagnóstico: para os perfis que falharam no compat_test, mostra QUAL widget
// do app estourou (arquivo:linha), para o relatório.
// Rodar (na pasta frontend, com a API de teste na 3999):
//   flutter test ../testes/06-compatibilidade/flutter/diagnostico_test.dart --dart-define=API_URL=http://127.0.0.1:3999
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/services/auth_service.dart';
import 'package:FinUp/services/lancamento_service.dart';
import '../../02-funcionais/app/suporte.dart' show prepararAmbiente, esperar, assentar;

final saida = File('${Directory('../testes/06-compatibilidade/evidencias').absolute.path}/diagnostico-overflow.txt');

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await prepararAmbiente();
    await AuthService.login(email: 'compat@teste.local', senha: 'senha123');
    await LancamentoService.carregar(force: true);
    saida.writeAsStringSync('Diagnóstico de overflow — ${DateTime.now().toIso8601String()}\n');
  });

  for (final (rotulo, w, h, fonte, logado) in [
    ('A01 Galaxy Z Fold externa 280×653 · login', 280.0, 653.0, 1.0, false),
    ('B02 Android pequeno 360×640 · fonte 200% · login', 360.0, 640.0, 2.0, false),
    ('B02 Android pequeno 360×640 · fonte 200% · início', 360.0, 640.0, 2.0, true),
    ('B06 Pixel 7 412×915 · fonte 200% · login', 412.0, 915.0, 2.0, false),
  ]) {
    testWidgets(rotulo, (t) async {
      await t.binding.setSurfaceSize(Size(w, h));
      final achados = <String>{};
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        final txt = d.toString();
        final local = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(txt)?.group(0);
        final dono = RegExp(r'creator: (\w+) ← (\w+) ← (\w+) ← (\w+) ← (\w+)').firstMatch(txt);
        final widget = [
          if (local != null) local,
          if (dono != null) 'criado em ${[for (var i = 1; i <= 5; i++) dono.group(i)].join(' ← ')}',
        ].join(' · ');
        achados.add('${d.exceptionAsString().split('\n').first}  ←  $widget');
      };
      try {
        await t.pumpWidget(MediaQuery(
          data: MediaQueryData(size: Size(w, h), textScaler: TextScaler.linear(fonte)),
          child: FinanceiroApp(logado: logado),
        ));
        await esperar(t, find.text(logado ? 'Início' : 'Entrar na sua conta'));
        await assentar(t, 800);
      } finally {
        FlutterError.onError = original;
        await t.pumpWidget(const SizedBox());
        await t.binding.setSurfaceSize(null);
      }
      saida.writeAsStringSync('\n## $rotulo\n${achados.map((a) => '- $a').join('\n')}\n', mode: FileMode.append);
    });
  }
}
