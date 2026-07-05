import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/data/services/auth_service.dart';
import 'package:xuro/data/services/exceptions/network_exception.dart';
import 'package:xuro/data/services/exceptions/update_exception.dart';

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
  return Strings.networkErrorGeneric;
}

String localizedPlayFailed(Object error) =>
    Strings.playFailed(userFacingError(error));

String localizedMarkFailed(Object error) =>
    Strings.markFailed(userFacingError(error));

String localizedOperationFailed(Object error) =>
    Strings.operationFailed(userFacingError(error));
