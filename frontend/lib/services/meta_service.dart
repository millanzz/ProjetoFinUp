import 'package:flutter/foundation.dart';

import '../models/meta_model.dart';
import 'api_client.dart';

/// Serviço de metas financeiras integrado ao backend (/goals).
class MetaService {
  MetaService._();

  static List<MetaModel> _metas = [];

  /// Incrementado a cada mudança (a Início mostra a primeira meta).
  static final ValueNotifier<int> revisao = ValueNotifier<int>(0);

  static List<MetaModel> get metas => List.unmodifiable(_metas);

  static Future<List<MetaModel>> carregar() async {
    final dados = await ApiClient.get('/goals');
    _metas = (dados as List)
        .map((m) => MetaModel.fromApi(Map<String, dynamic>.from(m as Map)))
        .toList();
    revisao.value++;
    return _metas;
  }

  static Future<void> criar({
    required String titulo,
    required double valorMeta,
    double valorInicial = 0,
    String icone = 'flag',
  }) async {
    await ApiClient.post('/goals', {
      'title': titulo,
      'target_amount': valorMeta,
      'current_amount': valorInicial,
      'icon': icone,
    });
    await carregar();
  }

  /// Soma um aporte à meta. A soma é feita no servidor, então dois
  /// aportes ao mesmo tempo não se sobrescrevem.
  static Future<void> aportar(MetaModel meta, double valor) async {
    await ApiClient.post('/goals/${meta.id}/aportes', {'amount': valor});
    await carregar();
  }

  static Future<void> remover(String id) async {
    await ApiClient.delete('/goals/$id');
    _metas.removeWhere((m) => m.id == id);
    revisao.value++;
  }

  static void limpar() {
    _metas = [];
    revisao.value++;
  }
}
