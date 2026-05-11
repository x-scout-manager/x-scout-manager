# 003 Flutter Firebase初期化

## 現状の動作

Flutter側にFirebase SDKを導入済み。

`lib/firebase_options.dart` は Firebase Web App `x-scout-manager-web` から生成済み。

`lib/core/firebase/firebase_app.dart` で Firebase 初期化を集約し、`lib/main.dart` から起動前に呼び出す。

## 期待する動作

Flutter WebからFirebaseを初期化できる。

## 操作フロー

1. Firebase依存を追加
2. `flutterfire configure` を実行
3. `firebase_options.dart` を生成
4. `FirebaseAppInitializer` を実装

## UI参考（既存画面）

起動時にアプリが正常表示されること。

## 技術方針

Firebase SDK依存は `core/firebase` に集約する。

## 対象ファイル（推定）

- `pubspec.yaml`
- `lib/main.dart`
- `lib/core/firebase/firebase_app.dart`
- `lib/firebase_options.dart`
- `docs/lib_function_roles_full.md`

## 完了条件

- `flutter analyze` が通る
- `flutter test` が通る
- Firebase初期化後もWeb起動できる

## 実施済み

- [x] Firebase依存を追加
- [x] `flutterfire configure` を実行
- [x] `lib/firebase_options.dart` を生成
- [x] `FirebaseAppInitializer` を実装
- [x] `flutter analyze` 成功
- [x] `flutter test` 成功
- [x] `flutter build web` 成功

## 残作業

なし。

## レビュー指摘

未記入。

## 備考

Firebase設定値は公開可能なWeb configのみ。秘密情報は置かない。
