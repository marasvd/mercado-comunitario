class AppStrings {
  AppStrings._();

  static const String appName = 'Mercados Comunitarios';

  // Login
  static const String loginTitle = 'Bienvenido';
  static const String loginSubtitle = 'Ingrese con su cédula y contraseña';
  static const String cedulaLabel = 'Cédula';
  static const String cedulaHint = 'Número de cédula';
  static const String passwordLabel = 'Contraseña';
  static const String loginButton = 'Ingresar';
  static const String loggingIn = 'Ingresando...';

  // Validaciones
  static const String fieldRequired = 'Este campo es obligatorio';
  static const String cedulaInvalid = 'Ingrese una cédula válida (solo números)';
  static const String passwordTooShort =
      'La contraseña debe tener al menos 4 caracteres';

  // Errores generales
  static const String unexpectedError = 'Error inesperado. Intente de nuevo.';
  static const String noConnection = 'Sin conexión a internet.';

  // Roles
  static const String roleAdmin = 'Administrador';
  static const String roleAsistente = 'Asistente';
  static const String roleBeneficiario = 'Beneficiario';
}
