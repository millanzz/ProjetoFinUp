import '../models/meta_model.dart';
import 'api_client.dart';

/// Serviço de metas financeiras integrado ao backend (/goals).
class MetaService {
  MetaService._();

  static List<MetaModel> _metas = [];

  static List<MetaModel> get metas => List.unmodifiable(_metas);

  static Future<List<MetaModel>> carregar() async {
    final dados = await ApiClient.get('/goals');
    _metas = (dados as List)
        .map((m) => MetaModel.fromApi(Map<String, dynamic>.from(m as Map)))
        .toList();
    return _metas;
  }

  static Future<void> criar({
    required String titulo,
    required double valorMeta,
    double valorInicial = 0,
    String icone = '🎯',
  }) async {
    await ApiClient.post('/goals', {
      'title': titulo,
      'target_amount': valorMeta,
      'current_amount': valorInicial,
      'icon': icone,
    });
    await carregar();
  }

  /// Soma um aporte ao progresso atual da meta.
  static Future<void> aportar(MetaModel meta, double valor) async {
    await ApiClient.patch('/goals/${meta.id}', {
      'current_amount': meta.valorAtual + valor,
    });
    await carregar();
  }

  static Future<void> remover(String id) async {
    await ApiClient.delete('/goals/$id');
    _metas.removeWhere((m) => m.id == id);
  }

  static void limpar() {
    _metas = [];
  }
}
