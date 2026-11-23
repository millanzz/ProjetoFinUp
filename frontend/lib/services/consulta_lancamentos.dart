import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import 'api_client.dart';
import 'lancamento_service.dart';

/// Consulta paginada de lançamentos de um período que NÃO está no cache local
/// (ver [LancamentoService]): Histórico "3 meses", "6 meses" e "Tudo", e meses
/// anteriores em Entradas/Despesas.
///
/// Baixa uma página por vez (GET /lancamentos). Os totais, a quantidade e a
/// soma por categoria são do período INTEIRO e vêm calculados pela API, então
/// o resumo aparece certo já com a primeira página. A tela chama
/// [carregarMais] quando o fim da lista aparece.
///
/// Quando um lançamento é incluído, editado ou excluído
/// ([LancamentoService.revisao] muda), recarrega a mesma quantidade de itens
/// que já estava na tela.
class ConsultaLancamentos extends ChangeNotifier {
  static const tamanhoPagina = 100;

  /// Só receitas, só despesas, ou `null` para as duas.
  final TipoLancamento? tipo;

  /// Primeiro dia do período (`null` = desde o início).
  final DateTime? de;

  /// Último dia do período, inclusive (`null` = sem limite).
  final DateTime? ate;

  ConsultaLancamentos({this.tipo, this.de, this.ate}) {
    LancamentoService.revisao.addListener(_recarregar);
    primeiraPagina = _buscar(0, tamanhoPagina);
  }

  /// Completa quando a primeira página (e os totais) chegam.
  late final Future<void> primeiraPagina;

  final List<LancamentoModel> _itens = [];
  int? _proximo;
  bool _carregando = false;
  bool _descartada = false;
  int _geracao = 0;

  /// Itens já baixados, do mais recente para o mais antigo.
  List<LancamentoModel> get itens => List.unmodifiable(_itens);

  /// Quantidade de lançamentos do período inteiro.
  int total = 0;
  double receitas = 0;
  double despesas = 0;

  /// Soma por categoria do período inteiro (receitas e despesas separadas).
  Map<String, double> categoriasReceita = const {};
  Map<String, double> categoriasDespesa = const {};

  /// A primeira resposta ainda não chegou.
  bool pronta = false;
  ApiException? erro;

  bool get temMais => _proximo != null;
  bool get carregando => _carregando;

  String _rota(int offset, int limit) {
    final q = <String>[
      'limit=$limit',
      'offset=$offset',
      if (tipo != null) 'tipo=${tipo == TipoLancamento.receita ? 'receita' : 'despesa'}',
      if (de != null) 'from=${LancamentoService.dia(de!)}',
      if (ate != null) 'to=${LancamentoService.dia(ate!)}',
    ];
    return '/lancamentos?${q.join('&')}';
  }

  Future<void> _buscar(int offset, int limit) async {
    final geracao = _geracao;
    _carregando = true;
    if (!_descartada) notifyListeners();
    try {
      final r = await ApiClient.get(_rota(offset, limit)) as Map;
      if (_descartada || geracao != _geracao) return;
      if (offset == 0) {
        _itens.clear();
        total = (r['total'] as num).toInt();
        receitas = Fmt.centavos((r['receitas'] as num).toDouble());
        despesas = Fmt.centavos((r['despesas'] as num).toDouble());
        final rec = <String, double>{}, des = <String, double>{};
        for (final c in (r['categorias'] as List? ?? const [])) {
          final nome = c['categoria'] == 'Sem categoria' ? 'Outros' : c['categoria'].toString();
          final alvo = c['tipo'] == 'receita' ? rec : des;
          alvo[nome] = (alvo[nome] ?? 0) + (c['total'] as num).toDouble();
        }
        categoriasReceita = rec;
        categoriasDespesa = des;
      }
      _itens.addAll((r['itens'] as List).map((m) => LancamentoService.doExtrato(m as Map)));
      _proximo = (r['proximo_offset'] as num?)?.toInt();
      erro = null;
      pronta = true;
    } on ApiException catch (e) {
      if (_descartada || geracao != _geracao) return;
      erro = e;
      pronta = true;
    } finally {
      if (geracao == _geracao) _carregando = false;
      if (!_descartada) notifyListeners();
    }
  }

  /// Busca a próxima página (não faz nada se já está buscando ou acabou).
  Future<void> carregarMais() async {
    if (_carregando || _proximo == null) return;
    await _buscar(_proximo!, tamanhoPagina);
  }

  /// Começa de novo mantendo quantos itens já estavam na tela.
  void _recarregar() {
    _geracao++;
    final n = _itens.length.clamp(tamanhoPagina, 1000);
    _buscar(0, n);
  }

  /// Puxar a lista para baixo.
  Future<void> recarregar() {
    _geracao++;
    return _buscar(0, _itens.length.clamp(tamanhoPagina, 1000));
  }

  @override
  void dispose() {
    _descartada = true;
    LancamentoService.revisao.removeListener(_recarregar);
    super.dispose();
  }
}
