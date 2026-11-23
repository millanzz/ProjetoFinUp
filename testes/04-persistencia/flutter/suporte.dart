// Suporte dos testes de persistência.
//
// Diferente das baterias anteriores, aqui o "aparelho" NÃO é simulado em
// memória: o app grava as preferências (token de login e tema) num arquivo
// JSON de verdade, usando a implementação Windows do shared_preferences, só
// que numa pasta do teste (evidencias/aparelho) em vez do AppData.
//
// Cada fase roda num PROCESSO separado (flutter test), então tudo o que estava
// na memória do app some entre uma fase e outra — como fechar e abrir o app.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

final raiz = Directory('../testes/04-persistencia').absolute.path;
final ev = '$raiz/evidencias';
final pastaAparelho = '$ev/aparelho';
final arquivoPreferencias = File('$pastaAparelho/shared_preferences.json');
final arquivoEsperado = File('$ev/estado-antes-de-reiniciar.json');
const portaInspetor = 4000;

/// Pasta de dados do "aparelho" usada pelo shared_preferences do Windows.
class _PastaDoAparelho extends PathProviderWindows {
  @override
  Future<String?> getApplicationSupportPath() async {
    Directory(pastaAparelho).createSync(recursive: true);
    return pastaAparelho;
  }
}

const _fontes = r'C:\flutter\bin\cache\artifacts\material_fonts';

/// Liga o armazenamento real em disco, a rede real e as fontes das capturas.
Future<void> prepararAparelho() async {
  HttpOverrides.global = null;
  SharedPreferencesStorePlatform.instance = SharedPreferencesWindows()..pathProvider = _PastaDoAparelho();
  GoogleFonts.config.allowRuntimeFetching = false;

  final icones = File('$_fontes\\materialicons-regular.otf').readAsBytesSync();
  await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icones)))).load();
  _servirAssetsComRoboto();
  for (final w in FontWeight.values) {
    GoogleFonts.roboto(fontWeight: w);
  }
  await GoogleFonts.pendingFonts();
}

/// O google_fonts procura "Roboto-*.ttf" nos assets; serve as Roboto do Flutter.
void _servirAssetsComRoboto() {
  const roboto = {
    'Thin': 'roboto-thin.ttf', 'ExtraLight': 'roboto-light.ttf', 'Light': 'roboto-light.ttf',
    'Regular': 'roboto-regular.ttf', 'Medium': 'roboto-medium.ttf', 'SemiBold': 'roboto-medium.ttf',
    'Bold': 'roboto-bold.ttf', 'ExtraBold': 'roboto-black.ttf', 'Black': 'roboto-black.ttf',
  };
  final base = Directory('build/unit_test_assets').absolute.path;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (msg) async {
    final chave = Uri.decodeFull(utf8.decode(msg!.buffer.asUint8List(msg.offsetInBytes, msg.lengthInBytes)));
    if (chave == 'AssetManifest.bin') {
      final mapa = Map<Object?, Object?>.from(const StandardMessageCodec()
          .decodeMessage(ByteData.sublistView(File('$base/AssetManifest.bin').readAsBytesSync())) as Map);
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

/// Conteúdo atual do arquivo de preferências no disco (o que sobrevive ao app fechar).
Map<String, dynamic> preferenciasNoDisco() =>
    arquivoPreferencias.existsSync() ? jsonDecode(arquivoPreferencias.readAsStringSync()) as Map<String, dynamic> : {};

final _rede = IOClient();

/// Consulta direta ao SQLite pelo inspetor da API de teste.
Future<List<Map<String, dynamic>>> sql(String consulta, [List<Object?> params = const []]) async {
  final r = await _rede.post(Uri.parse('http://127.0.0.1:$portaInspetor/sql'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode({'sql': consulta, 'params': params}));
  final dados = jsonDecode(utf8.decode(r.bodyBytes));
  if (dados is Map) throw StateError('SQL falhou: ${dados['error']}');
  return [for (final l in dados as List) Map<String, dynamic>.from(l as Map)];
}

/// Diário da execução: cada fase acrescenta o que verificou.
void diario(String linha) {
  File('$ev/diario.md').writeAsStringSync('$linha\n', mode: FileMode.append);
}

/// Confere e anota no diário (✅ / ❌) antes de falhar.
void conferir(String descricao, Object? obtido, Object? esperado) {
  final ok = jsonEncode(obtido) == jsonEncode(esperado);
  final resumo = (Object? v) {
    final s = jsonEncode(v);
    return s.length > 160 ? '${s.substring(0, 157)}…' : s;
  };
  diario('| ${ok ? '✅' : '❌'} | $descricao | `${resumo(esperado)}` | `${resumo(obtido)}` |');
  expect(jsonEncode(obtido), jsonEncode(esperado), reason: descricao);
}

void cabecalhoFase(String titulo, String descricao) {
  diario('\n## $titulo\n\n$descricao\n\n_Início: ${DateTime.now().toIso8601String()} · processo ${pid}_\n');
  diario('| | Verificação | Esperado | Obtido |\n|---|---|---|---|');
}

// ── Captura de tela ─────────────────────────────────────────────
final telaKey = GlobalKey(debugLabel: 'tela');
Widget comTela(Widget app) => RepaintBoundary(key: telaKey, child: app);

Future<void> telaDeCelular(WidgetTester t) async {
  await t.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() => t.binding.setSurfaceSize(null));
}

Future<void> assentar(WidgetTester t, [int ms = 900]) async {
  final fim = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(fim)) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> esperar(WidgetTester t, Finder f, {int segundos = 20}) async {
  final fim = DateTime.now().add(Duration(seconds: segundos));
  while (DateTime.now().isBefore(fim)) {
    await t.pump(const Duration(milliseconds: 100));
    if (f.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Tempo esgotado esperando: $f');
}

/// Salva a tela atual como PNG (sem comparar).
Future<void> salvarTela(WidgetTester t, String nome) async {
  await assentar(t, 400);
  final boundary = telaKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final img = await boundary.toImage(pixelRatio: 1);
  final png = await img.toByteData(format: ImageByteFormat.png);
  File('$ev/telas/$nome.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}
