import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import 'api_client.dart';
import 'categoria_service.dart';

/// Serviço de lançamentos (receitas e despesas) integrado ao backend.
///
/// **Janela recente.** O cache local guarda só os lançamentos do MÊS ATUAL em
/// diante (inclui as parcelas futuras). É o que a tela Início, o Histórico
/// "Este mês" e as listas do mês corrente leem de forma síncrona
/// ([getAll], [getReceitas], [getDespesas]).
///
/// Períodos mais antigos (Histórico "3 meses", "6 meses", "Tudo" e meses
/// anteriores em Entradas/Despesas) não ficam no aparelho: são buscados
/// página por página com `ConsultaLancamentos`, e os totais desses períodos
/// vêm calculados pela API. Antes, o app baixava TODOS os lançamentos a cada
/// recarga (12 MB para quem tem 50 mil), o que deixava a abertura e a troca
/// de abas lentas para usuários com muitos registros.
///
/// [totalReceitas], [totalDespesas] e [saldo] continuam sendo de TODOS os
/// lançamentos do usuário: vêm somados pela API (GET /lancamentos?limit=0).
class LancamentoService {
  LancamentoService._();

  /// Tamanho das páginas usadas para preencher a janela.
  static const tamanhoPaginaJanela = 1000;

  static List<LancamentoModel> _lancamentos = [];
  static bool _carregado = false;
  static DateTime? _carregadoEm;
  static DateTime _desde = _inicioDoMesAtual();
  static double _totalReceitas = 0;
  static double _totalDespesas = 0;
  static List<DateTime> _meses = [];

  static DateTime _inicioDoMesAtual() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month);
  }

  /// Incrementado a cada mudança no cache. As abas (que ficam vivas num
  /// IndexedStack) escutam isto para se redesenhar; as consultas paginadas
  /// também, para recarregar depois de uma inclusão, edição ou exclusão.
  static final ValueNotifier<int> revisao = ValueNotifier<int>(0);
  static void _notificar() => revisao.value++;

  // ── Leitura (síncrona, a partir do cache) ─────────────────────

  /// Primeiro dia coberto pelo cache local (início do mês atual).
  static DateTime get janelaDesde => _desde;

  /// Se o período que começa em [inicio] está inteiro no cache local.
  static bool cobre(DateTime inicio) => !inicio.isBefore(_desde);

  static bool _naJanela(LancamentoModel l) => !l.data.isBefore(_desde);

  /// Lançamentos da janela recente (mês atual em diante).
  static List<LancamentoModel> getAll() => List.unmodifiable(_lancamentos);

  static List<LancamentoModel> getReceitas() =>
      _lancamentos.where((l) => l.isReceita).toList();

  static List<LancamentoModel> getDespesas() =>
      _lancamentos.where((l) => !l.isReceita).toList();

  /// Meses (dia 1) que têm algum lançamento, do mais recente ao mais antigo.
  static List<DateTime> get meses => List.unmodifiable(_meses);

  // Totais de TODOS os lançamentos, somados pela API e arredondados (DEF-01/02).
  static double get totalReceitas => _totalReceitas;

  static double get totalDespesas => _totalDespesas;

  static double get saldo => Fmt.centavos(_totalReceitas - _totalDespesas);

  // ── Sincronização com a API ───────────────────────────────────

  /// Data no formato da API (AAAA-MM-DD).
  static String dia(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Converte um item de GET /lancamentos (que traz o campo `tipo`).
  static LancamentoModel doExtrato(Map m) => LancamentoModel.fromApi(
        Map<String, dynamic>.from(m),
        m['tipo'] == 'receita' ? TipoLancamento.receita : TipoLancamento.despesa,
      );

  /// Busca no backend a janela recente (página por página), os totais gerais
  /// e a lista de meses, e atualiza o cache.
  static Future<void> carregar({bool force = false}) async {
    if (_carregado && !force) return;

    final desde = _inicioDoMesAtual();
    final rota = '/lancamentos?from=${dia(desde)}&limit=$tamanhoPaginaJanela';
    final resultados = await Future.wait([
      ApiClient.get('$rota&offset=0'),
      ApiClient.get('/lancamentos?limit=0'),
      ApiClient.get('/lancamentos/meses'),
    ]);

    final itens = <LancamentoModel>[];
    var pagina = resultados[0] as Map;
    while (true) {
      itens.addAll((pagina['itens'] as List).map((m) => doExtrato(m as Map)));
      final proximo = pagina['proximo_offset'];
      if (proximo == null) break;
      pagina = await ApiClient.get('$rota&offset=$proximo') as Map;
    }

    _desde = desde;
    _lancamentos = itens..sort((a, b) => b.data.compareTo(a.data));
    _aplicarResumo(resultados[1] as Map);
    _meses = [
      for (final m in resultados[2] as List) DateTime.parse('$m-01'),
    ];

    _carregado = true;
    _carregadoEm = DateTime.now();
    _notificar();
  }

  static void _aplicarResumo(Map r) {
    _totalReceitas = Fmt.centavos((r['receitas'] as num).toDouble());
    _totalDespesas = Fmt.centavos((r['despesas'] as num).toDouble());
  }

  /// Depois de uma inclusão, edição ou exclusão: atualiza os totais gerais
  /// (somados pela API) e a lista de meses. Uma falha aqui não desfaz a
  /// operação, que já foi gravada; os totais se acertam na próxima recarga.
  static Future<void> _atualizarResumo(Iterable<DateTime> datas) async {
    for (final d in datas) {
      final mes = DateTime(d.year, d.month);
      if (!_meses.contains(mes)) {
        _meses = [..._meses, mes]..sort((a, b) => b.compareTo(a));
      }
    }
    try {
      _aplicarResumo(await ApiClient.get('/lancamentos?limit=0') as Map);
    } catch (_) {}
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
        ..addAll(criadas.where(_naJanela))
        ..sort((a, b) => b.data.compareTo(a.data));
      await _atualizarResumo(criadas.map((l) => l.data));
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

    if (_naJanela(criado)) {
      _lancamentos
        ..add(criado)
        ..sort((a, b) => b.data.compareTo(a.data));
    }
    await _atualizarResumo([criado.data]);
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

    // A data pode ter mudado: o lançamento entra, continua ou sai da janela.
    if (indice >= 0) _lancamentos.removeAt(indice);
    if (_naJanela(atualizado)) _lancamentos.add(atualizado);

    _lancamentos.sort((a, b) => b.data.compareTo(a.data));
    await _atualizarResumo([atualizado.data]);
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
    await _atualizarResumo(const []);
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
    await _atualizarResumo(const []);
    _notificar();
    return (dados is Map && dados['removidas'] is num)
        ? (dados['removidas'] as num).toInt()
        : 0;
  }

  static void limpar() {
    _lancamentos = [];
    _carregado = false;
    _carregadoEm = null;
    _totalReceitas = 0;
    _totalDespesas = 0;
    _meses = [];
    _notificar();
  }
}
