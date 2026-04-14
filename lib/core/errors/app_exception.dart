class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class StockException extends AppException {
  const StockException(super.message, {super.code});
}

class JornadaException extends AppException {
  const JornadaException(super.message, {super.code});
}
