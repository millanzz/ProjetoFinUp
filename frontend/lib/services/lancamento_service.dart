import '../models/lancamento_model.dart';
import 'api_client.dart';
import 'categoria_service.dart';

/// Serviço de lançamentos (receitas e despesas) integrado ao backend.
///
/// Os dados ficam em um cache local sincronizado com a API, então as
/// telas continuam lendo de forma síncrona (getReceitas, saldo, etc.)
/// e chamam [carregar] / [adicionar] / [remover] para sincronizar.
class LancamentoService {
  LancamentoService._();

  static List<LancamentoModel> _lancamentos = [];
  static bool _carregado = false;

  // ── Leitura (síncrona, a partir do cache) ─────────────────────

  static List<LancamentoModel> getAll() => List.unmodifiable(_lancamentos);

  static List<LancamentoModel> getReceitas() =>
      _lancamentos.where((l) => l.isReceita).toList();

  static List<LancamentoModel> getDespesas() =>
      _lancamentos.where((l) => !l.isReceita).toList();

  static double get totalReceitas =>
      getReceitas().fold(0, (sum, l) => sum + l.valor);

  static double get totalDespesas =>
      getDespesas().fold(0, (sum, l) => sum + l.valor);

  static double get saldo => totalReceitas - totalDespesas;

  // ── Sincronização com a API ───────────────────────────────────

  /// Busca receitas e despesas no backend e atualiza o cache.
  static Future<void> carregar({bool force = false}) async {
    if (_carregado && !force) return;

    final resultados = await Future.wait([
      ApiClient.get('/incomes'),
      ApiClient.get('/expenses'),
    ]);

    final receitas = (resultados[0] as List).map(
      (m) => LancamentoModel.fromApi(
        Map<String, dynamic>.from(m as Map),
        TipoLancamento.receita,
      ),
    );
    final despesas = (resultados[1] as List).map(
      (m) => LancamentoModel.fromApi(
        Map<String, dynamic>.from(m as Map),
        TipoLancamento.despesa,
      ),
    );

    _lancamentos = [...receitas, ...despesas]
      ..sort((a, b) => b.data.compareTo(a.data));

    _carregado = true;
  }

  /// Cria o lançamento no backend e insere no cache local.
  static Future<void> adicionar(LancamentoModel lancamento) async {
    int? categoryId;

    // resolve a categoria (a despesa exige categoria no backend)
    final nomeCategoria =
        lancamento.categoria ?? (lancamento.isReceita ? null : 'Outros');
    if (nomeCategoria != null) {
      categoryId = await CategoriaService.obterOuCriarId(
        nomeCategoria,
        lancamento.tipo,
      );
    }

    final rota = lancamento.isReceita ? '/incomes' : '/expenses';
    final dados = await ApiClient.post(
      rota,
      lancamento.toApiJson(categoryId: categoryId),
    );

    _lancamentos
      ..add(LancamentoModel(
        id: dados['id'].toString(),
        titulo: lancamento.titulo,
        valor: lancamento.valor,
        data: lancamento.data,
        tipo: lancamento.tipo,
        categoria: lancamento.categoria ?? nomeCategoria,
        parcelado: lancamento.parcelado,
      ))
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  /// Remove o lançamento no backend e no cache local.
  static Future<void> remover(LancamentoModel lancamento) async {
    final rota = lancamento.isReceita
        ? '/incomes/${lancamento.id}'
        : '/expenses/${lancamento.id}';

    await ApiClient.delete(rota);

    _lancamentos.removeWhere(
      (l) => l.id == lancamento.id && l.tipo == lancamento.tipo,
    );
  }

  static void limpar() {
    _lancamentos = [];
    _carregado = false;
  }
}
