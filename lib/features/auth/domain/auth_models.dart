/// Representa al usuario autenticado con datos combinados de
/// Supabase Auth y la tabla [users].
class AppUser {
  final String id;
  final String orgId;
  final String cedula;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.orgId,
    required this.cedula,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      cedula: json['cedula'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  bool get isAdmin => role == 'ADMINISTRADOR';
  bool get isAsistente => role == 'ASISTENTE';
  bool get isBeneficiario => role == 'BENEFICIARIO';
  bool get hasAdminAccess => isAdmin || isAsistente;
}
