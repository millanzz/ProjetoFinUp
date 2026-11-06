import 'package:flutter/material.dart';

/// Visual de um emblema: pictograma branco sobre esfera colorida.
class EmblemaStyle {
  final IconData icon;
  final Color claro;
  final Color escuro;

  const EmblemaStyle(this.icon, this.claro, this.escuro);
}

/// Categorias de lançamento e o emblema de cada uma (Figma: "Emblema").
class Categorias {
  Categorias._();

  static const receita = ['Salário', 'Freelance', 'Investimentos', 'Bônus', 'Outros'];

  static const despesa = [
    'Alimentação', 'Transporte', 'Moradia', 'Saúde', 'Lazer',
    'Compras', 'Assinaturas', 'Impostos', 'Outros',
  ];

  static const Map<String, EmblemaStyle> _mapa = {
    'Alimentação': EmblemaStyle(Icons.restaurant, Color(0xffFFC966), Color(0xffE58A00)),
    'Transporte': EmblemaStyle(Icons.directions_car_filled, Color(0xff6EC3FF), Color(0xff1E7FD9)),
    'Moradia': EmblemaStyle(Icons.home_rounded, Color(0xff9AA6FF), Color(0xff4A55D6)),
    'Saúde': EmblemaStyle(Icons.favorite, Color(0xff5FE0CF), Color(0xff119C8C)),
    'Lazer': EmblemaStyle(Icons.movie, Color(0xffC6A2FF), Color(0xff7B4FE0)),
    'Compras': EmblemaStyle(Icons.shopping_cart, Color(0xffFF9EC4), Color(0xffD9508A)),
    'Assinaturas': EmblemaStyle(Icons.autorenew, Color(0xff74E0FA), Color(0xff1A9EC4)),
    'Impostos': EmblemaStyle(Icons.account_balance, Color(0xffB3BFD6), Color(0xff5E6E8C)),
    'Outros': EmblemaStyle(Icons.more_horiz, Color(0xffC2CCDC), Color(0xff6E7E99)),
    'Salário': EmblemaStyle(Icons.work, Color(0xff7BE8B5), Color(0xff17A065)),
    'Freelance': EmblemaStyle(Icons.laptop, Color(0xff8DB7FF), Color(0xff2F66E0)),
    'Investimentos': EmblemaStyle(Icons.trending_up, Color(0xff6FE0BE), Color(0xff0F8E68)),
    'Bônus': EmblemaStyle(Icons.star, Color(0xffFFE07A), Color(0xffE0A100)),
  };

  /// Categorias criadas pelo usuário (fora da lista) usam o emblema "Outros".
  static EmblemaStyle estilo(String? nome) => _mapa[nome] ?? _mapa['Outros']!;
}

/// Ícones de meta. O backend guarda a chave (ex.: "flight") no campo `icon`.
/// Emojis de metas antigas são convertidos para o ícone equivalente.
class MetaIcones {
  MetaIcones._();

  static const chaves = [
    'flag', 'wallet', 'home', 'car', 'flight',
    'phone', 'school', 'laptop', 'star', 'trend',
  ];

  static const Map<String, EmblemaStyle> _mapa = {
    'flag': EmblemaStyle(Icons.flag, Color(0xff8DB7FF), Color(0xff2F66E0)),
    'wallet': EmblemaStyle(Icons.account_balance_wallet, Color(0xff7BE8B5), Color(0xff17A065)),
    'home': EmblemaStyle(Icons.home_rounded, Color(0xff9AA6FF), Color(0xff4A55D6)),
    'car': EmblemaStyle(Icons.directions_car_filled, Color(0xffFFC966), Color(0xffE58A00)),
    'flight': EmblemaStyle(Icons.flight, Color(0xff6EC3FF), Color(0xff1E7FD9)),
    'phone': EmblemaStyle(Icons.smartphone, Color(0xffFF9EC4), Color(0xffD9508A)),
    'school': EmblemaStyle(Icons.school, Color(0xffC6A2FF), Color(0xff7B4FE0)),
    'laptop': EmblemaStyle(Icons.laptop, Color(0xff9AA6FF), Color(0xff4A55D6)),
    'star': EmblemaStyle(Icons.star, Color(0xffFFE07A), Color(0xffE0A100)),
    'trend': EmblemaStyle(Icons.trending_up, Color(0xff6FE0BE), Color(0xff0F8E68)),
  };

  static const Map<String, String> _emojis = {
    '🎯': 'flag', '💰': 'wallet', '🏠': 'home', '🚗': 'car', '✈️': 'flight',
    '📱': 'phone', '🎓': 'school', '💻': 'laptop', '🏖️': 'flight', '🎁': 'star',
  };

  static String normalizar(String? icone) {
    if (icone == null) return 'flag';
    if (_mapa.containsKey(icone)) return icone;
    return _emojis[icone] ?? 'flag';
  }

  static EmblemaStyle estilo(String? icone) => _mapa[normalizar(icone)]!;
}
