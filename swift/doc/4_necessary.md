**アクセストークンやAPIキーは不要です。**

Screen Time APIは、**外部サービスに問い合わせるREST APIではなく、iOS/macOSのネイティブフレームワーク**だからです。

---

## 1. Screen Time APIで必要なもの

### (1) Apple Developerアカウントとプロビジョニング

- Apple Developer Programに登録し、アプリのBundle IDを登録
- Capabilityとして **Family Controls** を追加
- `Info.plist` に `NSUserTrackingUsageDescription` を追加（認可ダイアログ用）

これらは「**アプリの署名と権限設定**」であり、**APIキーやアクセストークンとは別物**です。

### (2) Family Controlの利用申請

- Appleのフォームから「Family Controlを使いたい」旨を申請し、審査を受ける必要があります[Zenn](https://zenn.dev/flutteruniv_dev/articles/e7d61e5e922631)。
- これは「**このアプリがスクリーンタイムを操作してよいか**」という**Apple側の承認**であり、ユーザーに渡すAPIキーではありません。

### (3) iOS側の認可（ユーザー許可）

- アプリ内で `AuthorizationCenter.shared.requestAuthorization(for: .individual)` を呼ぶと、iOSがユーザーに「このアプリがスクリーンタイムを管理してよいか」を尋ねます。
- ユーザーが許可すると、**iOS内部で暗号化されたトークン**が生成され、アプリはそれを利用して制限をかけます[riedel.wtf](https://riedel.wtf/state-of-the-screen-time-api-2024/)。

このトークンは**外部サービスに送るものではなく、iOS内部でアプリ選択情報を安全に扱うためのもの**です。

---

## 2. なぜAPIキーやアクセストークンが不要なのか

- Screen Time APIは**クラウドサービスではなく、端末内のOS機能**です。
- 制限設定は**端末内のManagedSettingsStore**に保存され、クラウドに送信されるわけではありません[Apple Developer](https://developer.apple.com/jp/videos/play/wwdc2022/110336/)。
- したがって、**外部サービス認証用のAPIキーやアクセストークンは不要**です。

---

## 3. まとめ

- **APIキーやアクセストークンは不要**
- 必要なのは
  - Apple Developerアカウント
  - Family Controlの利用申請（Appleの審査）
  - iOS側のユーザー許可（認可ダイアログ）
- これらは「**アプリがスクリーンタイムを操作する権限を得るための手続き**」であり、外部サービスに問い合わせるための認証情報ではありません。
