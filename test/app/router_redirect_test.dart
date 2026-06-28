import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/app/router.dart';
import 'package:investep_app/core/auth/auth_gate.dart';
import 'package:investep_app/features/auth/domain/auth_user.dart';

void main() {
  final user = AuthUser(id: 'u', email: 'u@e.com', mustResetPassword: false);

  group('gateRedirect', () {
    test('GateChecking → siempre /splash salvo si ya está', () {
      expect(gateRedirect(const GateChecking(), '/'), '/splash');
      expect(gateRedirect(const GateChecking(), '/login'), '/splash');
      expect(gateRedirect(const GateChecking(), '/splash'), isNull);
    });

    test('GateRetrying503 → /splash', () {
      expect(gateRedirect(const GateRetrying503('x'), '/'), '/splash');
      expect(gateRedirect(const GateRetrying503('x'), '/splash'), isNull);
    });

    test('GateNoSession → /login', () {
      expect(gateRedirect(const GateNoSession(), '/'), '/login');
      expect(gateRedirect(const GateNoSession(), '/setup'), '/login');
      expect(gateRedirect(const GateNoSession(), '/login'), isNull);
    });

    test('GateNeedsPasswordReset → fuerza /change-password (insalvable)', () {
      final gate = GateNeedsPasswordReset(user);
      // Cualquier intento de ir a otro lado (back, deep-link) se rebota.
      expect(gateRedirect(gate, '/'), '/change-password');
      expect(gateRedirect(gate, '/login'), '/change-password');
      expect(gateRedirect(gate, '/setup'), '/change-password');
      expect(gateRedirect(gate, '/splash'), '/change-password');
      // Sólo se permite quedarse en /change-password.
      expect(gateRedirect(gate, '/change-password'), isNull);
    });

    test('GateAuthenticated → rebota fuera de rutas de auth', () {
      final gate = GateAuthenticated(user);
      expect(gateRedirect(gate, '/login'), '/');
      expect(gateRedirect(gate, '/splash'), '/');
      // Rutas de app permitidas (incluyendo cambio voluntario de contraseña).
      expect(gateRedirect(gate, '/change-password'), isNull);
      expect(gateRedirect(gate, '/'), isNull);
      expect(gateRedirect(gate, '/setup'), isNull);
    });
  });
}
