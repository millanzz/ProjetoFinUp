/// Formatação de moeda e datas em pt-BR (sem depender do pacote intl).
class Fmt {
  Fmt._();

  static const meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const mesesCurtos = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
  static const _dow = ['Seg.', 'Ter.', 'Qua.', 'Qui.', 'Sex.', 'Sáb.', 'Dom.'];

  /// R$ 1.234,56
  static String brl(double v) {
    v = centavos(v);
    final partes = v.abs().toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${partes[1]}';
  }

  /// Arredonda para centavos (2 casas). Somas em ponto flutuante deixam
  /// resíduos como 0,30000000000000004; isto os elimina (DEF-01/02).
  static double centavos(double v) {
    final r = (v * 100).round() / 100;
    return r == 0 ? 0 : r; // também troca -0.0 por 0
  }

  /// Aceita "1.234,56", "1234,56" e "1234.56".
  static double? parseValor(String texto) {
    var s = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (s.isEmpty) return null;
    if (s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  /// 0,00 para preencher campos de valor.
  static String valorCampo(double v) =>
      v.toStringAsFixed(2).replaceAll('.', ',');

  static String dataCurta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// "Out 2026"
  static String mesAno(DateTime d) {
    final m = mesesCurtos[d.month - 1];
    return '${m[0].toUpperCase()}${m.substring(1)} ${d.year}';
  }

  /// "Sáb., 25 de outubro" (com o ano quando não é o ano atual).
  static String diaPorExtenso(DateTime d) {
    final base = '${_dow[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
    return d.year == DateTime.now().year ? base : '$base de ${d.year}';
  }

  /// Divide [total] em [n] parcelas sem perder centavos; a sobra vai
  /// para a 1ª parcela (mesma regra do backend).
  static List<double> dividirParcelas(double total, int n) {
    if (n <= 0) return const [];
    final centavos = (total * 100).round();
    final base = centavos ~/ n;
    final sobra = centavos - base * n;
    return [for (var i = 0; i < n; i++) (base + (i == 0 ? sobra : 0)) / 100];
  }

  /// "12x de R$ 100,00" ou "1x de R$ 33,34 + 2x de R$ 33,33".
  static String resumoParcelas(double total, int n) {
    final v = dividirParcelas(total, n);
    if (v.isEmpty) return '';
    if (n == 1 || v.first == v.last) return '${n}x de ${brl(v.last)}';
    return '1x de ${brl(v.first)} + ${n - 1}x de ${brl(v.last)}';
  }

  /// Porcentagem de cada valor sobre a soma de todos, como texto.
  ///
  /// Usa o método do maior resto: as porcentagens inteiras sempre
  /// somam exatamente 100%. Um valor real que arredondaria para 0
  /// aparece como "<1%" em vez de "0%".
  static List<String> percentuais(List<double> valores) {
    final total = valores.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return [for (final _ in valores) '0%'];

    final exatos = [for (final v in valores) v / total * 100];
    final inteiros = [for (final e in exatos) e.floor()];
    var falta = 100 - inteiros.fold<int>(0, (s, v) => s + v);

    // Distribui os pontos que faltam para quem tem o maior resto.
    final ordem = List<int>.generate(valores.length, (i) => i)
      ..sort((a, b) => (exatos[b] - inteiros[b]).compareTo(exatos[a] - inteiros[a]));
    for (final i in ordem) {
      if (falta <= 0) break;
      inteiros[i]++;
      falta--;
    }

    return [
      for (var i = 0; i < valores.length; i++)
        inteiros[i] == 0 && valores[i] > 0 ? '<1%' : '${inteiros[i]}%',
    ];
  }

  static bool mesmoMes(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool mesmoDia(DateTime a, DateTime b) =>
      mesmoMes(a, b) && a.day == b.day;
}
