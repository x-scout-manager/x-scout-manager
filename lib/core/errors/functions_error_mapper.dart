import 'package:cloud_functions/cloud_functions.dart';

import 'app_error.dart';

class FunctionsErrorMapper {
  const FunctionsErrorMapper._();

  static AppError map(Object error) {
    if (error is FirebaseFunctionsException) {
      return AppError(
        messageFor(error.message ?? error.code, error.code),
        code: error.code,
      );
    }

    return AppError(error.toString());
  }

  static String messageFor(String message, String code) {
    final normalized = message.toLowerCase();
    if (normalized.contains('permission to dm') ||
        normalized.contains('operation is not permitted')) {
      return '送信先アカウントのDM受信設定またはX側の制限により送信できませんでした。相手がDMを受け取れる状態か確認してください。';
    }

    if (normalized.contains('value passed for the token was invalid')) {
      return 'X APIの認証情報が無効です。送信用アカウントのOAuth認可とFirebase Secretsを更新してください。';
    }

    if (code == 'unauthenticated') {
      return 'X APIまたはログインの認証情報が無効です。再ログイン、または送信用アカウントのOAuth認可を確認してください。';
    }

    return message;
  }
}
