import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/auth/domain/password_policy.dart';

void main() {
  group('validateNewPassword', () {
    test('rechaza valor nulo o vacío', () {
      expect(validateNewPassword(null), isNotNull);
      expect(validateNewPassword(''), isNotNull);
    });

    test('rechaza si es más corta que la longitud mínima', () {
      final corta = 'a' * (passwordMinLength - 1);
      expect(validateNewPassword(corta), isNotNull);
    });

    test('acepta si cumple la longitud mínima', () {
      final valida = 'a' * passwordMinLength;
      expect(validateNewPassword(valida), isNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test('rechaza confirmación vacía', () {
      expect(validatePasswordConfirmation('', 'secreto123'), isNotNull);
      expect(validatePasswordConfirmation(null, 'secreto123'), isNotNull);
    });

    test('rechaza si no coincide con el original', () {
      expect(validatePasswordConfirmation('otra12345', 'secreto123'), isNotNull);
    });

    test('acepta si coincide con el original', () {
      expect(validatePasswordConfirmation('secreto123', 'secreto123'), isNull);
    });
  });
}
