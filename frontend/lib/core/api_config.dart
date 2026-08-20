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

  static const String baseUrl = 'http://localhost:3000';
}
