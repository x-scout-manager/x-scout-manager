import 'package:flutter_test/flutter_test.dart';
import 'package:x_scout_manager/core/errors/functions_error_mapper.dart';

void main() {
  test('X APIのDM権限エラーを運用向け文言へ変換する', () {
    expect(
      FunctionsErrorMapper.messageFor(
        'You do not have permission to DM one or more participants.',
        'permission-denied',
      ),
      '送信先アカウントのDM受信設定またはX側の制限により送信できませんでした。相手がDMを受け取れる状態か確認してください。',
    );
    expect(
      FunctionsErrorMapper.messageFor(
        'This operation is not permitted.',
        'permission-denied',
      ),
      '送信先アカウントのDM受信設定またはX側の制限により送信できませんでした。相手がDMを受け取れる状態か確認してください。',
    );
  });

  test('X APIのトークン無効エラーを認可更新の案内へ変換する', () {
    expect(
      FunctionsErrorMapper.messageFor(
        'Value passed for the token was invalid',
        'unauthenticated',
      ),
      'X APIの認証情報が無効です。送信用アカウントのOAuth認可とFirebase Secretsを更新してください。',
    );
  });
}
