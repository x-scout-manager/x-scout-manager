# lib / functions 役割一覧

実装後に、追加・変更したFlutter側ファイルとCloud Functions側ファイルの責務を追記する。

## Flutter

| パス | 役割 |
|---|---|
| `lib/main.dart` | Flutterアプリのエントリポイント。`App` を起動する |
| `lib/app/app.dart` | アプリルート。テーマ、初期ルート、ルート定義を組み込む |
| `lib/app/router/app_router.dart` | Flutter標準 `MaterialApp.routes` ベースの初期ルーティング定義 |
| `lib/app/router/route_paths.dart` | 画面パス定数 |
| `lib/app/router/guards.dart` | 認証・権限ガード用の結果型。実ガードは認証実装時に追加 |
| `lib/app/di/providers.dart` | DI/Provider登録の入口。Riverpod導入時に拡張 |
| `lib/app/config/*.dart` | 環境・アプリ定数 |
| `lib/app/theme/app_theme.dart` | アプリ共通テーマ |
| `lib/core/ui/**` | 共通UI、共通ボタン、ローディング、エラー、空状態、レスポンシブ定義 |
| `lib/core/errors/**` | アプリ共通エラーとFirebase/Functionsエラー変換境界 |
| `lib/core/result/result.dart` | 成功/失敗の結果型 |
| `lib/core/logging/logger.dart` | ログ出力境界 |
| `lib/core/utils/**` | 日付、表示整形、バリデーション |
| `lib/core/auth/**` | ロール、セッション、認証サービス境界 |
| `lib/core/firebase/**` | Firebase初期化とSDKクライアント境界。実SDK依存はFirebase連携時に追加 |
| `lib/core/serialization/**` | Firestore/JSON変換用の共通境界 |
| `lib/features/auth/**` | ログイン、セッション、ユーザー取得のfeature構成 |
| `lib/features/dashboard/**` | 候補数・送信済み数・除外数など概要表示のfeature構成 |
| `lib/features/candidates/**` | 候補一覧、候補詳細、候補抽出、除外/復元のfeature構成 |
| `lib/features/send_queue/**` | 送信キュー作成、個別DM送信、手動送信済み登録、スキップのfeature構成 |
| `lib/features/templates/**` | DMテンプレート一覧・保存のfeature構成 |
| `lib/features/histories/**` | 送信履歴表示のfeature構成 |
| `lib/features/exclusions/**` | 除外アカウント、除外キーワード設定のfeature構成 |
| `lib/features/conversions/**` | 成果登録、成果報酬計算、成果一覧のfeature構成 |
| `lib/features/settings/**` | タグ設定、システム設定のfeature構成 |
| `web/index.html` | Flutter WebのHTMLエントリポイント |
| `web/manifest.json` | Webアプリのマニフェスト |
| `test/widget_test.dart` | 初期画面がダッシュボードとして表示されることを確認するWidgetテスト |
| `pubspec.yaml` | Flutter/Dart依存関係とアセット定義 |
| `analysis_options.yaml` | Dart/Flutter静的解析設定 |

## Cloud Functions

| パス | 役割 |
|---|---|
| `.firebaserc` | Firebase default projectとして `x-scout-manager-prod` を指定 |
| `firebase.json` | Hosting、Firestore、Functions、EmulatorのFirebase設定 |
| `firestore.rules` | Firestore Security Rules。未ログイン拒否、admin参照、重要書き込みFunctions限定 |
| `firestore.indexes.json` | 初期MVPで想定するFirestore複合インデックス |
| `functions/package.json` | Cloud Functions依存関係とbuild/lint/test scripts |
| `functions/tsconfig.json` | Cloud Functions TypeScriptコンパイル設定 |
| `functions/src/index.ts` | Functions entrypoint。`healthCheck` と `adminHealthCheck` の初期関数を定義 |
