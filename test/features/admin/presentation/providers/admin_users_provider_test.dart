import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/admin/data/admin_repository.dart';
import 'package:investep_app/features/admin/domain/user_admin.dart';
import 'package:investep_app/features/admin/presentation/providers/admin_users_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository repo;
  late ProviderContainer container;

  final user = UserAdmin(
    id: 'u-1',
    email: 'test@example.com',
    role: 'user',
    fullName: 'Test User',
    createdAt: DateTime(2026, 7, 1),
    mustResetPassword: false,
  );

  setUp(() {
    repo = MockAdminRepository();
    container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  AdminUsersNotifier notifier() => container.read(adminUsersProvider.notifier);
  AsyncValue<List<UserAdmin>> currentState() =>
      container.read(adminUsersProvider);

  group('AdminUsersNotifier', () {
    test('build → obtiene la lista de usuarios del repositorio', () async {
      when(() => repo.getUsers()).thenAnswer((_) async => [user]);

      // Al escuchar por primera vez, dispara el build y pasa a loading
      container.listen(adminUsersProvider, (_, _) {});
      expect(currentState(), const AsyncValue<List<UserAdmin>>.loading());

      // Esperar a que se complete el build
      await container.pump();

      expect(currentState().value, [user]);
    });

    test('createUser → llama al repo y hace refresh de la lista', () async {
      final input = {
        'email': 'new@test.com',
        'fullName': 'New',
        'role': 'user',
      };
      when(() => repo.createUser(input)).thenAnswer((_) async => user);
      when(() => repo.getUsers()).thenAnswer((_) async => [user]);

      container.listen(adminUsersProvider, (_, _) {});
      await container.pump();

      await notifier().createUser(input);

      verify(() => repo.createUser(input)).called(1);
      verify(() => repo.getUsers()).called(2); // 1 en build, 1 tras crear
    });

    test('updateUser → llama al repo y hace refresh de la lista', () async {
      final updateData = {'fullName': 'Updated Name'};
      when(
        () => repo.updateUser('u-1', updateData),
      ).thenAnswer((_) async => user);
      when(() => repo.getUsers()).thenAnswer((_) async => [user]);

      container.listen(adminUsersProvider, (_, _) {});
      await container.pump();

      await notifier().updateUser('u-1', updateData);

      verify(() => repo.updateUser('u-1', updateData)).called(1);
      verify(() => repo.getUsers()).called(2);
    });

    test('deleteUser → llama al repo y actualiza el estado', () async {
      when(() => repo.deleteUser('u-1')).thenAnswer((_) async => {});
      when(() => repo.getUsers()).thenAnswer((_) async => []);

      container.listen(adminUsersProvider, (_, _) {});
      await container.pump();

      await notifier().deleteUser('u-1');

      verify(() => repo.deleteUser('u-1')).called(1);
      expect(currentState().value, isEmpty);
    });
  });
}
