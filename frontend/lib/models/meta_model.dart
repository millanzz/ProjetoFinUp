class MetaModel {
  final String id;
  final String titulo;
  final double valorAtual;
  final double valorMeta;
  final String icone;

  MetaModel({
    String? id,
    required this.titulo,
    required this.valorAtual,
    required this.valorMeta,
    this.icone = '🎯',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Progresso de 0.0 a 1.0
  double get progresso => valorMeta <= 0 ? 0 : valorAtual / valorMeta;

  bool get concluida => valorAtual >= valorMeta;

  factory MetaModel.fromApi(Map<String, dynamic> map) {
    return MetaModel(
      id: map['id'].toString(),
      titulo: map['title'].toString(),
      valorAtual: ((map['current_amount'] ?? 0) as num).toDouble(),
      valorMeta: (map['target_amount'] as num).toDouble(),
      icone: (map['icon'] ?? '🎯').toString(),
    );
  }

  Map<String, dynamic> toApiJson() => {
        'title': titulo,
        'target_amount': valorMeta,
        'current_amount': valorAtual,
        'icon': icone,
      };
}
