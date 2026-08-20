import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';

/// Erro de API com mensagem amigável (vinda do backend quando possível).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Cliente HTTP central do app.
/// Cuida do token JWT (persistido no shared_preferences),
/// dos headers, do timeout e da decodificação das respostas.
class ApiClient {
  ApiClient._();

  static const String _tokenKey = 'auth_token';
  static String? _token;

  static bool get temToken => _token != null && _token!.isNotEmpty;

  static Future<void> carregarToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  static Future<void> salvarToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> limparToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (temToken) 'Authorization': 'Bearer $_token',
      };

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<dynamic> get(String path) =>
      _executar(() => http.get(_uri(path), headers: _headers));

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _executar(() => http.post(
            _uri(path),
            headers: _headers,
            body: jsonEncode(body ?? {}),
          ));

  static Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _executar(() => http.put(
            _uri(path),
            headers: _headers,
            body: jsonEncode(body ?? {}),
          ));

  static Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _executar(() => http.patch(
            _uri(path),
            headers: _headers,
            body: jsonEncode(body ?? {}),
          ));

  static Future<dynamic> delete(String path) =>
      _executar(() => http.delete(_uri(path), headers: _headers));

  static Future<dynamic> _executar(
    Future<http.Response> Function() requisicao,
  ) async {
    http.Response resposta;

    try {
      resposta = await requisicao().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException(
        'O servidor demorou para responder. Ele está rodando?',
      );
    } catch (_) {
      throw ApiException(
        'Não foi possível conectar ao servidor. Verifique o baseUrl e a rede.',
      );
    }

    dynamic dados;
    if (resposta.body.isNotEmpty) {
      try {
        dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      } catch (_) {
        dados = null;
      }
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return dados;
    }

    final mensagem = (dados is Map && dados['error'] != null)
        ? dados['error'].toString()
        : 'Erro ${resposta.statusCode} ao comunicar com o servidor';

    throw ApiException(mensagem, statusCode: resposta.statusCode);
  }
}
