# Xスカウト支援ツール アーキテクチャ設計

**方針: core + features + MVVM（+ Repository / UseCase）**

## 1. 採用方針

- feature単位で分割する
- feature内は MVVM（View / ViewModel / Model）で分離する
- Firebase Authentication、Firestore、Cloud Functions呼び出しは Repository に閉じる
- 候補抽出、送信キュー作成、送信済み登録、成果登録などの業務手順は UseCase に寄せる
- feature横断の共通UI、エラー、Firebase初期化、認証セッション、ユーティリティは core に集約する
- X APIトークンやシークレットはFlutter Web側に保持しない

## 2. 推奨ディレクトリ構造

```text
lib/
  main.dart

  app/
    app.dart
    router/
      app_router.dart
      route_paths.dart
      guards.dart
    di/
      providers.dart
    config/
      env.dart
      constants.dart
    theme/
      app_theme.dart

  core/
    ui/
      widgets/
        app_scaffold.dart
        app_dialog.dart
        app_snackbar.dart
        loading_view.dart
        error_view.dart
        empty_view.dart
      components/
        primary_button.dart
        secondary_button.dart
        form_text_field.dart
      layout/
        responsive.dart
      styles/
        spacing.dart
        typography.dart

    errors/
      app_error.dart
      firebase_error_mapper.dart
      functions_error_mapper.dart
    result/
      result.dart
    logging/
      logger.dart

    utils/
      date_time_utils.dart
      formatters.dart
      validators.dart

    auth/
      auth_service.dart
      session.dart
      role.dart

    firebase/
      firebase_app.dart
      auth_client.dart
      firestore_client.dart
      functions_client.dart

    serialization/
      timestamps.dart
      json_converters.dart

  features/
    auth/
      model/
        app_user.dart
      data/
        auth_repository.dart
        firebase_auth_repository.dart
        user_repository.dart
        firestore_user_repository.dart
      usecase/
        sign_in.dart
        sign_out.dart
        load_session.dart
      vm/
        login_vm.dart
        session_vm.dart
      view/
        pages/
          login_page.dart
        widgets/
          login_form.dart

    dashboard/
      model/
        dashboard_summary.dart
      data/
        dashboard_repository.dart
        firestore_dashboard_repository.dart
      usecase/
        load_dashboard_summary.dart
      vm/
        dashboard_vm.dart
      view/
        pages/
          dashboard_page.dart
        widgets/
          summary_tiles.dart

    candidates/
      model/
        candidate.dart
        candidate_status.dart
      data/
        candidate_repository.dart
        firestore_candidate_repository.dart
        candidate_functions_repository.dart
      usecase/
        load_candidates.dart
        sync_candidates.dart
        exclude_candidate.dart
        restore_candidate.dart
      vm/
        candidate_list_vm.dart
        candidate_detail_vm.dart
      view/
        pages/
          candidate_list_page.dart
          candidate_detail_page.dart
        widgets/
          candidate_table.dart
          candidate_status_badge.dart

    send_queue/
      model/
        send_queue.dart
        send_queue_item.dart
      data/
        send_queue_repository.dart
        firestore_send_queue_repository.dart
        send_queue_functions_repository.dart
      usecase/
        create_send_queue.dart
        send_direct_message.dart
        mark_as_manually_sent.dart
        skip_queue_item.dart
      vm/
        send_queue_vm.dart
      view/
        pages/
          send_queue_page.dart
        widgets/
          queue_progress.dart
          message_preview.dart

    templates/
      model/
        dm_template.dart
      data/
        template_repository.dart
        firestore_template_repository.dart
      usecase/
        load_templates.dart
        save_template.dart
      vm/
        template_list_vm.dart
      view/
        pages/
          template_list_page.dart
        widgets/
          template_editor.dart

    histories/
      model/
        send_history.dart
      data/
        send_history_repository.dart
        firestore_send_history_repository.dart
      usecase/
        load_send_histories.dart
      vm/
        send_history_vm.dart
      view/
        pages/
          send_history_page.dart

    exclusions/
      model/
        excluded_account.dart
        exclusion_keyword.dart
      data/
        exclusion_repository.dart
        firestore_exclusion_repository.dart
      usecase/
        load_excluded_accounts.dart
        save_exclusion_keywords.dart
      vm/
        excluded_account_vm.dart
        exclusion_keyword_vm.dart
      view/
        pages/
          excluded_account_page.dart
          exclusion_keyword_setting_page.dart

    conversions/
      model/
        conversion.dart
      data/
        conversion_repository.dart
        firestore_conversion_repository.dart
        conversion_functions_repository.dart
      usecase/
        create_conversion.dart
        calculate_reward.dart
        load_conversions.dart
      vm/
        conversion_list_vm.dart
        conversion_form_vm.dart
      view/
        pages/
          conversion_list_page.dart
          conversion_form_page.dart

    settings/
      model/
        scout_settings.dart
        tag_setting.dart
      data/
        settings_repository.dart
        firestore_settings_repository.dart
      usecase/
        load_scout_settings.dart
        save_tags.dart
        save_scout_settings.dart
      vm/
        tag_setting_vm.dart
        system_setting_vm.dart
      view/
        pages/
          tag_setting_page.dart
          system_setting_page.dart
```

## 3. レイヤー責務

### 3.1 View

- Page / Widgetを配置する
- 状態を購読して描画する
- Firestore、Cloud Functions、Firebase Authへ直接アクセスしない
- 業務判断を持たない

### 3.2 ViewModel

- 画面状態を保持する
- ユーザー操作を受け取りUseCaseを呼び出す
- loading、error、data、form stateを管理する
- 表示用の軽い整形は許可する

### 3.3 Model

- Entity / ValueObjectを配置する
- Firebase SDKに依存しない
- `DocumentSnapshot`、`Timestamp` などSDK固有型を直接保持しない

### 3.4 Repository

- Firestore、Firebase Auth、Cloud Functions呼び出しを閉じ込める
- Firestoreのパス文字列はRepository内に集約する
- DTOとModelの変換を行う
- ViewModelからFirebase SDKを隠蔽する

### 3.5 UseCase

- 業務手順を固定する
- 候補抽出、送信キュー作成、手動送信済み登録、API送信、成果登録などを扱う
- 複数Repositoryをまたぐ処理の入口にする

## 4. 依存関係ルール

```text
View -> ViewModel -> UseCase -> Repository -> Firebase SDK / Cloud Functions
```

Modelは各レイヤーから参照してよいが、Model自身はFirebase SDKやUIに依存しない。

禁止事項:

- ViewがFirestoreへ直接アクセスする
- ViewがCloud Functionsを直接呼び出す
- RepositoryがViewModelの状態型を参照する
- ModelがFirebase SDK固有型を持つ
- X APIトークンをFlutter Web側に保持する

## 5. Firebase前提の事故防止ルール

- Firestoreパス生成はRepositoryまたはCloud Functions内で統一する
- `send_histories` は送信証跡の正本として扱う
- `excluded_accounts` は除外対象の正本として扱う
- `candidates.status` と `candidates.isExcluded` は表示・検索用スナップショットとして扱う
- DM送信、手動送信済み登録、成果登録はCloud Functions経由を原則とする
- 二重送信防止はUIだけでなくCloud FunctionsとFirestore transactionで担保する
- X API秘密情報はCloud Functions側の設定またはSecret Managerで管理する

## 6. 画面とfeatureの対応

| 画面 | feature |
|---|---|
| ログイン | auth |
| ダッシュボード | dashboard |
| 候補一覧 / 候補詳細 | candidates |
| 送信キュー | send_queue |
| 送信履歴 | histories |
| 除外リスト / 除外キーワード設定 | exclusions |
| テンプレート | templates |
| 成果報告管理 | conversions |
| タグ設定 / システム設定 | settings |

## 7. 状態管理

状態管理はRiverpodを想定する。

- Firestoreのリアルタイム購読: `StreamProvider`
- 単発取得: `FutureProvider`
- 画面操作・フォーム状態: `Notifier` / `AsyncNotifier`
- Repository、UseCase、FirebaseインスタンスDI: `Provider`

## 8. Cloud Functionsとの境界

以下の処理はCloud Functions callableを経由する。

- `syncCandidates`
- `createSendQueue`
- `sendDirectMessage`
- `markAsManuallySent`
- `excludeCandidate`
- `restoreCandidate`
- `createConversion`
- `calculateReward`

Flutter側のRepositoryは、callable関数の呼び出しとレスポンス変換のみを担当する。

## 9. 変更履歴

- 2026-05-11: Xスカウト支援ツール向けにcore + features + MVVM方針を作成
