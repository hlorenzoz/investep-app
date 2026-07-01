/// Modelo de datos que representa el usuario autenticado retornado por
/// la API en el endpoint `GET /auth/me`.
class AuthUser {
  final String id;
  final String email;
  final String role;
  final bool mustResetPassword;

  AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.mustResetPassword,
  });

  /// Construye una instancia a partir del JSON retornado por la API de Investep.
  /// Formato esperado:
  /// {
  ///   "user": {
  ///     "id": "...",
  ///     "email": "...",
  ///     "role": "...",
  ///     "mustResetPassword": false
  ///   }
  /// }
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>;
    return AuthUser(
      id: userMap['id'] as String,
      email: userMap['email'] as String,
      role: userMap['role'] as String? ?? 'user',
      mustResetPassword: userMap['mustResetPassword'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': id,
        'email': email,
        'role': role,
        'mustResetPassword': mustResetPassword,
      },
    };
  }
}
