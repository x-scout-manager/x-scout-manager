# 003 Flutter Firebase初期化

## 現状の動作

Flutter側にFirebase SDKが未導入で、`core/firebase` はプレースホルダー。

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

## レビュー指摘

未記入。

## 備考

Firebase設定値は公開可能なWeb configのみ。秘密情報は置かない。
