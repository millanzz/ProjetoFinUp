import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/api_client.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';

/// Política de Privacidade. O texto vem da API (GET /privacidade.json), a
/// mesma fonte da página pública /privacidade, então app e site nunca divergem.
class PoliticaPrivacidadeScreen extends StatefulWidget {
  const PoliticaPrivacidadeScreen({super.key});

  @override
  State<PoliticaPrivacidadeScreen> createState() => _PoliticaPrivacidadeScreenState();
}

class _PoliticaPrivacidadeScreenState extends State<PoliticaPrivacidadeScreen> {
  late Future<Map<String, dynamic>> _politica = _carregar();

  Future<Map<String, dynamic>> _carregar() async =>
      Map<String, dynamic>.from(await ApiClient.get('/privacidade.json') as Map);

  @override
  Widget build(BuildContext context) {
    final c = context.fin;
    return FinScaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _politica,
        builder: (context, snap) {
          const topo = FinTopBar(title: 'Política de privacidade', lead: Icons.arrow_back);
          if (snap.connectionState != ConnectionState.done) {
            return const Column(children: [topo, Expanded(child: Center(child: CircularProgressIndicator()))]);
          }
          if (snap.hasError) {
            return Column(
              children: [
                topo,
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Não foi possível carregar a política agora. Verifique a conexão e tente de novo.',
                        textAlign: TextAlign.center,
                        style: FinType.bodyL.copyWith(color: c.textVar),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _politica = _carregar()),
                        child: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          final dados = snap.data!;
          final secoes = (dados['secoes'] as List).cast<Map<dynamic, dynamic>>();
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              topo,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: FinSurface.convex(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Versão ${dados['versao']} · atualizada em ${dados['atualizada_em']}',
                        style: FinType.bodyS.copyWith(color: c.textVar),
                      ),
                      for (final s in secoes) ...[
                        const SizedBox(height: 18),
                        Text(s['titulo'].toString(), style: FinType.titleM.copyWith(color: c.text)),
                        for (final p in (s['paragrafos'] as List)) ...[
                          const SizedBox(height: 8),
                          Text(p.toString(), style: FinType.bodyM.copyWith(color: c.text, height: 1.5)),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
