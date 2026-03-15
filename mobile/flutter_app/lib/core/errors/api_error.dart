import 'dart:io';

/// Structured API error with human-readable Spanish messages.
class ApiError {
  const ApiError({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetworkError;

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Parses a caught exception into an [ApiError].
  static ApiError fromException(dynamic e) {
    if (e is SocketException) {
      return const ApiError(
        message: 'No hay conexión a Internet. Verifica tu red e intenta de nuevo.',
        isNetworkError: true,
      );
    }

    // TimeoutException from dart:async — checked by type name to avoid importing
    // dart:async just for that class.
    if (e.runtimeType.toString() == 'TimeoutException') {
      return const ApiError(
        message: 'La solicitud tardó demasiado. Intenta de nuevo.',
        isNetworkError: true,
      );
    }

    if (e is HttpException) {
      return ApiError(
        message: 'Error de red: ${e.message}',
        isNetworkError: true,
      );
    }

    if (e is FormatException) {
      return ApiError(
        message: 'Respuesta inesperada del servidor: ${e.message}',
      );
    }

    if (e is ApiError) return e;

    return ApiError(message: e?.toString() ?? 'Ocurrió un error inesperado.');
  }

  /// Creates an [ApiError] from an HTTP status code and optional response body.
  static ApiError fromStatusCode(int code, [String? body]) {
    switch (code) {
      case 400:
        return ApiError(
          message: body?.isNotEmpty == true ? body! : 'Solicitud incorrecta.',
          statusCode: code,
        );
      case 401:
        return ApiError(
          message: 'Tu sesión ha expirado. Inicia sesión de nuevo.',
          statusCode: code,
        );
      case 403:
        return ApiError(
          message: 'No tienes permiso para realizar esta acción.',
          statusCode: code,
        );
      case 404:
        return ApiError(
          message: 'El recurso solicitado no fue encontrado.',
          statusCode: code,
        );
      case 409:
        return ApiError(
          message: body?.isNotEmpty == true ? body! : 'Conflicto con el estado actual del recurso.',
          statusCode: code,
        );
      case 422:
        return ApiError(
          message: body?.isNotEmpty == true ? body! : 'Los datos enviados no son válidos.',
          statusCode: code,
        );
      case 429:
        return ApiError(
          message: 'Demasiadas solicitudes. Espera un momento e intenta de nuevo.',
          statusCode: code,
        );
      case 500:
      case 502:
      case 503:
        return ApiError(
          message: 'El servidor no está disponible en este momento. Intenta más tarde.',
          statusCode: code,
        );
      default:
        return ApiError(
          message: 'Error del servidor (código $code).',
          statusCode: code,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Human-readable Spanish message suitable for display to the end user.
  String get userMessage => message;

  /// True when the error is an authentication failure (HTTP 401).
  bool get isAuthError => statusCode == 401;

  @override
  String toString() =>
      'ApiError(statusCode: $statusCode, isNetworkError: $isNetworkError, message: $message)';
}
