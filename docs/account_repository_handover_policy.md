# アカウント・リポジトリ・Firebase移管方針

## 1. 基本方針

本プロジェクトでは、納品後にクライアントが継続運用できるように、Google、Firebase、GitHub、X Developer関連の資産は、原則としてクライアント所有または案件専用アカウントで作成する。

開発者個人のGoogleアカウント、GitHubアカウント、X Developer App、Firebaseプロジェクトを本番運用の所有者にしない。

## 2. 納品先所有アカウントがある場合

クライアントが既に管理しているGoogleアカウント、Google Workspace、GitHub Organization、Xアカウントがある場合は、それらを利用する。

推奨構成は以下とする。

| 区分 | 所有者 | 開発者の関与 |
|---|---|---|
| Google / Firebase / GCP | クライアント | IAM権限で招待 |
| GitHub Organization | クライアント | リポジトリ権限で招待 |
| X Developer App | クライアント | 必要に応じて開発権限で参加 |
| Billing | クライアント | 原則として関与しない |

開発者は、必要な期間のみ権限付与を受けて作業し、納品後または保守終了後に不要な権限を削除する。

## 3. 納品先所有アカウントがない場合

クライアントが利用可能な所有アカウントを持っていない場合は、案件専用の新規アカウントを作成する。

この場合も、開発者個人の既存アカウントとは分離する。

例:

```text
Google: project-name.owner@gmail.com
GitHub Organization: project-name
Firebase Project: project-name-prod
X Developer App: project-name
```

案件専用アカウントは、納品時にクライアントへ管理権限を移す前提で作成する。

## 4. Google / Firebase / GCP

FirebaseプロジェクトおよびGoogle Cloudプロジェクトは、クライアント所有または案件専用Googleアカウントで作成する。

方針:

- Firebase Projectは本番環境用として作成する
- Google Cloud Billingはクライアント名義またはクライアント管理の支払い方法に紐づける
- 開発者は必要なIAMロールで招待される
- X APIトークン、シークレット、Firebase Functions config、Secret Managerの値はクライアント所有プロジェクト内で管理する
- Flutter Web側、Gitリポジトリ、公開Hostingファイルに秘密情報を保存しない

納品時に確認する項目:

- Firebase Consoleへクライアントがログインできる
- Google Cloud Consoleへクライアントがログインできる
- Billingの管理者がクライアント側になっている
- 開発者個人アカウントがOwnerのまま残っていない
- Secret ManagerやFunctions環境変数の保管場所が明確になっている

## 5. GitHub

GitHubは、個人リポジトリではなく、案件専用またはクライアント所有のGitHub Organization配下にリポジトリを作成する。

方針:

- リポジトリはGitHub Organization配下に作成する
- クライアントをOrganization Ownerにする
- 開発者はAdmin、Maintainer、Writeなど必要最小限の権限で参加する
- 納品後または保守終了後に不要な開発者権限を削除する
- GitHub Actions、Secrets、Deploy Keys、Firebase連携設定もOrganizationまたはRepository側で管理する

避ける構成:

- 開発者個人GitHubアカウント配下のリポジトリで本番運用する
- 納品直前にリポジトリ移管する前提で進める
- SecretsやAPIキーをコードにコミットする

## 6. X Developer / X API

X APIを利用する場合、X Developer Appはクライアント所有または案件専用のXアカウントで作成する。

方針:

- 開発者個人のX Developer Appを本番用に使わない
- X APIの課金、審査、制限、凍結リスクはクライアント所有アカウント側で管理する
- OAuth Client ID、Client Secret、Access Token、Refresh Token等はCloud Functions側で管理する
- Flutter Web側にX API秘密情報を保持しない

## 7. 認証情報と2FA

パスワード共有は原則として避ける。

やむを得ず案件専用アカウントを作成して納品する場合は、納品時に以下をクライアント管理へ変更する。

- パスワード
- 2段階認証
- 復旧メールアドレス
- 復旧電話番号
- 請求先情報
- 所有者メールアドレス

開発期間中の認証情報共有が必要な場合は、1Password等の共有Vaultを利用し、チャットやメール本文に平文で送らない。

## 8. 納品時チェックリスト

- [ ] クライアントがGoogleアカウントへログインできる
- [ ] クライアントがFirebase Consoleへアクセスできる
- [ ] クライアントがGoogle Cloud Billingを管理できる
- [ ] クライアントがGitHub Organization Ownerである
- [ ] クライアントがGitHub RepositoryへAdmin以上でアクセスできる
- [ ] クライアントがX Developer Portalへアクセスできる
- [ ] 開発者個人アカウントが不要なOwner権限を持っていない
- [ ] APIキー、トークン、シークレットがGitに含まれていない
- [ ] Firebase Hosting、Functions、Firestore、Authenticationの管理者が明確である
- [ ] 納品後の保守時に必要な開発者権限だけが残っている

## 9. 本プロジェクトでの推奨

本プロジェクトでは、契約上アカウントやGitリポジトリごと引き渡す前提があるため、以下を推奨する。

1. クライアント所有アカウントがある場合は、その配下でFirebase、GitHub、X Developer Appを作成する
2. クライアント所有アカウントがない場合は、案件専用アカウントを新規作成する
3. 開発者個人の普段使いアカウントでは本番資産を作成しない
4. 納品時にクライアントがログイン、復旧、請求、権限管理をできる状態にする
