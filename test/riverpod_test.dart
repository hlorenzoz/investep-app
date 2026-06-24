import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:investep_app/features/auth/presentation/login_controller.dart';

void main() {
  test('LoginController arranca con estado LoginInitial', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(loginControllerProvider);
    expect(state, isA<LoginInitial>());
  });
}
