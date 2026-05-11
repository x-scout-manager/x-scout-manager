import 'app_error.dart';

class FunctionsErrorMapper {
  const FunctionsErrorMapper._();

  static AppError map(Object error) {
    return AppError(error.toString());
  }
}
