import 'api_client.dart';
import 'categoria_service.dart';
import 'lancamento_service.dart';
import 'meta_service.dart';

/// Serviço de autenticação integrado ao backend (JWT).
/// O token fica salvo no shared_preferences, então a sessão
/// sobrevive ao fechamento do app ([restaurarSessao]).
class AuthService {
  AuthService._();

  static bool _isLogged = false;
  static String _nome = '';
  static String _email = '';

  static bool isLogged() => _isLogged;

  static String get nome => _nome;
  static String get email => _email;

  /// Iniciais do nome para o avatar
  static String get iniciais {
    if (_nome.isEmpty) return '?';
    final partes = _nome.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    return partes.first[0].toUpperCase();
  }

  /// Tenta restaurar a sessão a partir do token salvo.
  /// Retorna true se o token ainda é válido.
  static Future<bool> restaurarSessao() async {
    await ApiClient.carregarToken();
    if (!ApiClient.temToken) return false;

    try {
      final dados = await ApiClient.get('/users/me');
      _nome = (dados['name'] ?? '').toString();
      _email = (dados['email'] ?? '').toString();
      _isLogged = true;
      return true;
    } on ApiException catch (e) {
      // token expirado/inválido -> limpa e volta pro login
      if (e.statusCode == 401) {
        await ApiClient.limparToken();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> login({
    required String email,
    required String senha,
  }) async {
    final dados = await ApiClient.post('/auth/login', {
      'email': email,
      'password': senha,
    });

    await ApiClient.salvarToken(dados['token'].toString());

    _nome = (dados['user']?['name'] ?? '').toString();
    _email = (dados['user']?['email'] ?? email).toString();
    _isLogged = true;
  }

  static Future<void> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    await ApiClient.post('/users', {
      'name': nome,
      'email': email,
      'password': senha,
    });

    // já entra direto após o cadastro
    await login(email: email, senha: senha);
  }

  /// Atualiza nome/email no backend.
  static Future<void> atualizarPerfil({String? nome, String? email}) async {
    await ApiClient.put('/users/me', {
      if (nome != null) 'name': nome,
      if (email != null) 'email': email,
    });
    if (nome != null) _nome = nome;
    if (email != null) _email = email;
  }

  /// Troca a senha (exige a senha atual).
  static Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    await ApiClient.put('/users/me/password', {
      'current_password': senhaAtual,
      'new_password': novaSenha,
    });
  }

  static void logout() {
    _isLogged = false;
    _nome = '';
    _email = '';
    ApiClient.limparToken();
    LancamentoService.limpar();
    CategoriaService.limpar();
    MetaService.limpar();
  }
}
