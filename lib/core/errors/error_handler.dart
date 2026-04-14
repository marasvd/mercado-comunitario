import 'app_exception.dart';

/// Mapea mensajes de error de Supabase Auth a mensajes legibles para el usuario.
String mapAuthErrorMessage(String raw) {
  final lower = raw.toLowerCase();

  if (lower.contains('invalid login credentials') ||
      lower.contains('invalid email or password')) {
    return 'Cédula o contraseña incorrectos.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Cuenta no confirmada. Contacte al administrador.';
  }
  if (lower.contains('too many requests')) {
    return 'Demasiados intentos. Espere un momento antes de intentar de nuevo.';
  }
  if (lower.contains('network') || lower.contains('connection')) {
    return 'Sin conexión a internet. Verifique su red.';
  }

  return 'Error de autenticación. Intente de nuevo.';
}

/// Convierte cualquier error desconocido en un [AppException] con mensaje legible.
AppException wrapUnknownError(Object e) {
  if (e is AppException) return e;
  return const AppException('Error inesperado. Intente de nuevo.');
}
