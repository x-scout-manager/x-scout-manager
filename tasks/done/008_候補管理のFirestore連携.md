# 008 候補管理のFirestore連携

## 現状の動作

候補一覧・詳細はFirestoreの `candidates` と連携済み。

## 期待する動作

Firestoreの `candidates` を一覧・詳細表示できる。

## 操作フロー

1. 候補一覧を開く
2. 候補が表示される
3. 候補詳細を開く
4. ステータスや送信可否を確認する

## UI参考（既存画面）

- `CandidateListPage`
- `CandidateDetailPage`

## 技術方針

候補抽出API実装前でも、手動/ダミーデータで表示確認できるようにする。

## 対象ファイル（推定）

- `lib/features/candidates/**`
- `lib/features/histories/**`
- `lib/app/router/**`

## 完了条件

- 候補一覧がFirestoreから表示される
- 詳細画面に遷移できる
- empty/loading/error状態がある

## 実施済み

- [x] `Candidate` のFirestore変換と送信可否判定を実装
- [x] `CandidateStatus` の文字列変換と表示ラベルを実装
- [x] `FirestoreCandidateRepository` で `candidates` の一覧監視・詳細取得を実装
- [x] `CandidateListVm` でloading/error/emptyを扱う一覧状態を実装
- [x] `CandidateDetailVm` で詳細取得状態を実装
- [x] 候補一覧をFirestoreデータで表示
- [x] 候補一覧から詳細画面へ遷移
- [x] 候補詳細でステータス、タグ、送信可否、プロフィールを表示
- [x] `flutter analyze` 成功
- [x] `flutter test` 成功
- [x] `flutter build web` 成功
- [x] Firebase Hosting deploy成功

## レビュー指摘

未記入。

## 備考

X API候補抽出は後続タスク。
