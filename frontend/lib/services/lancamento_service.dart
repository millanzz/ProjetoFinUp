import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
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
  static DateTime? _carregadoEm;

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

  // Totais arredondados para centavos (sem resíduo de ponto flutuante, DEF-01/02).
  static double get totalReceitas =>
      Fmt.centavos(getReceitas().fold(0, (sum, l) => sum + l.valor));

  static double get totalDespesas =>
      Fmt.centavos(getDespesas().fold(0, (sum, l) => sum + l.valor));

  static double get saldo => Fmt.centavos(totalReceitas - totalDespesas);

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
    _carregadoEm = DateTime.now();
    _notificar();
  }

  /// Recarrega só se o cache tiver mais de [idadeMaxima]. Usado na troca de
  /// abas: antes, cada toque baixava e reprocessava TODOS os lançamentos (DEF-09).
  /// Puxar a lista para baixo continua forçando a recarga.
  static Future<void> carregarSeDesatualizado({
    Duration idadeMaxima = const Duration(minutes: 1),
  }) {
    final em = _carregadoEm;
    if (_carregado && em != null && DateTime.now().difference(em) < idadeMaxima) {
      return Future.value();
    }
    return carregar(force: true);
  }

  /// A categoria guardada no cache pode ter sido excluída em outro aparelho.
  /// Nesse caso a API responde 400 "Categoria não encontrada…": recarrega as
  /// categorias (o que recria a que falta) e tenta uma vez de novo (DEF-05).
  static Future<T> _comCategoriaAtualizada<T>(
    LancamentoModel lancamento,
    Future<T> Function(int? categoryId) enviar,
  ) async {
    try {
      return await enviar(await _resolverCategoria(lancamento));
    } on ApiException catch (e) {
      if (e.statusCode != 400 || !e.message.contains('Categoria não encontrada')) rethrow;
      await CategoriaService.carregar(force: true);
      return enviar(await _resolverCategoria(lancamento));
    }
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
  ///
  /// Com [parcelas] ≥ 2, o valor é o TOTAL e o backend cria uma parcela
  /// por mês. Nesse caso devolve a 1ª parcela (com o grupo preenchido,
  /// para o "Desfazer" poder remover todas).
  static Future<LancamentoModel> adicionar(
    LancamentoModel lancamento, {
    int? parcelas,
  }) async {
    final rota = lancamento.isReceita ? '/incomes' : '/expenses';
    final dados = await _comCategoriaAtualizada(
      lancamento,
      (categoryId) => ApiClient.post(
        rota,
        lancamento.toApiJson(categoryId: categoryId, parcelas: parcelas),
      ),
    );

    final categoria = lancamento.categoria ?? (lancamento.isReceita ? null : 'Outros');

    if (dados['parcelas'] is List) {
      final grupo = dados['parcela_grupo'].toString();
      final total = (dados['parcela_total'] as num).toInt();
      final criadas = [
        for (final p in dados['parcelas'] as List)
          LancamentoModel(
            id: p['id'].toString(),
            titulo: lancamento.titulo,
            valor: (p['amount'] as num).toDouble(),
            data: DateTime.parse(p['date'].toString()),
            tipo: lancamento.tipo,
            categoria: categoria,
            parcelado: true,
            parcelaGrupo: grupo,
            parcelaNumero: (p['parcela_numero'] as num).toInt(),
            parcelaTotal: total,
          ),
      ];
      _lancamentos
        ..addAll(criadas)
        ..sort((a, b) => b.data.compareTo(a.data));
      _notificar();
      return criadas.first;
    }

    final criado = LancamentoModel(
      id: dados['id'].toString(),
      titulo: lancamento.titulo,
      valor: lancamento.valor,
      data: lancamento.data,
      tipo: lancamento.tipo,
      categoria: categoria,
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

    final rota = lancamento.isReceita
        ? '/incomes/${lancamento.id}'
        : '/expenses/${lancamento.id}';

    await _comCategoriaAtualizada(
      lancamento,
      (categoryId) => ApiClient.put(rota, lancamento.toApiJson(categoryId: categoryId)),
    );

    final atualizado = LancamentoModel(
      id: lancamento.id,
      titulo: lancamento.titulo,
      valor: lancamento.valor,
      data: lancamento.data,
      tipo: lancamento.tipo,
      categoria: lancamento.categoria ?? (lancamento.isReceita ? null : 'Outros'),
      parcelado: lancamento.parcelado,
      parcelaGrupo: lancamento.parcelaGrupo,
      parcelaNumero: lancamento.parcelaNumero,
      parcelaTotal: lancamento.parcelaTotal,
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

  /// Remove todas as parcelas do mesmo parcelamento de [lancamento].
  static Future<int> removerParcelamento(LancamentoModel lancamento) async {
    final grupo = lancamento.parcelaGrupo;
    if (grupo == null) {
      await remover(lancamento);
      return 1;
    }

    final base = lancamento.isReceita ? '/incomes' : '/expenses';
    final dados = await ApiClient.delete('$base/grupo/${Uri.encodeComponent(grupo)}');

    _lancamentos.removeWhere(
      (l) => l.parcelaGrupo == grupo && l.tipo == lancamento.tipo,
    );
    _notificar();
    return (dados is Map && dados['removidas'] is num)
        ? (dados['removidas'] as num).toInt()
        : 0;
  }

  static void limpar() {
    _lancamentos = [];
    _carregado = false;
    _carregadoEm = null;
    _notificar();
  }
}
