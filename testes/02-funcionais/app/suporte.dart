// Suporte aos testes funcionais de interface.
//
// Os testes abrem as telas REAIS do app e conversam com a API REAL
// (subida por testes/02-funcionais/api/servidor.js com banco em memória).
// Para isso usamos o LiveTestWidgetsFlutterBinding (tempo e rede reais)
// e desligamos o bloqueio de HTTP que o flutter_test aplica por padrão.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:FinUp/core/api_config.dart';

const _fontes = r'C:\flutter\bin\cache\artifacts\material_fonts';

Future<void> _carregarFonte(String familia, String arquivo) async {
  final bytes = File('$_fontes\\$arquivo').readAsBytesSync();
  final loader = FontLoader(familia)..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// Prepara o ambiente: rede real, preferências zeradas e fontes reais
/// (Roboto e ícones Material) para que as capturas de tela fiquem legíveis.
Future<void> prepararAmbiente() async {
  HttpOverrides.global = null;
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});

  await _carregarFonte('MaterialIcons', 'materialicons-regular.otf');
  _servirAssetsComRoboto();
  // Carrega a Roboto antes da primeira tela; sem isso os primeiros quadros
  // usam a fonte de teste (glifos quadrados e largos) e acusam overflow falso.
  for (final w in FontWeight.values) {
    GoogleFonts.roboto(fontWeight: w);
  }
  await GoogleFonts.pendingFonts();
}

/// O google_fonts procura "Roboto-Bold.ttf" etc. nos assets do app. Como o
/// projeto não empacota essas fontes, este handler serve os assets normais
/// (build/unit_test_assets) e acrescenta as Roboto que vêm com o Flutter.
void _servirAssetsComRoboto() {
  const roboto = {
    'Thin': 'roboto-thin.ttf', 'ExtraLight': 'roboto-light.ttf', 'Light': 'roboto-light.ttf',
    'Regular': 'roboto-regular.ttf', 'Medium': 'roboto-medium.ttf', 'SemiBold': 'roboto-medium.ttf',
    'Bold': 'roboto-bold.ttf', 'ExtraBold': 'roboto-black.ttf', 'Black': 'roboto-black.ttf',
  };
  final base = Directory('build/unit_test_assets').absolute.path;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (msg) async {
    final chave = Uri.decodeFull(utf8.decode(msg!.buffer.asUint8List(msg.offsetInBytes, msg.lengthInBytes)));
    if (chave == 'AssetManifest.bin') {
      final bytes = File('$base/AssetManifest.bin').readAsBytesSync();
      final mapa = Map<Object?, Object?>.from(
          const StandardMessageCodec().decodeMessage(ByteData.sublistView(bytes)) as Map);
      for (final v in roboto.keys) {
        mapa['google_fonts/Roboto-$v.ttf'] = [
          {'asset': 'google_fonts/Roboto-$v.ttf'}
        ];
      }
      return const StandardMessageCodec().encodeMessage(mapa);
    }
    if (chave.startsWith('google_fonts/Roboto-')) {
      final v = chave.substring('google_fonts/Roboto-'.length).replaceAll('.ttf', '');
      return ByteData.sublistView(File('$_fontes\\${roboto[v]}').readAsBytesSync());
    }
    final f = File('$base/$chave');
    return f.existsSync() ? ByteData.sublistView(f.readAsBytesSync()) : null;
  });
}

/// Chamada direta à API de teste (fora da interface), para preparar dados
/// e conferir o resultado no servidor.
Future<dynamic> api(String metodo, String rota, {Map<String, dynamic>? body, String? token}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(metodo, Uri.parse('${ApiConfig.baseUrl}$rota'));
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    if (body != null) req.write(jsonEncode(body));
    final res = await req.close();
    final texto = await res.transform(utf8.decoder).join();
    return {'status': res.statusCode, 'body': texto.isEmpty ? null : jsonDecode(texto)};
  } finally {
    client.close();
  }
}

/// Cadastra um usuário direto pela API e devolve o token.
Future<String> criarUsuario(String nome, String email, String senha) async {
  await api('POST', '/users', body: {'name': nome, 'email': email, 'password': senha});
  final l = await api('POST', '/auth/login', body: {'email': email, 'password': senha});
  return l['body']['token'] as String;
}

/// Espera (com tempo real) até o [finder] aparecer na tela.
Future<void> esperar(WidgetTester t, Finder finder, {int segundos = 20}) async {
  final fim = DateTime.now().add(Duration(seconds: segundos));
  while (DateTime.now().isBefore(fim)) {
    await t.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Tempo esgotado esperando: $finder');
}

/// Deixa animações terminarem (com tempo real).
Future<void> assentar(WidgetTester t, [int ms = 900]) async {
  final fim = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(fim)) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// Campo de texto pelo rótulo do FinField (ex.: 'E-mail').
Finder campo(String rotulo) => find.descendant(
      of: find.ancestor(of: find.text(rotulo), matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == 'FinField')).first,
      matching: find.byType(TextField),
    );

/// Envolve o app numa RepaintBoundary para capturar só a tela do celular.
final telaKey = GlobalKey(debugLabel: 'tela');
Widget comTela(Widget app) => RepaintBoundary(key: telaKey, child: app);

/// Tamanho de um celular comum (412 × 915 dp, densidade 2,625).
Future<void> telaDeCelular(WidgetTester t) async {
  await t.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() => t.binding.setSurfaceSize(null));
}

/// Salva a tela atual como evidência (PNG em evidencias/telas).
Future<void> capturar(WidgetTester t, String nome) async {
  await assentar(t, 400);
  await expectLater(
    find.byKey(telaKey),
    matchesGoldenFile('../evidencias/telas/$nome.png'),
  );
}

/// Rola até o elemento (se preciso) e toca nele.
Future<void> tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await assentar(t, 250);
  await t.tap(f, warnIfMissed: false);
  await assentar(t, 300);
}

/// Digita num campo (com rolagem até ele).
Future<void> digitar(WidgetTester t, Finder f, String texto) async {
  await t.ensureVisible(f);
  await t.enterText(f, texto);
  await assentar(t, 150);
}

/// Data de hoje no formato da API (os lançamentos aparecem no mês atual).
String hojeApi() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
