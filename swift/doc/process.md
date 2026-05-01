
## 簡単なコードを書いて実行する流れ

### 方法A: VS Codeでプロジェクトを作成して実行

1. VS Codeを開き、コマンドパレット（`Ctrl+Shift+P`）から`Swift: Create New Project...` を実行します[Visual Studio Code Docs](https://code.visualstudio.com/docs/languages/swift)。
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

---

## 5. 注意点

- Swift on Windowsは、**iOSやmacOSアプリの開発には使えません**。あくまでWindowsネイティブの実行ファイルやサーバーサイド用途などが主な対象です[Swift.org](https://swift.org/install/windows/)。
- Swift 6.1未満のバージョンでは、VS Codeの言語機能（補完など）を有効にするために、プロジェクトで一度 `swift build` を実行してインデックスを作成する必要があります[Visual Studio Code Docs](https://code.visualstudio.com/docs/languages/swift)。

