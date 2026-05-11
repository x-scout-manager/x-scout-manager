import 'app_error.dart';

class FirebaseErrorMapper {
  const FirebaseErrorMapper._();

  static AppError map(Object error) {
    return AppError(error.toString());
  }
}
