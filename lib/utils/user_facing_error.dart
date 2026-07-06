import 'package:lizunemu/core/audio/utils/audio_error_handler.dart';
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/services/auth_service.dart';
import 'package:lizunemu/data/services/exceptions/network_exception.dart';
import 'package:lizunemu/data/services/exceptions/update_exception.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';

/// Thrown when [message] is already localized for the current locale.
class UserFacingException implements Exception {
  const UserFacingException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Maps thrown errors to localized user-facing copy.
String userFacingError(Object error) {
  if (error is UserFacingException) return error.message;
  if (error is NetworkException) return error.userMessage;
  if (error is UpdateException) return error.userMessage;
  if (error is RegisteredButNotLoggedInException) {
    return Strings.registerOkButLoginFailed;
  }
  if (error is PlayerException) {
    final message = error.message;
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return Strings.networkErrorGeneric;
  }
  if (error is AudioError) {
    return Strings.networkErrorGeneric;
  }
  if (error is Exception &&
      error.toString().contains(LogStrings.logNoAudioSources)) {
    return Strings.networkErrorGeneric;
  }
  if (error is DioException) {
    return NetworkException.fromDioException(error).userMessage;
  }
  return Strings.networkErrorGeneric;
}

String localizedPlayFailed(Object error) =>
    Strings.playFailed(userFacingError(error));

String localizedMarkFailed(Object error) =>
    Strings.markFailed(userFacingError(error));

String localizedOperationFailed(Object error) =>
    Strings.operationFailed(userFacingError(error));
