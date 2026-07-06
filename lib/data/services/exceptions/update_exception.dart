import 'package:dio/dio.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// Update-check error classification.
///
/// **Does not reuse `NetworkException`**: its copy is asmr.one-specific (VPN/login hints).
/// GitHub 403/429 is rate limiting, not auth failure.
enum UpdateErrorType {
  /// Connection failure / timeout / TLS / unknown network error.
  network,

  /// Unauthenticated GitHub REST rate limit: 60/hour/IP → 403 or 429.
  rateLimited,

  /// Repository / releases endpoint 404.
  notFound,

  /// Empty list or no tag matching `vX.Y.Z`.
  noRelease,

  /// Invalid JSON / missing required fields.
  invalidPayload,

  /// Other uncategorized error.
  unknown,
}

class UpdateException implements Exception {
  final UpdateErrorType type;

  /// Technical message for logs only.
  final String message;
  final int? statusCode;
  final dynamic originalError;

  UpdateException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  factory UpdateException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return UpdateException(
          type: UpdateErrorType.network,
          message: LogStrings.logNetworkErrorEMessage80c20(e.message),
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 403 || code == 429) {
          // Public read-only 403/429 ≈ unauthenticated rate limit (GitHub docs).
          return UpdateException(
            type: UpdateErrorType.rateLimited,
            message: LogStrings.logGithubRateLimited(code),
            statusCode: code,
            originalError: e,
          );
        }
        if (code == 404) {
          return UpdateException(
            type: UpdateErrorType.notFound,
            message: LogStrings.logReleaseNotFound404,
            statusCode: code,
            originalError: e,
          );
        }
        return UpdateException(
          type: UpdateErrorType.unknown,
          message: LogStrings.logResponseErrorCode(code),
          statusCode: code,
          originalError: e,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return UpdateException(
          type: UpdateErrorType.network,
          message: LogStrings.logNetworkErrorEMessage80c20(e.message),
          originalError: e,
        );
    }
  }

  /// User-facing recovery guidance.
  String get userMessage {
    switch (type) {
      case UpdateErrorType.network:
        return Strings.updateErrorNetwork;
      case UpdateErrorType.rateLimited:
        return Strings.updateErrorRateLimited;
      case UpdateErrorType.notFound:
        return Strings.updateErrorNotFound;
      case UpdateErrorType.noRelease:
        return Strings.updateErrorNoRelease;
      case UpdateErrorType.invalidPayload:
        return Strings.updateErrorInvalidPayload;
      case UpdateErrorType.unknown:
        return Strings.updateErrorUnknown;
    }
  }

  @override
  String toString() => 'UpdateException($type): $message';
}
