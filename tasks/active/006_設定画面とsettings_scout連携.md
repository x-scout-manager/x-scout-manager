# 006 設定画面とsettings_scout連携

## 現状の動作

タグ設定、除外キーワード設定、システム設定は静的表示のみ。

## 期待する動作

`settings/scout` の読み書きができる。

## 操作フロー

1. 設定画面を開く
2. タグ/除外キーワード/基本設定を編集
3. 保存
4. 再読み込み後も値が表示される

## UI参考（既存画面）

- `TagSettingPage`
- `ExclusionKeywordSettingPage`
- `SystemSettingPage`

## 技術方針

`features/settings` と `features/exclusions` のRepository/UseCase/VMに分離する。

## 対象ファイル（推定）

- `lib/features/settings/**`
- `lib/features/exclusions/**`
- `lib/app/di/providers.dart`

## 完了条件

- `settings/scout` に保存できる
- バリデーションがある
- `flutter analyze` と `flutter test` が通る

## レビュー指摘

未記入。

## 備考

空タグ、重複タグを防ぐ。
