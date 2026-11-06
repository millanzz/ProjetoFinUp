import 'package:flutter/foundation.dart';

import '../models/lancamento_model.dart';
import 'api_client.dart';
import 'categoria_service.dart';

/// Serviço de lançamentos (receitas e despesas) integrado ao backend.
///
/// Os dados ficam em um cache local sincronizado com a API, então as
/// telas continuam lendo de forma síncrona (getReceitas, saldo, etc.)
/// e chamam [carregar] / [adicionar] / [editar] / [remover] para sincronizar.
class LancamentoService {
  LancamentoService._();

  static List<LancamentoModel> _lancamentos = [];
  static bool _carregado = false;

  /// Incrementado a cada mudança no cache. As abas (que ficam vivas num
  /// IndexedStack) escutam isto para se redesenhar.
  static final ValueNotifier<int> revisao = ValueNotifier<int>(0);
  static void _notificar() => revisao.value++;

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
    _notificar();
  }

  /// Resolve o id da categoria a partir do nome.
  /// A despesa exige categoria no backend, por isso o fallback "Outros".
  static Future<int?> _resolverCategoria(LancamentoModel lancamento) async {
    final nomeCategoria =
        lancamento.categoria ?? (lancamento.isReceita ? null : 'Outros');
    if (nomeCategoria == null) return null;

    return CategoriaService.obterOuCriarId(nomeCategoria, lancamento.tipo);
  }

  /// Cria o lançamento no backend e insere no cache local.
  static Future<LancamentoModel> adicionar(LancamentoModel lancamento) async {
    final categoryId = await _resolverCategoria(lancamento);

    final rota = lancamento.isReceita ? '/incomes' : '/expenses';
    final dados = await ApiClient.post(
      rota,
      lancamento.toApiJson(categoryId: categoryId),
    );

    final criado = LancamentoModel(
      id: dados['id'].toString(),
      titulo: lancamento.titulo,
      valor: lancamento.valor,
      data: lancamento.data,
      tipo: lancamento.tipo,
      categoria: lancamento.categoria ??
          (lancamento.isReceita ? null : 'Outros'),
      parcelado: lancamento.parcelado,
    );

    _lancamentos
      ..add(criado)
      ..sort((a, b) => b.data.compareTo(a.data));
    _notificar();
    return criado;
  }

  /// Atualiza o lançamento no backend (PUT /incomes/:id ou /expenses/:id)
  /// e substitui a versão antiga no cache local.
  ///
  /// O [lancamento] precisa manter o mesmo `id` e o mesmo `tipo` do
  /// registro original — só os demais campos são alterados.
  static Future<void> editar(LancamentoModel lancamento) async {
    if (lancamento.id.isEmpty) {
      throw ApiException('Lançamento sem id: não é possível editar.');
    }

    final categoryId = await _resolverCategoria(lancamento);

    final rota = lancamento.isReceita
        ? '/incomes/${lancamento.id}'
        : '/expenses/${lancamento.id}';

    await ApiClient.put(
      rota,
      lancamento.toApiJson(categoryId: categoryId),
    );

    final atualizado = LancamentoModel(
      id: lancamento.id,
      titulo: lancamento.titulo,
      valor: lancamento.valor,
      data: lancamento.data,
      tipo: lancamento.tipo,
      categoria: lancamento.categoria ?? (lancamento.isReceita ? null : 'Outros'),
      parcelado: lancamento.parcelado,
    );

    final indice = _lancamentos.indexWhere(
      (l) => l.id == lancamento.id && l.tipo == lancamento.tipo,
    );

    if (indice >= 0) {
      _lancamentos[indice] = atualizado;
    } else {
      _lancamentos.add(atualizado);
    }

    _lancamentos.sort((a, b) => b.data.compareTo(a.data));
    _notificar();
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
    _notificar();
  }

  static void limpar() {
    _lancamentos = [];
    _carregado = false;
    _notificar();
  }
}
