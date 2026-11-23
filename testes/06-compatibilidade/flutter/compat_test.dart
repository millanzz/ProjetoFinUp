// Teste de COMPATIBILIDADE: as telas reais do app em diferentes tamanhos de
// tela, aparelhos (Android/iOS/tablet/desktop), orientação, tamanho de fonte,
// tema e com o teclado aberto. O app conversa com a API real (dados reais).
//
// Para cada perfil × tela o teste:
//   1. desenha a tela e guarda uma captura (evidencias/telas/<perfil>/<tela>.png);
//   2. registra qualquer erro de layout do Flutter (ex.: "RenderFlex overflowed");
//   3. confere se a ação principal da tela pode ser tocada (dá para rolar até ela
//      e ela não está coberta).
//
// Rodar (na pasta frontend, com a API de teste na 3999):
//   flutter test ../testes/06-compatibilidade/flutter/compat_test.dart --dart-define=API_URL=http://127.0.0.1:3999
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/core/theme_controller.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/models/lancamento_model.dart';
import 'package:FinUp/services/auth_service.dart';
import 'package:FinUp/services/categoria_service.dart';
import 'package:FinUp/services/lancamento_service.dart';
import 'package:FinUp/services/meta_service.dart';
import '../../02-funcionais/app/suporte.dart' show prepararAmbiente, esperar, assentar;

final ev = Directory('../testes/06-compatibilidade/evidencias').absolute.path;

class Perfil {
  final String id, nome;
  final double w, h;
  final double dpr;
  final TargetPlatform plataforma;
  final EdgeInsets seguro; // área segura (notch, barra de gestos)
  final double fonte;
  final bool escuro;
  final double teclado; // altura do teclado aberto (0 = fechado)
  const Perfil(this.id, this.nome, this.w, this.h, this.dpr, this.plataforma,
      {this.seguro = EdgeInsets.zero, this.fonte = 1, this.escuro = false, this.teclado = 0});
}

const _and = TargetPlatform.android, _ios = TargetPlatform.iOS, _win = TargetPlatform.windows;

/// Matriz A — aparelhos (fonte 100%, tema claro)
const aparelhos = [
  Perfil('A01', 'Galaxy Z Fold (tela externa)', 280, 653, 3, _and, seguro: EdgeInsets.only(top: 24, bottom: 16)),
  Perfil('A02', 'iPhone SE 1ª geração', 320, 568, 2, _ios, seguro: EdgeInsets.only(top: 20)),
  Perfil('A03', 'Android pequeno (Galaxy J/A básico)', 360, 640, 2, _and, seguro: EdgeInsets.only(top: 24)),
  Perfil('A04', 'iPhone SE 2ª/3ª geração', 375, 667, 2, _ios, seguro: EdgeInsets.only(top: 20)),
  Perfil('A05', 'iPhone 14 / 15', 390, 844, 3, _ios, seguro: EdgeInsets.only(top: 47, bottom: 34)),
  Perfil('A06', 'Pixel 7 / Galaxy S23', 412, 915, 2.625, _and, seguro: EdgeInsets.only(top: 32, bottom: 24)),
  Perfil('A07', 'iPhone 14/15 Pro Max', 430, 932, 3, _ios, seguro: EdgeInsets.only(top: 59, bottom: 34)),
  Perfil('A08', 'iPhone 14 em paisagem', 844, 390, 3, _ios, seguro: EdgeInsets.only(left: 47, right: 47, bottom: 21)),
  Perfil('A09', 'Android em paisagem', 915, 412, 2.625, _and, seguro: EdgeInsets.only(top: 24)),
  Perfil('A10', 'iPad 9ª geração', 810, 1080, 2, _ios, seguro: EdgeInsets.only(top: 24, bottom: 20)),
  Perfil('A11', 'Tablet Android 10"', 800, 1280, 2, _and, seguro: EdgeInsets.only(top: 24, bottom: 48)),
  Perfil('A12', 'Notebook / Web 1280×800', 1280, 800, 1, _win),
  Perfil('A13', 'Monitor Full HD 1920×1080', 1920, 1080, 1, _win),
];

/// Matriz B — fonte ampliada (acessibilidade do sistema)
const fontes = [
  Perfil('B01', 'Android pequeno · fonte 130%', 360, 640, 2, _and, seguro: EdgeInsets.only(top: 24), fonte: 1.3),
  Perfil('B02', 'Android pequeno · fonte 200%', 360, 640, 2, _and, seguro: EdgeInsets.only(top: 24), fonte: 2.0),
  Perfil('B03', 'iPhone 14 · fonte 130%', 390, 844, 3, _ios, seguro: EdgeInsets.only(top: 47, bottom: 34), fonte: 1.3),
  Perfil('B04', 'iPhone 14 · fonte 200%', 390, 844, 3, _ios, seguro: EdgeInsets.only(top: 47, bottom: 34), fonte: 2.0),
  Perfil('B05', 'Pixel 7 · fonte 130%', 412, 915, 2.625, _and, seguro: EdgeInsets.only(top: 32, bottom: 24), fonte: 1.3),
  Perfil('B06', 'Pixel 7 · fonte 200%', 412, 915, 2.625, _and, seguro: EdgeInsets.only(top: 32, bottom: 24), fonte: 2.0),
];

/// Matriz C — tema escuro
const escuros = [
  Perfil('C01', 'iPhone 14 · tema escuro', 390, 844, 3, _ios, seguro: EdgeInsets.only(top: 47, bottom: 34), escuro: true),
  Perfil('C02', 'iPad · tema escuro', 810, 1080, 2, _ios, seguro: EdgeInsets.only(top: 24, bottom: 20), escuro: true),
];

/// Matriz D — teclado aberto nas telas de formulário
const teclados = [
  Perfil('D01', 'iPhone SE 1ª · teclado aberto', 320, 568, 2, _ios, seguro: EdgeInsets.only(top: 20), teclado: 216),
  Perfil('D02', 'Android pequeno · teclado aberto', 360, 640, 2, _and, seguro: EdgeInsets.only(top: 24), teclado: 280),
  Perfil('D03', 'Pixel 7 · teclado aberto', 412, 915, 2.625, _and, seguro: EdgeInsets.only(top: 32, bottom: 24), teclado: 300),
];

/// Telas visitadas. `acao` = elemento principal que precisa poder ser tocado.
class Tela {
  final String id, nome;
  final bool logado;
  final Future<void> Function(WidgetTester) abrir;
  final Finder Function() acao;
  final bool formulario;
  Tela(this.id, this.nome, this.logado, this.abrir, this.acao, {this.formulario = false});
}

Finder _texto(String s) => find.text(s);
Finder _tipo(String nome) => find.byWidgetPredicate((w) => w.runtimeType.toString() == nome);

Future<void> _tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await assentar(t, 200);
  await t.tap(f.first, warnIfMissed: false);
  await assentar(t, 500);
}

Future<void> _aba(WidgetTester t, String nome) async {
  final rev = LancamentoService.revisao.value;
  await t.tap(find.text(nome).last, warnIfMissed: false);
  final fim = DateTime.now().add(const Duration(seconds: 1)); // a troca de aba só recarrega com cache velho (DEF-09)
  while (LancamentoService.revisao.value == rev && DateTime.now().isBefore(fim)) {
    await t.pump(const Duration(milliseconds: 20));
  }
  await assentar(t, 600);
}

final telas = [
  Tela('01-login', 'Login', false, (t) async {}, () => _texto('Entrar').last, formulario: true),
  Tela('02-cadastro', 'Criar conta', false, (t) async {
    await _tocar(t, find.text('Criar conta'));
    await esperar(t, find.text('Nome completo'));
  }, () => _texto('Criar conta').last, formulario: true),
  Tela('03-esqueci-senha', 'Esqueci minha senha', false, (t) async {
    await _tocar(t, find.text('Esqueci minha senha'));
    await esperar(t, find.text('Enviar código'));
  }, () => _texto('Enviar código'), formulario: true),
  Tela('04-inicio', 'Início', true, (t) async {}, () => _texto('Despesa')),
  Tela('05-entradas', 'Entradas', true, (t) => _aba(t, 'Entradas'), () => _texto('Nova receita')),
  Tela('06-despesas', 'Despesas', true, (t) => _aba(t, 'Despesas'), () => _texto('Nova despesa')),
  Tela('07-metas', 'Metas', true, (t) => _aba(t, 'Metas'), () => _texto('Nova meta').last),
  Tela('08-historico', 'Histórico', true, (t) => _aba(t, 'Histórico'), () => _texto('Tudo')),
  Tela('09-perfil', 'Perfil', true, (t) async {
    await _tocar(t, _tipo('FinAvatar'));
    await esperar(t, find.text('Sair da conta'));
  }, () => _texto('Sair da conta').last),
  Tela('10-nova-despesa', 'Formulário de despesa', true, (t) async {
    await _tocar(t, find.text('Despesa'));
    await esperar(t, find.text('Salvar despesa'));
  }, () => _texto('Salvar despesa'), formulario: true),
];

final _key = GlobalKey();

Future<void> _salvarPng(String caminho) async {
  final b = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final img = await b.toImage(pixelRatio: 1);
  final png = await img.toByteData(format: ImageByteFormat.png);
  File(caminho)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

Widget _app(Perfil p, bool logado) => RepaintBoundary(
      key: _key,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(p.w, p.h),
          devicePixelRatio: p.dpr,
          padding: p.seguro,
          viewPadding: p.seguro,
          viewInsets: EdgeInsets.only(bottom: p.teclado),
          textScaler: TextScaler.linear(p.fonte),
          platformBrightness: p.escuro ? Brightness.dark : Brightness.light,
        ),
        child: FinanceiroApp(logado: logado),
      ),
    );

/// Resultado de todas as telas de todos os perfis (vira evidencias/resultados.json).
final resultados = <Map<String, Object?>>[];

Future<void> visitarPerfil(WidgetTester t, Perfil p, {bool soFormularios = false}) async {
  await t.binding.setSurfaceSize(Size(p.w, p.h));
  debugDefaultTargetPlatformOverride = p.plataforma;
  await ThemeController.definir(p.escuro ? ThemeMode.dark : ThemeMode.light);
  final erroOriginal = FlutterError.onError;
  final falhas = <String>[];
  try {
    for (final tela in telas.where((x) => !soFormularios || x.formulario)) {
      final erros = <String>[];
      FlutterError.onError = (d) {
        final txt = d.exceptionAsString().split('\n').first;
        final onde = d.informationCollector?.call().map((e) => e.toString()).firstWhere(
              (s) => s.contains('lib/'), orElse: () => '') ?? '';
        final m = RegExp(r'(lib/[\w/]+\.dart:\d+)').firstMatch(onde);
        erros.add(m == null ? txt : '$txt (${m.group(1)})');
      };
      String acao = 'não verificada';
      try {
        await t.pumpWidget(const SizedBox());
        await t.pumpWidget(_app(p, tela.logado));
        await esperar(t, tela.logado ? find.text('Início') : find.text('Entrar na sua conta'));
        await assentar(t, 700);
        await tela.abrir(t);
        await assentar(t, 500);
        final f = tela.acao();
        if (f.evaluate().isEmpty) {
          acao = 'não encontrada';
        } else {
          await t.ensureVisible(f.first);
          await assentar(t, 300);
          acao = f.first.hitTestable().evaluate().isNotEmpty ? 'tocável' : 'coberta/fora da tela';
        }
        await t.binding.setSurfaceSize(Size(p.w, p.h));
        await t.pump();
        // Rola de volta ao topo para a captura mostrar o começo da tela
        for (final s in find.byType(Scrollable).evaluate()) {
          final st = (s as StatefulElement).state as ScrollableState;
          if (st.position.pixels != 0) st.position.jumpTo(0);
        }
        await assentar(t, 300);
        await _salvarPng('$ev/telas/${p.id}/${tela.id}.png');
      } catch (e) {
        erros.add('falha ao abrir a tela: ${e.toString().split('\n').first}');
      } finally {
        FlutterError.onError = erroOriginal;
      }
      final unicos = erros.toSet().toList();
      final ok = unicos.isEmpty && acao == 'tocável';
      if (!ok) falhas.add('${tela.nome}: ${[...unicos, if (acao != 'tocável') 'ação principal $acao'].join('; ')}');
      resultados.add({
        'perfil': p.id, 'aparelho': p.nome, 'largura': p.w, 'altura': p.h,
        'plataforma': p.plataforma.name, 'fonte': p.fonte, 'escuro': p.escuro, 'teclado': p.teclado,
        'tela': tela.id, 'nome_tela': tela.nome, 'erros': unicos, 'acao_principal': acao, 'ok': ok,
        'captura': 'telas/${p.id}/${tela.id}.png',
      });
      File('$ev/resultados.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(resultados));
    }
  } finally {
    await t.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    await t.binding.setSurfaceSize(null);
  }
  expect(falhas, isEmpty, reason: '${p.id} ${p.nome}');
}

LancamentoModel _l(String t, double v, int dia, TipoLancamento tipo, String cat) {
  final h = DateTime.now();
  return LancamentoModel(titulo: t, valor: v, data: DateTime(h.year, h.month, dia), tipo: tipo, categoria: cat);
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await prepararAmbiente();
    // Dados "difíceis" para o layout: nome longo, descrições longas, valores altos
    await AuthService.register(
        nome: 'Maria Aparecida dos Santos Albuquerque', email: 'compat@teste.local', senha: 'senha123');
    await CategoriaService.carregar(force: true);
    await LancamentoService.carregar(force: true);
    const r = TipoLancamento.receita, d = TipoLancamento.despesa;
    for (final l in [
      _l('Salário', 12850.75, 5, r, 'Salário'),
      _l('Projeto de consultoria para a Associação Comercial de São José dos Campos', 999999.99, 3, r, 'Freelance'),
      _l('Aluguel do apartamento', 3200, 2, d, 'Moradia'),
      _l('Supermercado Pão de Açúcar — compra do mês com produtos de limpeza', 1543.27, 4, d, 'Alimentação'),
      _l('Uber', 32.5, 6, d, 'Transporte'),
      _l('Farmácia', 187.9, 6, d, 'Saúde'),
      _l('Streaming', 55.9, 1, d, 'Assinaturas'),
      _l('IPVA', 2875.4, 7, d, 'Impostos'),
    ]) {
      await LancamentoService.adicionar(l);
    }
    await LancamentoService.adicionar(_l('Notebook para estudos', 7999.99, 1, d, 'Compras'), parcelas: 10);
    await MetaService.criar(titulo: 'Reserva de emergência para seis meses de despesas', valorMeta: 120000, valorInicial: 45800.5, icone: 'wallet');
    await MetaService.criar(titulo: 'Viagem', valorMeta: 8000, valorInicial: 8000, icone: 'flight');
    await LancamentoService.carregar(force: true);
  });

  for (final grupo in [
    ('A — aparelhos', aparelhos, false),
    ('B — fonte ampliada', fontes, false),
    ('C — tema escuro', escuros, false),
    ('D — teclado aberto', teclados, true),
  ]) {
    group(grupo.$1, () {
      for (final p in grupo.$2) {
        testWidgets('${p.id} ${p.nome} (${p.w.toInt()}×${p.h.toInt()})',
            (t) => visitarPerfil(t, p, soFormularios: grupo.$3),
            timeout: const Timeout(Duration(minutes: 10)));
      }
    });
  }
}
