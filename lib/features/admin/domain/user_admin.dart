class UserAdmin {
  final String id;
  final String email;
  final String role;
  final String fullName;
  final DateTime createdAt;
  final bool mustResetPassword;
  final String? planSlug;

  UserAdmin({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    required this.createdAt,
    required this.mustResetPassword,
    this.planSlug,
  });

  /// Construye una instancia a partir del JSON retornado por la API de admin.
  factory UserAdmin.fromJson(Map<String, dynamic> json) {
    return UserAdmin(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      fullName: json['fullName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      mustResetPassword: json['mustResetPassword'] as bool? ?? false,
      planSlug: json['planSlug'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
      'mustResetPassword': mustResetPassword,
      'planSlug': planSlug,
    };
  }
}
