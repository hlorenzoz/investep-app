import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro del token de sesión de Supabase.
///
/// Usa el almacén cifrado del sistema (Keychain en iOS/macOS, Keystore en
/// Android, etc.). NUNCA guardes el token en SharedPreferences en claro
/// (ver AGENTS.md §5). Acá sólo vive el token de SESIÓN; los tokens de brókers
/// jamás llegan al cliente.
class SecureSessionStore {
  SecureSessionStore(this._storage);

  static const _sessionKey = 'investep_session_token';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(String token) =>
      _storage.write(key: _sessionKey, value: token);

  Future<String?> readSession() => _storage.read(key: _sessionKey);

  Future<void> clearSession() => _storage.delete(key: _sessionKey);
}

/// Provider del almacén seguro. En v10+ el cifrado por defecto ya está
/// respaldado por el almacén nativo del SO (Keystore en Android, Keychain en
/// iOS/macOS), así que no hace falta configuración extra.
final secureSessionStoreProvider = Provider<SecureSessionStore>((ref) {
  const storage = FlutterSecureStorage();
  return SecureSessionStore(storage);
});
