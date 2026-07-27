# 034 iOS PWA安定性とWebレンダラー検証

## 現状の動作

- 本番Flutter WebはFlutter 3.38.5のCanvasKitレンダラーで配信されている。
- iOS Safariで候補一覧を表示した際、「問題が繰り返し起きました」と表示される報告がある。
- Safariタブ、ホーム画面PWA、iOSバージョン、Service Worker、レンダラーの影響が未切り分けである。

## 期待する動作

- 対象iPhoneで候補一覧を継続利用してもWebContentプロセスが終了しない。
- Safariタブとホーム画面PWAの差異が確認される。
- CanvasKit / Skwasm、Service Worker有無、Flutter SDK更新の採否が根拠付きで決定される。

## 操作フロー

1. 対象端末・iOSバージョン・候補件数を記録する。
2. Safariタブとホーム画面PWAで同一操作を行う。
3. CanvasKit版、Skwasm版、Service Workerなし版をステージングで比較する。
4. 起動、スクロール、バックグラウンド復帰、候補抽出中の安定性を確認する。
5. 採用構成を設計・デプロイ手順へ反映する。

## UI参考（既存画面）

- `web/index.html`
- `web/manifest.json`
- `lib/features/candidates/view/pages/candidate_list_page.dart`

## 技術方針

- タスク032・033によるアプリ側負荷削減後に実機比較する。
- 本番へ直接試験構成を適用せず、ステージングまたはFirebase Hosting preview channelを利用する。
- Flutter SDK・FirebaseパッケージのWasm互換性を確認する。
- Service Workerなしビルドは原因切り分け用とし、採用時はオフライン性・更新配信への影響を整理する。

## 対象ファイル（推定）

- `web/index.html`
- `web/manifest.json`
- Flutter Webビルド・デプロイ手順
- `docs/納品引き継ぎ.md`
- 関連設計資料

## 完了条件

- 対象端末とiOSバージョンが記録される。
- Safariタブとホーム画面PWAの比較結果が記録される。
- CanvasKit / Skwasmの比較結果が記録される。
- Service Worker有無の比較結果が記録される。
- 採用構成と理由が設計・運用資料へ反映される。

## レビュー指摘

- PWA表示時に候補一覧で「問題が繰り返し起きました」となる。
- 最初は利用できていたが、最近重くなっている。

## 備考

- iOS WebKit側の既知不具合も候補に含め、アプリ側負荷と分けて判定する。
