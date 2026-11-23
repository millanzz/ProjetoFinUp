enum TipoLancamento { receita, despesa }

class LancamentoModel {
  final String id;
  final String titulo;
  final double valor;
  final DateTime data;
  final TipoLancamento tipo;
  final String? categoria;
  final bool parcelado;

  /// Parcelamento: todas as parcelas de uma compra têm o mesmo grupo.
  final String? parcelaGrupo;
  final int? parcelaNumero;
  final int? parcelaTotal;

  LancamentoModel({
    String? id,
    required this.titulo,
    required this.valor,
    required this.data,
    required this.tipo,
    this.categoria,
    this.parcelado = false,
    this.parcelaGrupo,
    this.parcelaNumero,
    this.parcelaTotal,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get isReceita => tipo == TipoLancamento.receita;

  /// Faz parte de um parcelamento com 2 ou mais parcelas.
  bool get isParcela => parcelaGrupo != null && (parcelaTotal ?? 0) > 1;

  /// "Parcela 3/12" (ou null quando não é parcela).
  String? get rotuloParcela =>
      isParcela ? 'Parcela $parcelaNumero/$parcelaTotal' : null;

  /// Data no formato exibido no app (DD/MM/AAAA)
  String get dataFormatada =>
      "${data.day.toString().padLeft(2, '0')}/"
      "${data.month.toString().padLeft(2, '0')}/"
      "${data.year}";

  /// Data no formato aceito pelo backend (YYYY-MM-DD)
  String get dataApi =>
      "${data.year.toString().padLeft(4, '0')}-"
      "${data.month.toString().padLeft(2, '0')}-"
      "${data.day.toString().padLeft(2, '0')}";

  /// Cria a partir do JSON retornado pela API (/incomes e /expenses)
  factory LancamentoModel.fromApi(
    Map<String, dynamic> map,
    TipoLancamento tipo,
  ) {
    final descricao = map['description'];
    final categoria = map['category_name'];

    return LancamentoModel(
      id: map['id'].toString(),
      titulo: (descricao != null && descricao.toString().isNotEmpty)
          ? descricao.toString()
          : (categoria?.toString() ?? 'Sem descrição'),
      valor: (map['amount'] as num).toDouble(),
      data: DateTime.tryParse(map['date'].toString()) ?? DateTime.now(),
      tipo: tipo,
      categoria: categoria?.toString(),
      parcelado: map['parcelado'] == 1 || map['parcelado'] == true,
      parcelaGrupo: map['parcela_grupo']?.toString(),
      parcelaNumero: (map['parcela_numero'] as num?)?.toInt(),
      parcelaTotal: (map['parcela_total'] as num?)?.toInt(),
    );
  }

  /// Corpo enviado para a API na criação/edição.
  /// Com [parcelas] ≥ 2, o backend divide [valor] (total) em parcelas mensais.
  Map<String, dynamic> toApiJson({int? categoryId, int? parcelas}) => {
        'amount': valor,
        'description': titulo,
        'date': dataApi,
        if (categoryId != null) 'category_id': categoryId,
        'parcelado': parcelado,
        if (parcelas != null && parcelas >= 2) 'parcelas': parcelas,
      };

  /// Cópia com outros campos de parcela (usada ao editar uma parcela).
  LancamentoModel comParcela(LancamentoModel origem) => LancamentoModel(
        id: id,
        titulo: titulo,
        valor: valor,
        data: data,
        tipo: tipo,
        categoria: categoria,
        parcelado: parcelado,
        parcelaGrupo: origem.parcelaGrupo,
        parcelaNumero: origem.parcelaNumero,
        parcelaTotal: origem.parcelaTotal,
      );
}
