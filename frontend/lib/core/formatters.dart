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
    final partes = v.abs().toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${partes[1]}';
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

  static bool mesmoMes(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool mesmoDia(DateTime a, DateTime b) =>
      mesmoMes(a, b) && a.day == b.day;
}
