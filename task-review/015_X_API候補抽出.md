# 015 X API候補抽出レビュー

## 2026-05-14 実装メモ

実装内容:

- `functions/src/index.ts` に `syncCandidates` を追加
- X Recent Search APIで設定タグごとに投稿検索
- `includes.users[]` から投稿者を候補化
- `candidates/{xUserId}` へupsert
- `excluded_accounts/{xUserId}` と `send_histories.xUserId` を参照して再候補化を防止
- `settings/scout.exclusionKeywords` に一致する候補は除外保存
- `function_logs` に実行結果を保存
- 候補一覧画面に `X API候補抽出` ボタンを追加

保存する主な項目:

- `candidateId`
- `xUserId`
- `username`
- `displayName`
- `profileText`
- `profileUrl`
- `sourceTags`
- `sourcePostIds`
- `sourceTypes`
- `receivesYourDm`
- `isProtected`
- `isVerified`
- `firstFoundAt`
- `lastFoundAt`
- `lastCheckedAt`

検証:

```text
npm --prefix functions run build: pass
flutter analyze: pass
flutter test: pass
```

完了:

- Firebase Secret Managerへ `X_BEARER_TOKEN` を設定
- Functions deploy
- Hosting deploy

未完了:

- 本番Firebaseで候補抽出を実行
- Firestore `candidates` と `function_logs` の保存確認

運用注意:

- X APIクレジットを消費する
- `searchMaxResults` と `searchMaxPages` は上限を抑える
- DMの視認性が低い可能性があるため、候補抽出時点では `receivesYourDm` は補助情報として扱う

## 2026-05-18 プロフィール検索の扱い

方針:

- 初期開発ではプロフィール検索は実装しない
- 015は投稿内容検索による候補抽出に限定する
- プロフィール検索は追加開発扱いにする

下地:

- 候補に `sourceTypes` を保存する
- 投稿検索由来は `post_search`
- 追加開発でプロフィール検索由来は `profile_search` として同じ候補へ統合する

追加開発で必要な想定:

- `settings/scout.profileKeywords`
- プロフィール検索用Functionまたは `syncCandidates` のmode拡張
- 投稿検索/プロフィール検索のUI切り替え
- `function_logs` で検索種別ごとの実行結果記録

## 2026-05-18 送信設定と成果報酬欄の見直し

ユーザー指摘:

- API DM送信は基本API経由で行う方針にする
- 手動送信支援はフォールバックとして残す
- 成果報酬の欄は不要。成果報酬はクライアント側で別途計算する

対応:

- システム設定の表示名を `API送信を有効にする` / `手動送信フォールバックを有効にする` に変更
- システム設定画面から標準成果報酬率の入力欄を削除
- 成果登録画面から報酬率/報酬額の入力・表示を削除
- `createConversion` は対象売上と証跡を保存し、報酬率/報酬額は保存しない方針に変更
- 既存データ互換のため、旧 `rewardRate` / `rewardAmount` フィールドはモデル上は任意で読める状態を維持

## 2026-05-18 成果証跡タブの扱い

ユーザー指摘:

- 成果報酬を別途クライアント側で計算するなら、成果証跡タブも不要ではないか

対応:

- `conversions` のコードとルートは削除せず維持
- Drawerのメインナビゲーションから `成果証跡` を非表示
- 020は `成果記録UIの再設計判断` として扱い、必要になった場合のみ成約記録/成果メモとして再設計する

## 2026-05-18 タグ検索モード

ユーザー指摘:

- タグ検索はAND検索/OR検索を選べると利便性が高い
- 設定画面へ移動せず、候補一覧画面で変更できた方がよい

対応方針:

- `settings/scout.tagSearchMode` を追加する
- デフォルトは既存挙動の `per_tag`
- 候補一覧画面で `タグごとに検索` / `いずれかを含む（OR）` / `すべて含む（AND）` を選択して保存する
- `syncCandidates` は保存された検索モードに応じてX Recent Searchのqueryを組み立てる
