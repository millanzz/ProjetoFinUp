import '../models/lancamento_model.dart';
import 'api_client.dart';

/// Serviço de categorias.
/// Mantém em cache o mapa nome -> id vindo do backend,
/// para que o resto do app trabalhe apenas com nomes.
class CategoriaService {
  CategoriaService._();

  static final Map<String, int> _receitas = {};
  static final Map<String, int> _despesas = {};
  static bool _carregado = false;

  static List<String> nomes(TipoLancamento tipo) =>
      (tipo == TipoLancamento.receita ? _receitas : _despesas).keys.toList();

  static Future<void> carregar({bool force = false}) async {
    if (_carregado && !force) return;

    final dados = await ApiClient.get('/categories');

    _receitas.clear();
    _despesas.clear();

    for (final c in (dados as List)) {
      final nome = c['name'].toString();
      final id = c['id'] as int;
      if (c['type'] == 'income') {
        _receitas[nome] = id;
      } else {
        _despesas[nome] = id;
      }
    }

    _carregado = true;
  }

  /// Retorna o id da categoria; se ainda não existir no backend, cria.
  static Future<int> obterOuCriarId(String nome, TipoLancamento tipo) async {
    await carregar();

    final cache = tipo == TipoLancamento.receita ? _receitas : _despesas;
    final existente = cache[nome];
    if (existente != null) return existente;

    try {
      final dados = await ApiClient.post('/categories', {
        'name': nome,
        'type': tipo == TipoLancamento.receita ? 'income' : 'expense',
      });
      final id = dados['id'] as int;
      cache[nome] = id;
      return id;
    } on ApiException catch (e) {
      // 409: a categoria já existe no servidor (criada em outro aparelho, por
      // exemplo). Recarrega a lista e usa a que já existe.
      if (e.statusCode != 409) rethrow;
      await carregar(force: true);
      final id = (tipo == TipoLancamento.receita ? _receitas : _despesas)[nome];
      if (id == null) rethrow;
      return id;
    }
  }

  static void limpar() {
    _receitas.clear();
    _despesas.clear();
    _carregado = false;
  }
}
