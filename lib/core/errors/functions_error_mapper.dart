import 'package:cloud_functions/cloud_functions.dart';

import 'app_error.dart';

class FunctionsErrorMapper {
  const FunctionsErrorMapper._();

  static AppError map(Object error) {
    if (error is FirebaseFunctionsException) {
      return AppError(error.message ?? error.code, code: error.code);
    }

    return AppError(error.toString());
  }
}
