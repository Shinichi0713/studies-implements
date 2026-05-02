## 開発環境

Swift Toolchain

## 簡単なコードを書いて実行する流れ

### 方法A: VS Codeでプロジェクトを作成して実行

1. VS Codeを開き、コマンドパレット（`Ctrl+Shift+P`）から `Swift: Create New Project...` を実行します[Visual Studio Code Docs](https://code.visualstudio.com/docs/languages/swift)。
2. テンプレート（例: executable）、保存先フォルダ、プロジェクト名を指定します。
3. `Sources/` ディレクトリ内の `.swift` ファイルにコードを書きます。

   ```swift
   print("Hello, Swift on Windows!")
   ```
4. ビルド：`Ctrl+Shift+B` でビルドタスクを実行します。
5. 実行・デバッグ：サイドバーの「実行とデバッグ」ビューから起動構成を選び、緑の再生ボタンで実行します[Visual Studio Code Docs](https://code.visualstudio.com/docs/languages/swift)。

### 方法B: ターミナルで直接実行

1. テキストエディタで `hello.swift` を作成し、次のコードを書きます。

   ```swift
   print("Hello, Swift on Windows!")
   ```
2. PowerShellやコマンドプロンプトで、そのディレクトリに移動し、次のコマンドを実行します。

   ```bash
   swift hello.swift
   ```

   または、実行ファイルにコンパイルしてから実行することもできます。

   ```bash
   swiftc hello.swift
   .\hello.exe
   ```


## 5. 注意点

- Swift on Windowsは、**iOSやmacOSアプリの開発には使えません**。あくまでWindowsネイティブの実行ファイルやサーバーサイド用途などが主な対象です[Swift.org](https://swift.org/install/windows/)。
- Swift 6.1未満のバージョンでは、VS Codeの言語機能（補完など）を有効にするために、プロジェクトで一度 `swift build` を実行してインデックスを作成する必要があります[Visual Studio Code Docs](https://code.visualstudio.com/docs/languages/swift)。


# 実行手順

WindowsにSwift Toolchainをインストール済みであれば、VSCodeでSwiftコードを開発・コンパイルするのは比較的簡単です。  
公式ドキュメントを参考に、Windows向けの手順を整理します[Swift.org - Configuring VS Code for Swift Development](https://swift.org/documentation/articles/getting-started-with-vscode-swift.html)。

---

## 1. 前提：WindowsにSwift Toolchainが入っていること

- Swift.orgの「Getting Started」ページから、**Windows用のSwift Toolchain**をダウンロード・インストールしておきます[Swift.org - Getting Started](https://swift.org/getting-started/)。  
- インストール後、コマンドプロンプトやPowerShellで `swift --version` が動くことを確認してください。

---

## 2. VSCodeのインストールとSwift拡張の追加

1. **Visual Studio Code** をインストールします（まだ入っていない場合）。  
   - https://code.visualstudio.com/

2. VSCodeを起動し、**Swift拡張機能**をインストールします。  
   - 左の拡張機能アイコン（四角が4つ）をクリック  
   - 検索欄に `Swift` と入力  
   - 「Swift」拡張（ID: `swiftlang.swift-vscode`）をインストール[Swift - Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=swiftlang.swift-vscode)。

3. 拡張機能の**オンボーディング**を実行（推奨）  
   - `Ctrl+Shift+P` でコマンドパレットを開く  
   - `Welcome: Open Welcome Walkthrough` を選択  
   - 「Getting started with Swift」を選んで、簡単なチュートリアルを進めます。

---

## 3. Swiftプロジェクト（パッケージ）の作成

VSCodeのSwift拡張は、**Swift Package Manager（SPM）プロジェクト**を前提にした機能が多いです。  
まずは簡単なパッケージを作成しましょう。

1. 作業用フォルダを開く  
   - VSCodeで `ファイル` → `フォルダーを開く` から、新規フォルダ（例: `swift-test`）を開きます。

2. ターミナルでSwiftパッケージを作成  
   - `Ctrl+Shift+`` でターミナルを開く  
   - 以下を実行して、実行可能なSwiftパッケージを作成します。

   ```bash
   swift package init --type executable
   ```

   これで、以下のような構造ができます。

   ```
   swift-test/
   ├── Package.swift
   ├── Sources/
   │   └── swift-test/
   │       └── main.swift
   └── Tests/
   ```

3. `main.swift` を編集  
   - `Sources/swift-test/main.swift` を開き、例えば以下のように書いてみます。

   ```swift
   import Foundation

   print("Hello from Swift on Windows!")
   let name = "VSCode"
   print("こんにちは、\(name)！")
   ```

---

## 4. VSCodeでのビルド・実行

### 方法A：ターミナルから `swift run` を使う（シンプル）

1. VSCodeのターミナルで、プロジェクトのルートディレクトリにいることを確認  
2. 以下を実行

   ```bash
   swift run
   ```

   - `swift build` でビルドだけ、`swift run` でビルド＋実行ができます。

### 方法B：VSCodeのタスク／ランチャーを使う

Swift拡張は、プロジェクトを開くと自動的にタスクやデバッグ設定を生成してくれます。

1. `Ctrl+Shift+P` → `Tasks: Run Task` → `swift: build` を選択してビルド  
2. `Ctrl+Shift+P` → `Debug: Start Debugging`（またはF5）でデバッグ実行  
   - 初回は `.vscode/launch.json` が自動生成され、`swift run` 相当の設定が作られます。

---

## 5. ツールチェーンの確認（必要に応じて）

- Swift拡張は、**インストール済みのSwift Toolchainを自動検出**します。  
- 複数のSwiftツールチェーンがある場合は、`Ctrl+Shift+P` → `Swift: Select Toolchain...` で切り替えられます[Swift.org - Configuring VS Code for Swift Development](https://swift.org/documentation/articles/getting-started-with-vscode-swift.html)。

---

## 6. デバッグ設定（任意）

デバッグを行う場合は、以下の設定を確認します。

1. `.vscode/launch.json` が自動生成されていることを確認  
2. 必要に応じて、`program` や `args` を変更  
   - 例: コマンドライン引数を渡したい場合など。

---

## 7. よくあるトラブルと解決策

- **Swift拡張がツールチェーンを認識しない**  
  - `Swift: Select Toolchain...` で明示的に選択  
  - SwiftのインストールパスがPATHに正しく設定されているか確認（`swift --version` がターミナルで動くか）。

- **ビルドエラーが出る**  
  - プロジェクトがSPM形式になっているか確認（`Package.swift` があるか）  
  - Windows用Swift Toolchainのバージョンと、コードで使っている機能が合っているか確認。

---

## まとめ

1. WindowsにSwift Toolchainをインストール済み  
2. VSCodeにSwift拡張をインストール  
3. `swift package init --type executable` でプロジェクト作成  
4. `swift run` またはVSCodeのタスク／デバッグでビルド・実行  

これで、Windows上のVSCodeでSwiftコードを開発・コンパイルできます。  
もし実際に試してみてエラーが出る場合は、エラーメッセージを貼ってもらえれば、もう少し具体的に解決方法を案内できます。


# ビルドエラー

このエラーは、**Windows SDK や Visual Studio Build Tools が正しくインストールされていない**、あるいは**パスが通っていない**ことが原因です。

Windows版Swiftは、内部的に `clang-cl` や `lld-link` を使い、Cランタイムライブラリ（`msvcrt.lib` など）にリンクします。  
そのため、**Visual Studio Build Tools** と **Windows SDK** が必要になります[LLVM Discussion - clang-cl on Windows without MSVC](https://discourse.llvm.org/t/clang-cl-on-microsoft-windows-without-msvc/86650)。

---

## 解決手順

### 1. Visual Studio Build Tools と Windows SDK をインストール

1. **Visual Studio Build Tools のインストーラ**をダウンロード  
   - https://visualstudio.microsoft.com/ja/downloads/ から  
   - 「Build Tools for Visual Studio 2022」などをダウンロードします。

2. インストーラを起動し、**ワークロードを選択**  
   - 「C++ によるデスクトップ開発」または「C++ Build Tools」を選択  
   - これにより、Windows SDK や必要なライブラリが一緒にインストールされます。

3. インストールが完了したら、**PCを再起動**  
   - パスや環境変数が正しく設定されるようにするためです。

---

### 2. 環境変数とパスの確認

インストール後もエラーが出る場合は、**環境変数 `LIB` や `PATH` が正しく設定されていない**可能性があります。

1. **Visual Studio Developer Command Prompt** を使う  
   - スタートメニューから「Developer Command Prompt for VS 2022」などを開きます。  
   - その中で `swift build` を実行してみてください。  
   - このコマンドプロンプトは、自動的に `LIB` や `INCLUDE` を設定してくれるため、エラーが解消されることが多いです。

2. 通常のコマンドプロンプトやPowerShellを使いたい場合は、**環境変数を手動で設定**  
   - `LIB` 環境変数に、以下のようなパスが含まれているか確認します（例: Visual Studio 2022）。

   ```text
   C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.xx.xxxxx\lib\x64
   C:\Program Files (x86)\Windows Kits\10\Lib\10.0.xxxxx.0\um\x64
   C:\Program Files (x86)\Windows Kits\10\Lib\10.0.xxxxx.0\ucrt\x64
   ```

   - `PATH` にも、VCの `bin` ディレクトリなどが含まれているか確認します。

3. Swift Toolchain のパスも `PATH` に追加されているか確認  
   - Swift Toolchain のインストール先（例: `C:\Library\Developer\Toolchains\unknown-Asserts-development.xctoolchain\usr\bin`）が `PATH` に含まれているか確認してください。

---

### 3. ビルドコマンドの確認

- `swift build -v` を実行すると、実際にどのコマンドが実行されているか詳細が表示されます。  
- そこに `-L` や `-l` オプション、リンカーの引数が表示されるので、どのライブラリが見つからないか確認できます。

---

## まとめ

- エラー `could not open 'msvcrt.lib'` は、**Windows SDK や Visual Studio Build Tools が不足している**ことが原因です。  
- Visual Studio Build Tools（C++ Build Tools）と Windows SDK をインストールし、  
  - Visual Studio Developer Command Prompt を使う  
  - もしくは `LIB` / `PATH` を正しく設定する  
  ことで、多くの場合は解決します。

もし上記を試してもエラーが続く場合は、  
- `swift build -v` の出力  
- インストールした Visual Studio / Build Tools のバージョン  
- Windowsのバージョン  

