import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/lancamento_model.dart';
import '../models/meta_model.dart';
import '../services/auth_service.dart';
import '../services/lancamento_service.dart';
import '../services/meta_service.dart';
import '../widgets/fin_controls.dart';
import '../widgets/fin_layout.dart';
import '../widgets/fin_surface.dart';
import '../widgets/lancamento_acoes.dart';
import '../widgets/meta_card.dart';
import '../widgets/saldo_card.dart';
import 'main_navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _timerSaudacao;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agendarViradaDaSaudacao();
    MetaService.carregar().catchError((_) => <MetaModel>[]);
  }

  @override
  void dispose() {
    _timerSaudacao?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
      _agendarViradaDaSaudacao();
      AuthService.recarregarPerfil();
    }
  }

  // ── Saudação ─────────────────────────────────────────────────

  /// 5h–11h59 bom dia, 12h–17h59 boa tarde, 18h–4h59 boa noite.
  String get _saudacao {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  DateTime _proximaVirada() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    for (final hora in [5, 12, 18]) {
      final marco = hoje.add(Duration(hours: hora));
      if (marco.isAfter(agora)) return marco;
    }
    return hoje.add(const Duration(days: 1, hours: 5));
  }

  void _agendarViradaDaSaudacao() {
    _timerSaudacao?.cancel();
    final espera = _proximaVirada().difference(DateTime.now());
    _timerSaudacao = Timer(espera + const Duration(seconds: 1), () {
      if (mounted) setState(() {});
      _agendarViradaDaSaudacao();
    });
  }

  // ── Navegação ────────────────────────────────────────────────

  Future<void> _recarregar() async {
    await Future.wait([
      LancamentoService.carregar(force: true).catchError((_) {}),
      MetaService.carregar().catchError((_) => <MetaModel>[]),
    ]);
  }

  void _irParaAba(int aba) => NavegacaoPrincipal.of(context)?.irParaAba(aba);

  List<MapEntry<String, double>> _porCategoria(List<LancamentoModel> l) {
    final m = <String, double>{};
    for (final x in l) {
      final k = x.categoria ?? 'Outros';
      m[k] = (m[k] ?? 0) + x.valor;
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LancamentoService.revisao,
        MetaService.revisao,
        AuthService.usuarioRevisao,
      ]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = context.fin;
    final agora = DateTime.now();
    final mes = DateTime(agora.year, agora.month);
    final doMes = LancamentoService.getAll()
        .where((l) => Fmt.mesmoMes(l.data, mes))
        .toList();
    final despesas = doMes.where((l) => !l.isReceita).toList();
    final receitas = doMes.where((l) => l.isReceita).toList();
    final totalD = despesas.fold<double>(0, (s, l) => s + l.valor);
    final totalR = receitas.fold<double>(0, (s, l) => s + l.valor);

    final metas = MetaService.metas;
    final metaDestaque = metas.isEmpty
        ? null
        : metas.firstWhere((m) => !m.concluida, orElse: () => metas.first);

    final primeiroNome = AuthService.primeiroNome;

    return FinScaffold(
      safeBottom: false,
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface,
        onRefresh: _recarregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            // Barra superior: koi + FinUp + avatar (abre o Perfil)
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.only(left: 18, right: 16),
                child: Row(
                  children: [
                    Image.asset(
                      c.isDark ? 'assets/images/koi_dark.png' : 'assets/images/koi_light.png',
                      width: 54,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'FinUp',
                        style: FinType.titleL.copyWith(
                          color: c.text,
                          fontWeight: FontWeight.w700,
                          shadows: FinFx.emboss(c),
                        ),
                      ),
                    ),
                    FinAvatar(
                      iniciais: AuthService.iniciais,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.perfil),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    primeiroNome.isEmpty ? _saudacao : '$_saudacao, $primeiroNome',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FinType.headlineS.copyWith(color: c.text, shadows: FinFx.emboss(c)),
                  ),
                  const SizedBox(height: 18),
                  SaldoCard(mes: mes, lancamentosDoMes: doMes),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FinButton(
                          label: 'Receita',
                          icon: Icons.add,
                          expand: true,
                          onPressed: () => LancamentoAcoes.novo(context, TipoLancamento.receita),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FinButton(
                          label: 'Despesa',
                          icon: Icons.remove,
                          kind: FinButtonKind.coral,
                          expand: true,
                          onPressed: () => LancamentoAcoes.novo(context, TipoLancamento.despesa),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SectionHead(
                    title: 'Para onde foi o dinheiro',
                    action: 'Ver despesas',
                    onAction: () => _irParaAba(Abas.despesas),
                  ),
                  const SizedBox(height: 10),
                  if (despesas.isEmpty)
                    const EmptyCard(
                      icon: Icons.receipt_long,
                      texto: 'Nenhuma despesa neste mês.',
                    )
                  else
                    ListCard(
                      inset: 66,
                      rows: [
                        for (final e in _porCategoria(despesas))
                          CatRow(
                            categoria: e.key,
                            valor: e.value,
                            total: totalD,
                            tone: FinTone.coral,
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  SectionHead(
                    title: 'De onde veio',
                    action: 'Ver entradas',
                    onAction: () => _irParaAba(Abas.entradas),
                  ),
                  const SizedBox(height: 10),
                  if (receitas.isEmpty)
                    const EmptyCard(
                      icon: Icons.savings,
                      texto: 'Nenhuma entrada neste mês.',
                    )
                  else
                    ListCard(
                      inset: 66,
                      rows: [
                        for (final e in _porCategoria(receitas))
                          CatRow(
                            categoria: e.key,
                            valor: e.value,
                            total: totalR,
                            tone: FinTone.primary,
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  SectionHead(
                    title: 'Metas',
                    action: 'Ver todas',
                    onAction: () => _irParaAba(Abas.metas),
                  ),
                  const SizedBox(height: 10),
                  if (metaDestaque == null)
                    EmptyCard(
                      icon: Icons.flag,
                      texto: 'Você ainda não tem metas.',
                      acao: FinButton.text(
                        label: 'Criar meta',
                        icon: Icons.add,
                        onPressed: () => _irParaAba(Abas.metas),
                      ),
                    )
                  else
                    MetaCard(
                      meta: metaDestaque,
                      compact: true,
                      onTap: () => _irParaAba(Abas.metas),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
