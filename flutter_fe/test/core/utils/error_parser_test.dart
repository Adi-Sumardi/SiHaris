import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/errors/exceptions.dart';
import 'package:gaji_pro/core/utils/error_parser.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ErrorParser', () {
    group('isNetworkError', () {
      test('should identify SocketException as network error', () {
        const exception = SocketException('Failed host lookup: siharis.yapinet.id');
        expect(ErrorParser.isNetworkError(exception), isTrue);
      });

      test('should identify http.ClientException with SocketException string', () {
        final exception = http.ClientException(
          'ClientException with SocketException: Failed host lookup: \'siharis.yapinet.id\' (OS Error: No address associated with hostname, errno = 7), uri=https://siharis.yapinet.id/api/v1/dashboard',
        );
        expect(ErrorParser.isNetworkError(exception), isTrue);
      });

      test('should identify raw network error strings', () {
        expect(
          ErrorParser.isNetworkError('Failed host lookup: \'siharis.yapinet.id\''),
          isTrue,
        );
        expect(
          ErrorParser.isNetworkError('OS Error: Connection refused, errno = 111'),
          isTrue,
        );
        expect(
          ErrorParser.isNetworkError('Network is unreachable'),
          isTrue,
        );
        expect(
          ErrorParser.isNetworkError('Software caused connection abort'),
          isTrue,
        );
      });

      test('should identify NetworkException as network error', () {
        final exception = NetworkException(message: 'Tidak ada koneksi');
        expect(ErrorParser.isNetworkError(exception), isTrue);
      });

      test('should not identify regular user validation error as network error', () {
        expect(ErrorParser.isNetworkError('Email atau password salah'), isFalse);
        expect(ErrorParser.isNetworkError('Data tidak ditemukan'), isFalse);
      });
    });

    group('isTimeoutError', () {
      test('should identify TimeoutException as timeout error', () {
        final exception = TimeoutException(message: 'Connection timed out');
        expect(ErrorParser.isTimeoutError(exception), isTrue);
      });

      test('should identify timeout strings', () {
        expect(ErrorParser.isTimeoutError('Connection timed out after 30000ms'), isTrue);
        expect(ErrorParser.isTimeoutError('deadline exceeded'), isTrue);
      });
    });

    group('isTechnicalError', () {
      test('should identify raw exception strings', () {
        expect(ErrorParser.isTechnicalError('ClientException: Failed host lookup'), isTrue);
        expect(ErrorParser.isTechnicalError('TypeError: null is not a subtype of int'), isTrue);
        expect(ErrorParser.isTechnicalError('FormatException: Unexpected character at line 1'), isTrue);
        expect(ErrorParser.isTechnicalError('uri=https://siharis.yapinet.id/api/v1/dashboard'), isTrue);
      });

      test('should not identify friendly messages as technical errors', () {
        expect(ErrorParser.isTechnicalError('Email atau password salah'), isFalse);
        expect(ErrorParser.isTechnicalError('Permintaan cuti berhasil diajukan'), isFalse);
      });
    });

    group('parseException', () {
      test('should format raw SocketException/ClientException to clean Indonesian message', () {
        final rawOfflineError =
            "ClientException with SocketException: Failed host lookup: 'siharis.yapinet.id' (OS Error: No address associated with hostname, errno = 7), uri=https://siharis.yapinet.id/api/v1/dashboard";
        final result = ErrorParser.parseException(rawOfflineError);
        expect(
          result,
          'Terjadi kesalahan koneksi: Tidak ada koneksi internet. Silakan periksa jaringan Wi-Fi atau data seluler Anda.',
        );
      });

      test('should format TimeoutException to user friendly message', () {
        final result = ErrorParser.parseException(TimeoutException(message: 'timed out'));
        expect(
          result,
          'Koneksi ke server terputus (timeout). Silakan coba lagi beberapa saat.',
        );
      });

      test('should format ServerException with status code', () {
        final result = ErrorParser.parseException(ServerException(statusCode: 500, message: 'Internal Server Error'));
        expect(
          result,
          'Terjadi kendala pada server (Kode: 500). Silakan coba beberapa saat lagi.',
        );
      });

      test('should format TypeError and FormatException to user friendly message', () {
        final typeError = TypeError();
        expect(
          ErrorParser.parseException(typeError),
          'Format respon server tidak sesuai. Silakan coba lagi.',
        );
      });

      test('should preserve friendly string messages while stripping Exception prefix', () {
        expect(
          ErrorParser.parseException('Exception: Email sudah terdaftar'),
          'Email sudah terdaftar',
        );
        expect(
          ErrorParser.parseException('Sesi Anda telah berakhir'),
          'Sesi Anda telah berakhir',
        );
      });
    });

    group('parse response body', () {
      test('should extract and clean message from map', () {
        final body = {'message': 'Email atau password salah'};
        expect(ErrorParser.parse(body), 'Email atau password salah');
      });

      test('should extract nested errors map if message not present', () {
        final body = {
          'errors': {
            'email': ['Format email tidak valid'],
          }
        };
        expect(ErrorParser.parse(body), 'Format email tidak valid');
      });

      test('should sanitize technical error inside response body', () {
        final body = {
          'message': 'SQLSTATE[HY000]: General error: 1364 Field uri=https://api...',
        };
        expect(
          ErrorParser.parse(body, fallback: 'Terjadi kesalahan pada sistem. Silakan coba beberapa saat lagi.'),
          'Terjadi kesalahan pada sistem. Silakan coba beberapa saat lagi.',
        );
      });
    });
  });
}
