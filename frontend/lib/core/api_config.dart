import 'package:flutter/foundation.dart';

/// Configuração central da API.
///
/// IMPORTANTE — ajuste o [baseUrl] conforme onde o app está rodando:
///
/// • Emulador Android  -> http://10.0.2.2:3000
///   (10.0.2.2 é o "localhost" da sua máquina visto de dentro do emulador)
///
/// • Celular físico    -> http://SEU_IP_NA_REDE:3000
///   (ex: http://192.168.0.10:3000 — descubra o IP com `ipconfig`/`ifconfig`.
///    O celular e o PC precisam estar na MESMA rede Wi-Fi)
///
/// • Flutter Web / Desktop -> http://localhost:3000
class ApiConfig {
  ApiConfig._();

  /// Pode ser trocado sem editar o código:
  /// `flutter run --dart-define=API_URL=http://localhost:3000`
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Produção exige HTTPS. Em build release, só endereços https:// são aceitos
  /// (o ApiClient recusa enviar senha e token por HTTP). Em debug/testes, HTTP
  /// continua liberado para o servidor local.
  ///
  /// Build de produção:  flutter build apk --release --dart-define=API_URL=https://api.seudominio.com.br
  static bool get conexaoSegura => !kReleaseMode || baseUrl.startsWith('https://');
}
