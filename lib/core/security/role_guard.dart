import 'package:supabase_flutter/supabase_flutter.dart';

/// Helpers para leer y validar el rol del usuario desde el JWT.
/// El rol se lee siempre del JWT del servidor; nunca se almacena en estado local
/// como fuente de verdad (ver CLAUDE.md sección 6).
class RoleGuard {
  RoleGuard._();

  static const String admin = 'ADMINISTRADOR';
  static const String asistente = 'ASISTENTE';
  static const String beneficiario = 'BENEFICIARIO';

  /// Extrae el rol desde [user_metadata] del JWT del usuario actual.
  /// Retorna null si no hay sesión activa.
  static String? getRole(SupabaseClient client) {
    return client.auth.currentUser?.userMetadata?['role'] as String?;
  }

  static bool isAdmin(SupabaseClient client) => getRole(client) == admin;

  static bool isAsistente(SupabaseClient client) =>
      getRole(client) == asistente;

  static bool isBeneficiario(SupabaseClient client) =>
      getRole(client) == beneficiario;

  /// Retorna true si el rol tiene acceso al panel de administración
  /// (ADMINISTRADOR o ASISTENTE).
  static bool hasAdminAccess(SupabaseClient client) {
    final role = getRole(client);
    return role == admin || role == asistente;
  }
}
