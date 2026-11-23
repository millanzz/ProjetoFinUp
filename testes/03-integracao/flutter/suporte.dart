// Suporte aos testes de integração Flutter + API + SQLite.
//
// - [Servidor]: sobe/derruba a API real (node servidor.js) apontando para um
//   ARQUIVO SQLite do teste, e consulta o banco pelo inspetor (porta+1).
// - [Rastro]: registra, para cada caso, as requisições HTTP feitas pela
//   camada de serviços do app (Flutter → API) e as consultas ao SQLite
//   (API → banco). Vira o arquivo de evidência evidencias/rastros/<caso>.md
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Pasta testes/03-integracao (os testes rodam com cwd = frontend).
final raiz = Directory('../testes/03-integracao').absolute.path;
final pastaEvidencias = '$raiz/evidencias';

// A porta da API vem do --dart-define=API_URL (fixo em 3999 no executar.sh).
const portaApi = 3999;
const portaInspetor = portaApi + 1;

/// Cliente de rede direto (fora do rastro do app), para o inspetor.
final _semRastro = IOClient();

class Servidor {
  Process? _proc;
  final String arquivoDb;
  final _log = StringBuffer();

  Servidor(this.arquivoDb);

  String get log => _log.toString();

  Future<void> iniciar() async {
    final p = await Process.start('node', ['$raiz/servidor/servidor.js', arquivoDb, '$portaApi']);
    _proc = p;
    final pronto = Completer<void>();
    p.stdout.transform(utf8.decoder).listen((s) {
      _log.write(s);
      if (s.contains('PRONTO') && !pronto.isCompleted) pronto.complete();
    });
    p.stderr.transform(utf8.decoder).listen(_log.write);
    await pronto.future.timeout(const Duration(seconds: 20));
  }

  /// Derruba o processo da API (como um servidor que caiu ou foi reiniciado).
  Future<void> parar() async {
    final p = _proc;
    if (p == null) return;
    p.kill();
    await p.exitCode.timeout(const Duration(seconds: 10), onTimeout: () => -1);
    _proc = null;
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<dynamic> _inspetor(String rota, Map<String, dynamic> corpo) async {
    final r = await _semRastro.post(
      Uri.parse('http://127.0.0.1:$portaInspetor$rota'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(corpo),
    );
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  /// SELECT no SQLite (mesma conexão da API). Também entra no rastro.
  Future<List<Map<String, dynamic>>> sql(String consulta, [List<Object?> params = const []]) async {
    final r = await _inspetor('/sql', {'sql': consulta, 'params': params});
    if (r is Map) throw StateError('SQL falhou: ${r['error']}');
    final linhas = [for (final l in r as List) Map<String, dynamic>.from(l as Map)];
    Rastro.atual?.sql(consulta, params, linhas);
    return linhas;
  }

  /// Escrita direta no banco (simula outro cliente). Também entra no rastro.
  Future<Map<String, dynamic>> exec(String comando, [List<Object?> params = const []]) async {
    final r = Map<String, dynamic>.from(await _inspetor('/exec', {'sql': comando, 'params': params}) as Map);
    Rastro.atual?.nota('Ação direta no SQLite (outro cliente): `$comando` $params → ${jsonEncode(r)}');
    return r;
  }

  Future<String> token({required int id, String? email, int? expiradoHaSegundos}) async {
    final r = await _inspetor('/token', {'id': id, 'email': email, 'expiradoHaSegundos': expiradoHaSegundos});
    return (r as Map)['token'] as String;
  }
}

/// Esconde segredos no rastro (senhas e tokens).
Object? _mascarar(Object? v) {
  if (v is Map) {
    return {
      for (final e in v.entries)
        e.key: (const {'password', 'current_password', 'new_password'}.contains(e.key))
            ? '***'
            : (e.key == 'token' && e.value is String)
                ? '${(e.value as String).substring(0, 12)}…(JWT)'
                : _mascarar(e.value),
    };
  }
  if (v is List) return [for (final x in v) _mascarar(x)];
  return v;
}

String _json(Object? v) => const JsonEncoder.withIndent('  ').convert(_mascarar(v));

/// Registro de evidências de um caso de teste.
class Rastro {
  static Rastro? atual;
  final String caso;
  final String titulo;
  final _md = StringBuffer();
  int _n = 0;

  Rastro(this.caso, this.titulo) {
    _md
      ..writeln('# $caso — $titulo')
      ..writeln()
      ..writeln('Gerado em ${DateTime.now().toIso8601String()}')
      ..writeln();
  }

  void nota(String texto) => _md
    ..writeln('> $texto')
    ..writeln();

  void http(String metodo, String url, Object? corpo, int status, Object? resposta) {
    _n++;
    _md
      ..writeln('### ${_n.toString().padLeft(2, '0')}. Flutter → API: `$metodo ${Uri.parse(url).path}${Uri.parse(url).hasQuery ? '?${Uri.parse(url).query}' : ''}` → **$status**')
      ..writeln();
    if (corpo != null) {
      _md
        ..writeln('Enviado pelo app:')
        ..writeln('```json')
        ..writeln(_json(corpo))
        ..writeln('```');
    }
    if (resposta != null) {
      _md
        ..writeln('Resposta da API:')
        ..writeln('```json')
        ..writeln(_json(resposta))
        ..writeln('```');
    }
    _md.writeln();
  }

  void sql(String consulta, List<Object?> params, List<Map<String, dynamic>> linhas) {
    _n++;
    _md
      ..writeln('### ${_n.toString().padLeft(2, '0')}. Conferência no SQLite')
      ..writeln()
      ..writeln('```sql')
      ..writeln('${consulta.trim()}${params.isEmpty ? '' : '   -- params: $params'}')
      ..writeln('```')
      ..writeln('```json')
      ..writeln(_json(linhas))
      ..writeln('```')
      ..writeln();
  }

  void resultado(String status, [String? erro]) {
    _md
      ..writeln('---')
      ..writeln()
      ..writeln('**Resultado: $status**');
    if (erro != null) {
      _md
        ..writeln()
        ..writeln('```')
        ..writeln(erro.trim())
        ..writeln('```');
    }
    final dir = Directory('$pastaEvidencias/rastros')..createSync(recursive: true);
    File('${dir.path}/$caso.md').writeAsStringSync(_md.toString());
  }
}

/// Cliente HTTP que repassa as chamadas do app para a rede real e anota
/// cada uma no rastro do caso atual.
class ClienteRastreado extends http.BaseClient {
  final http.Client _interno = IOClient();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    Object? corpo;
    if (request is http.Request && request.body.isNotEmpty) {
      try {
        corpo = jsonDecode(request.body);
      } catch (_) {
        corpo = request.body;
      }
    }
    final resp = await _interno.send(request);
    final bytes = await resp.stream.toBytes();
    Object? json;
    final texto = utf8.decode(bytes, allowMalformed: true);
    if (texto.isNotEmpty) {
      try {
        json = jsonDecode(texto);
      } catch (_) {
        json = texto;
      }
    }
    Rastro.atual?.http(request.method, request.url.toString(), corpo, resp.statusCode, json);
    return http.StreamedResponse(
      Stream.value(bytes),
      resp.statusCode,
      headers: resp.headers,
      request: request,
      reasonPhrase: resp.reasonPhrase,
      contentLength: bytes.length,
    );
  }
}
