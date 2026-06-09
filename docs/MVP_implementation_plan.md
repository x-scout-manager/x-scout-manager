# MVP実装計画

## 1. 目的

Xスカウト支援ツールのMVPを、外部APIリスクを抑えながら段階的に実装するための順序を定義する。

本計画では、候補管理と送信履歴を先に成立させたうえで、API DM送信を基本導線、手動送信支援をフォールバック導線として実装する。
成果記録UIは初期運用ではメイン導線から外し、必要になった場合に成約記録/成果メモとして再設計する。

## 2. 現在の状態

完了済み:

- 要件定義docs作成
- 基本設計docs作成
- アーキテクチャ方針docs作成
- アカウント・リポジトリ移管方針docs作成
- Flutter Webプロジェクト作成
- Flutter `core + features + MVVM` 骨組み作成

## 3. 実装フェーズ

## フェーズ0: 所有アカウント・環境方針確定

### 目的

納品時に資産移管で揉めない状態を作る。

### タスク

- 納品先所有アカウントの有無を確認
- ない場合は案件専用Googleアカウント作成
- GitHub Organization作成
- Firebase/GCPの作成主体を決定
- X Developer Appの作成主体を決定
- Billing管理者を決定

### 完了条件

- `docs/account_repository_handover_policy.md` に沿った運用が可能
- FirebaseとGitHubの所有者が開発者個人アカウントに依存していない

## フェーズ1: Firebase基盤

### タスク

- Firebaseプロジェクト作成
- Firebase Hosting設定
- Firebase Authentication有効化
- Firestore作成
- Cloud Functions TypeScript環境構築
- Firebase Emulator利用方針決定
- `.firebaserc`、`firebase.json` 作成

### 完了条件

- Flutter WebからFirebase初期化できる
- 管理者ユーザーを作成できる
- Cloud Functionsの空関数をdeployまたはemulator実行できる

## フェーズ2: 認証・管理者権限

### タスク

- Flutter Firebase依存追加
- `firebase_options.dart` 生成
- ログイン画面実装
- `users/{uid}` による管理者判定
- 未ログイン時のリダイレクト
- 権限なし表示

### 完了条件

- 管理者のみ管理画面にアクセスできる
- 未ログイン時にログイン画面へ誘導される

## フェーズ3: 設定・テンプレート

### タスク

- `settings/scout` 読み書き
- タグ設定画面
- 除外キーワード設定画面
- テンプレート画面
- Firestore Rules初期設定

### 完了条件

- タグ、除外キーワード、テンプレートを保存できる
- 保存値が再読み込み後も表示される

## フェーズ4: 手動送信支援MVP

### タスク

- 候補の手動登録またはダミー登録導線
- 候補一覧
- 候補詳細
- 送信対象チェック
- `createSendQueue`
- 送信キュー画面
- 本文コピー
- `markAsManuallySent`
- 送信履歴画面

### 完了条件

- X APIなしでも候補に対して手動送信済み登録ができる
- `send_histories` に `sendMethod = manual` で履歴が残る
- 同一Xユーザーへ二重登録できない

## フェーズ5: 除外・成果記録

### タスク

- `excludeCandidate`
- `restoreCandidate`
- 除外リスト画面
- `createConversion`
- 成約記録画面

### 完了条件

- 除外対象には送信できない
- 成約記録登録時に候補・送信履歴の証跡が保存される
- 対象売上と補足メモが保存される

## フェーズ6: X API検証

### タスク

- X Developer App設定
- OAuth 2.0 PKCE検証
- 投稿検索検証
- ユーザー情報取得検証
- DM送信検証
- レート制限確認
- 検証結果記録

### 完了条件

- `docs/DETAIL_x_api_verification.md` の成功条件に基づいて、API送信可否を判断できる

## フェーズ7: X API候補抽出

### タスク

- `syncCandidates`
- X API投稿検索
- ユーザー情報取得
- プロフィール除外判定
- 重複候補統合
- function_logs保存

### 完了条件

- 指定タグから候補を抽出できる
- 除外キーワードに一致した候補が除外される
- 既送信者が再候補化されない

## フェーズ8: API DM送信

### 前提

X API検証でDM送信が利用可能と判断された場合のみ実施する。

### タスク

- `sendDirectMessage`
- X API DM送信
- 送信中ロック
- 成功時履歴保存
- 失敗時failed保存
- API送信有効/無効設定

### 完了条件

- 管理者操作1回につき1候補者のみDM送信できる
- 二重クリックや複数タブでも重複送信されない
- 失敗時に再試行判断できるエラーが残る

## 4. 優先順位

高:

- Firebase基盤
- 認証
- 手動送信済み登録
- 送信履歴
- 二重送信防止
- 除外管理
- 成果記録UIは初期運用では非表示

中:

- X API投稿検索
- 候補抽出
- ダッシュボード
- テンプレート管理

低または条件付き:

- X API DM送信
- 高度な検索
- 返信管理
- 複数担当者権限

## 5. 検証コマンド

Flutter:

```bash
flutter analyze
flutter test
flutter build web
```

Cloud Functions:

```bash
npm run lint
npm run build
npm test
```

Firebase:

```bash
firebase emulators:start
firebase deploy --only hosting
firebase deploy --only functions
```

## 6. リリース判定

MVPリリースに必要な最低条件:

- 管理者ログインができる
- 候補を管理できる
- テンプレート本文をコピーできる
- 手動送信済み登録ができる
- 送信履歴が残る
- 除外対象には送信できない
- 必要に応じて成果記録UIを再設計できる
- Firestore Rulesで未ログインアクセスが拒否される

X API DM送信を基本導線とし、失敗時や運用停止時は手動送信フォールバックを使う。

## 7. 未確定事項

- Firebaseプロジェクト名
- GitHub Organization名
- X Developer App作成可否
- API DM送信の採用可否
- 成果報告の締め運用
