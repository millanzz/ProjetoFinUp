// FASE 1 — uso normal do app, antes de qualquer reinício.
// Cria, edita e exclui dados pelos serviços do app, escolhe o tema escuro,
// fotografa a tela inicial e guarda o "estado esperado" para as próximas fases.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FinUp/core/theme_controller.dart';
import 'package:FinUp/main.dart';
import 'package:FinUp/models/lancamento_model.dart';
import 'package:FinUp/services/api_client.dart';
import 'package:FinUp/services/auth_service.dart';
import 'package:FinUp/services/categoria_service.dart';
import 'package:FinUp/services/lancamento_service.dart';
import 'package:FinUp/services/meta_service.dart';
import 'suporte.dart';

final _hoje = DateTime.now();
DateTime _dia(int d) => DateTime(_hoje.year, _hoje.month, d);
const _r = TipoLancamento.receita;
const _d = TipoLancamento.despesa;
LancamentoModel _l(String t, double v, int dia, TipoLancamento tipo, String cat) =>
    LancamentoModel(titulo: t, valor: v, data: _dia(dia), tipo: tipo, categoria: cat);

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(prepararAparelho);

  testWidgets('FASE 1 — uso normal antes de reiniciar', (t) async {
    cabecalhoFase('Fase 1 — uso normal do app',
        'O app cria, edita e exclui dados pelos próprios serviços e escolhe o tema escuro. No fim, o estado é guardado para comparação.');
    conferir('Aparelho começa sem preferências salvas', preferenciasNoDisco(), {});

    // Conta: cadastro, edição de perfil e troca de senha
    await AuthService.register(nome: 'Paula Mendes', email: 'paula@teste.local', senha: 'inicial1');
    await AuthService.atualizarPerfil(nome: 'Paula M. Ribeiro', email: 'paula@teste.local');
    await AuthService.alterarSenha(senhaAtual: 'inicial1', novaSenha: 'definitiva9');
    await ThemeController.definir(ThemeMode.dark);
    await CategoriaService.carregar(force: true);
    await LancamentoService.carregar(force: true);

    // Lançamentos (inclui categoria criada pelo usuário e texto com acentos)
    await LancamentoService.adicionar(_l('Salário', 5200, 5, _r, 'Salário'));
    await LancamentoService.adicionar(_l('Logo — padaria São João', 850.5, 2, _r, 'Projetos'));
    await LancamentoService.adicionar(_l('Aluguel', 1450, 3, _d, 'Moradia'));
    final mercado = await LancamentoService.adicionar(_l('Mercado', 380.4, 4, _d, 'Alimentação'));
    await LancamentoService.editar(LancamentoModel(
        id: mercado.id, titulo: 'Mercado do mês', valor: 412.9, data: _dia(4), tipo: _d, categoria: 'Alimentação'));
    final cinema = await LancamentoService.adicionar(_l('Cinema', 45, 6, _d, 'Lazer'));
    await LancamentoService.remover(cinema);
    final notebook = await LancamentoService.adicionar(_l('Notebook', 3600, 1, _d, 'Compras'), parcelas: 4);
    await LancamentoService.carregar(force: true);
    final segunda = LancamentoService.getDespesas()
        .singleWhere((l) => l.parcelaGrupo == notebook.parcelaGrupo && l.parcelaNumero == 2);
    await LancamentoService.remover(segunda);

    // Metas
    await MetaService.criar(titulo: 'Reserva de emergência', valorMeta: 10000, valorInicial: 2000, icone: 'wallet');
    final reserva = MetaService.metas.singleWhere((m) => m.titulo == 'Reserva de emergência');
    await MetaService.aportar(reserva, 500);
    await MetaService.aportar(reserva, 250.75);
    await MetaService.criar(titulo: 'Viagem', valorMeta: 6000, icone: 'flight');
    await MetaService.criar(titulo: 'Carro', valorMeta: 40000, icone: 'car');
    final carro = MetaService.metas.singleWhere((m) => m.titulo == 'Carro');
    await MetaService.remover(carro.id);

    // Estado completo que deve sobreviver aos reinícios
    final mes = '${_hoje.year}-${_hoje.month.toString().padLeft(2, '0')}';
    final estado = {
      'usuario': await ApiClient.get('/users/me'),
      'categorias': await ApiClient.get('/categories'),
      'receitas': await ApiClient.get('/incomes'),
      'despesas': await ApiClient.get('/expenses'),
      'metas': await ApiClient.get('/goals'),
      'dashboard': await ApiClient.get('/dashboard'),
      'dashboard_mes': await ApiClient.get('/dashboard?month=$mes'),
      'saldo_no_app': LancamentoService.saldo,
      'excluidos': {
        'despesa_cinema': int.parse(cinema.id),
        'parcela_2_notebook': int.parse(segunda.id),
        'meta_carro': int.parse(carro.id),
      },
      'mes': mes,
    };
    arquivoEsperado.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(estado));

    conferir('Usuário com nome editado', (estado['usuario'] as Map)['name'], 'Paula M. Ribeiro');
    conferir('Receitas cadastradas', (estado['receitas'] as List).length, 2);
    conferir('Despesas (1 avulsa + mercado + 3 parcelas restantes)', (estado['despesas'] as List).length, 5);
    conferir('Metas (Carro excluída)', (estado['metas'] as List).map((m) => m['title']).toList()..sort(),
        ['Reserva de emergência', 'Viagem']);
    conferir('Valor guardado na reserva (2000 + 500 + 250,75)',
        (estado['metas'] as List).singleWhere((m) => m['title'] == 'Reserva de emergência')['current_amount'], 2750.75);
    final prefs = preferenciasNoDisco();
    conferir('Tema escuro gravado no arquivo do aparelho', prefs['flutter.theme_mode'], 'dark');
    conferir('Token de login gravado no arquivo do aparelho', (prefs['flutter.auth_token'] as String?)?.split('.').length, 3);

    // Fotografia da tela inicial (referência para comparar depois)
    await telaDeCelular(t);
    await t.pumpWidget(comTela(const FinanceiroApp(logado: true)));
    await esperar(t, find.textContaining(', Paula'));
    await assentar(t, 1500);
    await expectLater(find.byKey(telaKey), matchesGoldenFile('../evidencias/telas/inicio-referencia.png'));
    await salvarTela(t, 'fase1-inicio-antes');
    diario('\nCaptura: `telas/fase1-inicio-antes.png` (também salva como referência `inicio-referencia.png`).');
  });
}
