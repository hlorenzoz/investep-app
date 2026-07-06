/// Configuración de entorno, inyectada en tiempo de compilación con
/// `--dart-define` (o `--dart-define-from-file`). NUNCA hardcodees secretos:
/// se pasan al construir/ejecutar y quedan fuera del control de versiones.
///
/// Ejemplo:
//    flutter run --dart-define=API_BASE_URL=https://api.investepacademy.com \
///   flutter run --dart-define=API_BASE_URL=https://api-investep.hlorenzoz.com \
///               --dart-define=SUPABASE_URL=... \
///               --dart-define=SUPABASE_ANON_KEY=...
///
/// Nota fintech: la `anon key` de Supabase es pública por diseño. Los tokens de
/// brókers y credenciales sensibles NO viven nunca en el cliente (ver AGENTS.md).
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'https://api.investepacademy.com',
    defaultValue: 'https://api-investep.hlorenzoz.com',
  );

  static const String r2AssetsBaseUrl = String.fromEnvironment(
    'R2_ASSETS_BASE_URL',
    defaultValue: '',
  );

  static String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');

  static String supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Indica si la configuración mínima de Supabase está presente.
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Valida que la URL de Supabase y la anon key sean válidas y no sean placeholders.
  static bool get isValidSupabaseConfig {
    if (!hasSupabaseConfig) return false;
    if (supabaseUrl.contains('<') || supabaseUrl.contains('>')) return false;
    if (supabaseAnonKey.contains('<') || supabaseAnonKey.contains('>')) {
      return false;
    }
    try {
      final uri = Uri.parse(supabaseUrl);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }
}
