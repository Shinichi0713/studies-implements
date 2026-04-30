Swiftのインストールが確認できたので、あとは**プロジェクトを作ってコードを書いて実行する**だけです。Windowsでは主に以下のような開発スタイルが一般的です。

- **コマンドラインツール（CLI）の開発**
- **サーバーサイド（Vaporなど）の開発**
- **Swiftの学習（文法・アルゴリズム練習）**

ここでは、最もシンプルな「CLIツール開発」の流れを中心に説明します。

---

## 1. プロジェクトの作成（Swift Package Manager）

Swiftには標準で **Swift Package Manager（SPM）** が付属しており、これを使ってプロジェクトを作成・ビルド・実行できます。

### プロジェクト作成

1. 作業用フォルダを作成します（例：`C:\dev\swift-test`）。
2. そのフォルダでPowerShellを開きます。
3. 以下を実行します。

```powershell
swift package init --type executable
```

- `--type executable` を指定すると、実行可能なプログラム（CLIツール）のテンプレートが生成されます。
- 指定しない場合、デフォルトは `library`（ライブラリ）になります。

これで以下のような構成ができます。

```
swift-test/
├── Package.swift          # パッケージの設定ファイル
├── Sources/
│   └── main.swift         # エントリポイント（main関数）
└── Tests/                 # テストコード用ディレクトリ
```

### ビルドと実行

```powershell
swift build
swift run
```

- `swift build`：プロジェクトをビルド（コンパイル）します。
- `swift run`：ビルドして実行します（`swift build && .build/debug/swift-test.exe` 相当）。

`main.swift` を編集してから `swift run` を実行すると、変更が反映されます。

---

## 2. エディタの設定（任意）

### Visual Studio Code を使う場合

1. Visual Studio Code をインストールします（まだなら）。
2. 拡張機能「Swift」をインストールします。
   - これでシンタックスハイライトや簡易的な補完が使えます。
3. 先ほど作成したプロジェクトフォルダ（`C:\dev\swift-test`）をVS Codeで開きます。
4. ターミナル（PowerShell）から `swift build` / `swift run` を実行できます。

---

## 3. 実際にコードを書いてみる

`Sources/main.swift` を開くと、初期状態で以下のようなコードが入っています。

```swift
@main
struct MyApp {
    static func main() {
        print("Hello, world!")
    }
}
```

ここを自由に書き換えて、`swift run` で動作確認できます。

例：標準入力から文字列を受け取って表示する

```swift
@main
struct MyApp {
    static func main() {
        print("何か入力してください:")
        if let input = readLine() {
            print("入力された文字: \(input)")
        } else {
            print("入力がありませんでした")
        }
    }
}
```

---

## 4. テストの実行

SPMではテストも簡単に実行できます。

```powershell
swift test
```

- `Tests/` ディレクトリ以下にテストコードを書いておけば、`swift test` で自動実行されます。

---

## 5. Windowsでの開発の注意点

- **iOS/macOSアプリ開発は現状ほぼ不可**

  - シミュレータや実機デバッグにはXcode（macOS）が必要です。
  - WindowsでSwiftを学び、後からMacに移行する、という流れが現実的です。
- **サーバーサイド開発は可能**

  - Vaporなどのフレームワークを使えば、WindowsでもWeb APIサーバーを構築できます。
  - ただし、本番環境はLinuxが多いため、最終的にはLinux上で動かす前提で開発することが多いです。
- **CLIツール開発はWindowsでも十分実用的**

  - ファイル操作・ネットワーク・JSONパースなど、多くの用途で使えます。

---

## 6. 次のステップの例

- **Swiftの基礎文法を学ぶ**

  - 公式ドキュメントや「The Swift Programming Language」を読みながら、`main.swift` で練習する。
- **CLIツールを作る**

  - 例：特定のフォルダ内のファイル一覧をJSONで出力するツールなど。
- **サーバーサイドに挑戦する**

  - Vapor などのフレームワークを導入し、簡単なWeb APIを作ってみる。

---

## まとめ

1. `swift package init --type executable` でプロジェクトを作成
2. `Sources/main.swift` を編集してコードを書く
3. `swift run` で実行
4. VS Codeなどで編集しながら繰り返す

これでWindows上でもSwiftでの開発を始められます。
「何を作りたいか」（CLIツール／Web API／学習用など）を教えていただければ、その用途に合わせた具体的なプロジェクト例もお伝えできます。
