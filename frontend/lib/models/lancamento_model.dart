enum TipoLancamento { receita, despesa }

class LancamentoModel {
  final String id;
  final String titulo;
  final double valor;
  final DateTime data;
  final TipoLancamento tipo;
  final String? categoria;
  final bool parcelado;

  LancamentoModel({
    String? id,
    required this.titulo,
    required this.valor,
    required this.data,
    required this.tipo,
    this.categoria,
    this.parcelado = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get isReceita => tipo == TipoLancamento.receita;

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
    );
  }

  /// Corpo enviado para a API na criação/edição
  Map<String, dynamic> toApiJson({int? categoryId}) => {
        'amount': valor,
        'description': titulo,
        'date': dataApi,
        if (categoryId != null) 'category_id': categoryId,
        'parcelado': parcelado,
      };
}
