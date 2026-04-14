import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_handler.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  final sb.SupabaseClient _client;

  AuthRepository(this._client);

  /// Inicia sesión con cédula y contraseña.
  /// El email de auth se construye internamente como {cedula}@mercados.app.
  /// Lanza [AuthException] si las credenciales son incorrectas o el usuario
  /// está inactivo.
  Future<AppUser> signIn(String cedula, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: '$cedula@mercados.app',
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('No se pudo iniciar sesión. Intente de nuevo.');
      }

      // Verificar is_active desde la tabla users
      final userData = await _client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        await _client.auth.signOut();
        throw const AuthException(
          'Usuario no encontrado. Contacte al administrador.',
        );
      }

      if (!(userData['is_active'] as bool)) {
        await _client.auth.signOut();
        throw const AuthException(
          'Su cuenta está inactiva. Contacte al administrador.',
        );
      }

      return AppUser.fromJson(userData);
    } on AuthException {
      rethrow;
    } on sb.AuthException catch (e) {
      throw AuthException(mapAuthErrorMessage(e.message));
    } on sb.PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      throw wrapUnknownError(e);
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw wrapUnknownError(e);
    }
  }

  /// Retorna el usuario actual si hay sesión persistida válida.
  /// Se llama al iniciar la app para restaurar sesiones previas.
  Future<AppUser?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    try {
      final userData = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (userData == null) return null;

      // Forzar logout si el usuario fue desactivado mientras tenía sesión activa
      if (!(userData['is_active'] as bool)) {
        await _client.auth.signOut();
        return null;
      }

      return AppUser.fromJson(userData);
    } catch (_) {
      // En caso de error de red al restaurar sesión, devolvemos null
      // para que el usuario inicie sesión manualmente
      return null;
    }
  }

  /// Stream de cambios de estado de autenticación de Supabase.
  Stream<sb.AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
