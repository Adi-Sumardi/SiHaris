/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// Exception thrown when server returns 5xx error
class ServerException extends AppException {
  const ServerException({
    super.message = 'Terjadi kesalahan server',
    super.statusCode,
    super.data,
  });
}

/// Exception thrown when user is not authenticated (401)
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Sesi Anda telah berakhir',
    super.statusCode = 401,
    super.data,
  });
}

/// Exception thrown when resource is not found (404)
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Data tidak ditemukan',
    super.statusCode = 404,
    super.data,
  });
}

/// Exception thrown when validation fails (422)
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Validasi gagal',
    super.statusCode = 422,
    this.errors,
    super.data,
  });
}

/// Exception thrown when network is unavailable
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Tidak ada koneksi internet',
    super.statusCode,
    super.data,
  });
}

/// Exception thrown when request times out
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Koneksi timeout',
    super.statusCode,
    super.data,
  });
}

/// Exception thrown when cache operation fails
class CacheException extends AppException {
  const CacheException({
    super.message = 'Gagal mengakses cache',
    super.statusCode,
    super.data,
  });
}

/// Exception thrown for bad request (400)
class BadRequestException extends AppException {
  const BadRequestException({
    super.message = 'Permintaan tidak valid',
    super.statusCode = 400,
    super.data,
  });
}

/// Exception thrown for forbidden access (403)
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Akses ditolak',
    super.statusCode = 403,
    super.data,
  });
}
