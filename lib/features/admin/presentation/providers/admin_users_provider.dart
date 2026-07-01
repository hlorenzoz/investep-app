import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../domain/user_admin.dart';

class AdminUsersNotifier extends AsyncNotifier<List<UserAdmin>> {
  @override
  Future<List<UserAdmin>> build() {
    return ref.watch(adminRepositoryProvider).getUsers();
  }

  /// Crea un nuevo usuario. Si falla, propaga la excepción para que el
  /// diálogo del formulario la maneje localmente.
  Future<void> createUser(Map<String, dynamic> data) async {
    await ref.read(adminRepositoryProvider).createUser(data);
    await refresh();
  }

  /// Actualiza un usuario existente. Si falla, propaga la excepción.
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await ref.read(adminRepositoryProvider).updateUser(id, data);
    await refresh();
  }

  /// Elimina un usuario por su ID.
  Future<void> deleteUser(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(adminRepositoryProvider).deleteUser(id);
      return ref.read(adminRepositoryProvider).getUsers();
    });
  }

  /// Recarga la lista de usuarios desde el servidor.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(adminRepositoryProvider).getUsers();
    });
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<UserAdmin>>(
      AdminUsersNotifier.new,
    );
