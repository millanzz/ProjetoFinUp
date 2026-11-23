// Verificação do DEF-18: ao sair da conta, o token precisa estar apagado do
// aparelho assim que logout() termina (antes a remoção era disparada sem esperar).
// Rodar (na pasta frontend):  flutter test ../testes/reteste/logout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FinUp/core/formatters.dart';
import 'package:FinUp/services/api_client.dart';
import 'package:FinUp/services/auth_service.dart';

void main() {
  test('DEF-18 logout() só termina depois de apagar o token do aparelho', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'token.de.teste', 'theme_mode': 'dark'});
    await ApiClient.carregarToken();
    expect(ApiClient.temToken, isTrue);

    await AuthService.logout();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull, reason: 'token ainda salvo depois do logout');
    expect(prefs.getString('theme_mode'), 'dark', reason: 'o tema não deve ser apagado');
    expect(ApiClient.temToken, isFalse);
    expect(AuthService.isLogged(), isFalse);
  });

  test('DEF-01/02 arredondamento: 0,30 − (0,10 + 0,20) vira 0 e mostra "R\$ 0,00"', () {
    final bruto = 0.3 - (0.1 + 0.2); // −5,55e-17: o resíduo original do double
    expect(bruto, isNot(0));
    expect(Fmt.centavos(bruto), 0);
    expect(Fmt.brl(bruto), 'R\$ 0,00');
  });
}
