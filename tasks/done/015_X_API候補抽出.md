# 015 X API候補抽出

## 現状の動作

X APIから候補を抽出する `syncCandidates` を実装中。

2026-05-14時点:

- Cloud Functions `syncCandidates` 実装済み
- 候補一覧画面から `X API候補抽出` を実行できるUIを追加済み
- Functions build / Flutter analyze / Flutter test 通過
- Firebase Secret `X_BEARER_TOKEN` 設定済み
- `syncCandidates` Functions deploy済み
- Hosting deploy済み

## 期待する動作

指定タグから投稿主を抽出し、候補としてFirestoreへ保存できる。

初期開発の対象は「投稿内容の検索」に限定する。
プロフィール内容の検索は追加開発扱いとし、015では候補データに `sourceTypes = post_search` を保存して、将来 `profile_search` を統合できる下地だけ作る。

## 操作フロー

1. タグ設定を保存
2. 候補一覧画面でタグ検索モードを選択
3. 候補抽出を実行
4. X APIで投稿検索
5. 投稿主ユーザーを取得
6. 除外・既送信・重複判定
7. candidatesへ保存

## UI参考（既存画面）

- `CandidateListPage`

## 技術方針

既送信者と除外対象を再候補化しない。

X API Bearer TokenはFlutterへ渡さず、Cloud Functions側のSecret Manager `X_BEARER_TOKEN` で扱う。

投稿検索とプロフィール検索は検索ロジック、検索条件、レート制限、候補化の意味が異なるため、初期開発では混ぜない。
追加開発では `profileKeywords` などの設定項目を追加し、`sourceTypes = profile_search` として同一候補へupsertする。

タグ検索モードは候補抽出の実行直前に切り替えたい運用項目のため、システム設定画面ではなく候補一覧画面に配置する。
`per_tag` は既存のタグごと検索、`any` はOR検索、`all` はAND検索として `settings/scout.tagSearchMode` に保存する。

## 対象ファイル（推定）

- `functions/src/**`
- `lib/features/candidates/**`
- `docs/DETAIL_cloud_functions_design.md`

## 完了条件

- [x] 指定タグから候補保存できる実装がある
- [x] 除外キーワードが反映される実装がある
- [x] function_logsに実行結果が残る実装がある
- [x] Firebase Secret `X_BEARER_TOKEN` を設定する
- [x] Functionsへdeployする
- [x] 本番Firebaseで候補抽出を1回実行し、Firestore保存を確認する

## レビュー指摘

- 2026-05-14: `syncCandidates` はX Recent Searchで投稿者を抽出し、`candidates/{xUserId}` にupsertする。
- 2026-05-14: 既送信、除外済み、除外キーワード一致を判定する。
- 2026-05-14: `sourceTags`, `sourcePostIds`, `receivesYourDm`, `isProtected`, `isVerified` を保存する。
- 2026-05-14: `function_logs` に実行条件と結果件数を保存する。
- 2026-05-14: `syncCandidates` を本番Functionsへdeploy済み。候補一覧UIをHostingへdeploy済み。
- 2026-05-18: 初期開発では投稿検索のみ対応。プロフィール検索は追加開発扱いとし、`sourceTypes` で将来統合できる下地を追加。
- 2026-05-18: API送信を基本導線、手動送信支援をフォールバック導線として設定文言を変更。成果報酬の入力/表示はクライアント側別計算のため削除。
- 2026-05-18: 成果証跡タブを初期運用のメインナビゲーションから非表示に変更。機能自体は将来の成約記録/成果メモ再設計用に維持。
- 2026-05-18: 候補一覧画面でタグ検索モードを変更できるようにする。タグごと検索、OR検索、AND検索に対応。
- 2026-05-18: 本番アプリ上で候補者がリスト化できることを確認済み。

## 備考

X API検証完了後に着手。
Secret設定前は本番実行できない。
プロフィール検索は追加開発で対応する。
