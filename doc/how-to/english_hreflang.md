

## 普通に日英記事を書けるか

結論から申し上げますと、**はてなブログの標準機能のみで「検索エンジンに言語ごとに自動で使い分けさせる（多言語SEO対応）」を完全自動化することはできません**。

Googleなどの検索エンジンに「この記事の英語版はこちら」と認識させて検索結果で適切に使い分けてもらうには、`rel="alternate" hreflang="..."` というHTMLタグの設定が必要ですが、はてなブログには標準で自動翻訳や言語リダイレクトを行う多言語機能が備わっていないためです。

ただし、**はてなブログPro（有料版）の機能や記述の工夫を組み合わせることで、実質的に日本語版と英語版を分けて検索エンジンに評価させる運用は可能**です。具体的なアプローチを3つご紹介します。

---

## 実現するための3つの方法

### 方法1：別ブログとして英語版を開設し、`hreflang` タグを設定する（推奨）

もっともSEO的に正しく、検索エンジンに「言語違いの同一コンテンツ」として認識させやすい方法です。

* **手順**:
1. 日本語ブログとは別に、英語版用のブログ（例: `○○-en.hatenablog.com`）をもう1つ作成する。
2. 同じ内容の記事を英語で執筆・公開する。
3. **はてなブログPro**を利用し、「設定」>「詳細設定」>「head要素に要素を追加」または各記事の記述で、お互いのページを紐づける `hreflang` タグを記述する。


* **記述例（`<head>` 内に追加するタグ）**:
```html
<link rel="alternate" hreflang="ja" href="https://xxx.hatenablog.com/entry/japanese-post" />
<link rel="alternate" hreflang="en" href="https://xxx-en.hatenablog.com/entry/english-post" />

```



---

### 方法2：同一ブログ内で英語版記事を作成し、相互リンクを貼る

ブログを複数管理するのが大変な場合のシンプルな代替案です。

* **手順**:
1. 同じブログ内で、日本語版（例: `/entry/my-topic-ja`）と英語版（例: `/entry/my-topic-en`）の記事をそれぞれ個別に作成する。
2. 記事の冒頭や末尾に「English version is here」「日本語版はこちら」とお互いへのテキストリンクを分かりやすく設置する。


* **注意点**:
* `hreflang` タグを個別に埋め込まない場合、Googleはそれぞれの独立したページとしてインデックスします。
* 英語で検索するユーザーには英語版ページがヒットしやすくなりますが、地域・言語に応じた自動切り替えの精度は `hreflang` を使う方法より低くなります。



---

### 方法3：1つの記事の中に日本語と英語を併記する（最も手軽）

1つの記事ページ内に「前半：日本語」「後半：英語」をまとめて書く方法です。

* **メリット**: 記事管理が1つで済み、双方の読者にアクセスしてもらえる。
* **デメリット**: ページ内で使われている言語が混ざるため、検索エンジンが「この記事の主要言語はどちらか」を判断しづらくなり、単独言語のページに比べて特定の言語での検索順位が上がりにくくなる可能性があります。

---

## 運用上の注意点・アドバイス

* **機械翻訳のまま載せない**:
自動翻訳しただけの文章をそのまま公開すると、Googleのガイドライン（品質に関するガイドライン）で「低品質な自動生成コンテンツ」とみなされるリスクがあります。自然な英語になるよう手を入れて公開することをおすすめします。
* **URL（カスタムURL）の工夫**:
記事のURLを設定する際は、標準の年月日数字ではなく、カスタムURL（例: `entry/rust-optimization-en`）を利用して英語表記にしておくと、海外ユーザーや検索エンジンにとって分かりやすくなります。


## 


はてなブログで記事ごとに個別URLを指定した `hreflang` タグを `<head>` 内に埋め込む場合、結論から言うと**標準機能だけでは記事ごとの出し分けが難しい**ため、JavaScript（Scriptタグ）を使って動的に `<head>` へ挿入するか、HTML編集で記事本文内に入れる手法をとるのが一般的です。

具体的な設定手順を3パターンご紹介します。

---

## 方法1：JavaScriptで記事ごとに動的に＜head＞へ挿入する（推奨）

はてなブログProの「head要素に要素を追加」機能とJavaScriptを組み合わせることで、特定の記事のときだけ、その記事に対応する日本語・英語それぞれのURLを持つ `hreflang` タグを `<head>` 内へ自動追加できます。

### 設定手順

1. 管理画面の **[設定]** ＞ **[詳細設定]** を開きます。
2. **[head要素に要素を追加]** の入力欄に、以下のコードを記述します。

```html
<script>
(function() {
  // 記事ページのパスと、それに対応する英語版URLのマッピング
  var langMap = {
    "/entry/my-article-ja": "https://en-example.hatenablog.com/entry/my-article-en",
    "/entry/rust-tips-ja": "https://en-example.hatenablog.com/entry/rust-tips-en"
  };

  var currentPath = window.location.pathname;

  if (langMap[currentPath]) {
    var jaUrl = window.location.origin + currentPath;
    var enUrl = langMap[currentPath];

    // 日本語版の link タグ生成
    var linkJa = document.createElement('link');
    linkJa.rel = 'alternate';
    linkJa.hreflang = 'ja';
    linkJa.href = jaUrl;
    document.head.appendChild(linkJa);

    // 英語版の link タグ生成
    var linkEn = document.createElement('link');
    linkEn.rel = 'alternate';
    linkEn.hreflang = 'en';
    linkEn.href = enUrl;
    document.head.appendChild(linkEn);
  }
})();
</script>

```

* **使い方**:
新しい日英対応記事を公開するたびに、`langMap` の部分に `"/日本語記事のパス": "英語版記事のフルURL"` というペアを追加していきます。

---

## 方法2：記事本文のHTML編集モードで記述する

もっともシンプルで、JavaScriptを使わずに記事単位で完結させる方法です。

### 設定手順

1. 記事作成画面で **[HTML編集]** モードにします。
2. 記事本文の一番上の行に、直接 `<link>` タグを記述します。

```html
<link rel="alternate" hreflang="ja" href="https://xxx.hatenablog.com/entry/my-article-ja" />
<link rel="alternate" hreflang="en" href="https://xxx-en.hatenablog.com/entry/my-article-en" />

```

* **ポイント**:
HTML5の仕様上、`<link rel="alternate">` は `<body>` 内に記述されていても有効として扱われます。Googleのクローラーも本文内にある `hreflang` タグを正常に認識・処理します。
* 英語版記事側にも、同様に自分自身（en）と日本語版（ja）の両方を指すタグを本文冒頭に貼っておく必要があります。

---

## 方法3：サイト全体（トップページ等）の共通設定

もし「ブログ全体の言語切り替え（例：トップページ同士の紐づけ）」を行いたい場合は、JavaScriptを使わず直接設定できます。

1. **[設定]** ＞ **[詳細設定]** ＞ **[head要素に要素を追加]** を開く。
2. 以下のように直書きする。

```html
<link rel="alternate" hreflang="ja" href="https://xxx.hatenablog.com/" />
<link rel="alternate" hreflang="en" href="https://xxx-en.hatenablog.com/" />

```

---

## 設定時の注意点

* **相互に設定する**:
日本語ページから英語版へのリンクだけでなく、**英語版ページからも日本語版へ向ける `hreflang` タグを両方に記述**しないと、Google側で対として認識されません。
* **URLの記述**:
`href` に指定するURLは、省略形ではなく `https://...` から始まる**完全な絶対URL**で記述してください。

## 最終形

JavaScriptで `<head>` 内へ `hreflang` タグを動的挿入する場合、「Googlebotが遅延なく・確実に認識できる実装にする」**ことと**「日英双方のブログで相互アノテーションを完成させる」ことの2点が重要です。

これらを完全に満たし、コピペでそのまま使える決定版のスクリプトと設定手順を解説します。

---

## 1. 確実に動作させるための4つの設計ポイント

1. **即時実行（IIFE）で記述する**
`DOMContentLoaded` などのイベントを待たず、スクリプトが読み込まれた瞬間に `<head>` にアタッチします。これにより、クローラーのHTMLパース初期段階で要素を確定させます。
2. **`x-default` を含めた3種類のタグを出力する**
日本語（`ja`）、英語（`en`）、およびフォールバック用（`x-default`）の計3つの `link` タグを出力します。
3. **日本語・英語どちらのブログからアクセスされても動く「両方向マッピング」にする**
記事ペア（日本語URL ⇄ 英語URL）をオブジェクトで定義し、現在のページが「日本語記事」でも「英語記事」でも、自分自身と相手方のURLを自動判定してタグを生成します。
4. **はてなブログのドメイン差異を問わない構造にする**
サブドメイン型（例: `xxx.hatenablog.com` と `xxx-en.hatenablog.com`）でも、独自ドメイン型でも同じスクリプト1つで共通化します。

---

## 2. 設置する共通JavaScriptコード

以下のコードを、**日本語ブログ・英語ブログの両方の管理画面**に同じように設定します。

### 設定場所

はてなブログ管理画面 ＞ **[設定]** ＞ **[詳細設定]** ＞ **[head要素に要素を追加]**

```html
<script>
(function() {
  // ----------------------------------------------------
  // 日英ペア記事の対応表（フルURLで記述）
  // 新しい日英記事を追加したら、ここにペアを追加していきます
  // ----------------------------------------------------
  var pairs = [
    {
      ja: "https://xxx.hatenablog.com/entry/rust-optimization-ja",
      en: "https://xxx-en.hatenablog.com/entry/rust-optimization-en"
    },
    {
      ja: "https://xxx.hatenablog.com/entry/my-article-ja",
      en: "https://xxx-en.hatenablog.com/entry/my-article-en"
    }
  ];

  // 現在のページの完全URL（クエリ文字列やハッシュを除外）
  var currentUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;

  // 現在のURLがペアリストのいずれかに一致するか検索
  var matchedPair = null;
  for (var i = 0; i < pairs.length; i++) {
    if (pairs[i].ja === currentUrl || pairs[i].en === currentUrl) {
      matchedPair = pairs[i];
      break;
    }
  }

  // 一致するペアが見つかった場合のみ hreflang タグを挿入
  if (matchedPair) {
    var head = document.head || document.getElementsByTagName('head')[0];

    // タグ生成用のヘルパー関数
    function createHreflangLink(hreflang, href) {
      var link = document.createElement('link');
      link.setAttribute('rel', 'alternate');
      link.setAttribute('hreflang', hreflang);
      link.setAttribute('href', href);
      return link;
    }

    // 1. 日本語版タグ（hreflang="ja"）
    head.appendChild(createHreflangLink('ja', matchedPair.ja));

    // 2. 英語版タグ（hreflang="en"）
    head.appendChild(createHreflangLink('en', matchedPair.en));

    // 3. デフォルトタグ（hreflang="x-default" はメイン言語の日本語を指定）
    head.appendChild(createHreflangLink('x-default', matchedPair.ja));
  }
})();
</script>

```

---

## 3. 運用・検証の手順

スクリプトを設置した後は、以下のステップで動作を確認してください。

### ① 動作確認（ブラウザのデベロッパーツール）

1. 対応表に登録した記事ページを開きます。
2. キーボードの `F12` キー（Macは `Cmd + Option + I`）を押してデベロッパーツールを開きます。
3. **[Elements]** タブを開き、`<head>` タグを展開します。
4. `<head>` の末尾付近に、以下のような3行の `<link rel="alternate" ...>` が挿入されていることを確認します。

```html
<link rel="alternate" hreflang="ja" href="https://xxx.hatenablog.com/entry/rust-optimization-ja">
<link rel="alternate" hreflang="en" href="https://xxx-en.hatenablog.com/entry/rust-optimization-en">
<link rel="alternate" hreflang="x-default" href="https://xxx.hatenablog.com/entry/rust-optimization-ja">

```

### ② Google Search Consoleでの確認

1. **Google Search Console** にログインします。
2. 該当記事のURLを入力し、「URL 検査」を実行します。
3. 「公開 URL をテスト」をクリックします。
4. テスト完了後、**「テスト済みページを表示」** ＞ **「HTML」** タブを開き、生成されたHTMLの `<head>` 内に上記 `link` タグが含まれているか確認します。

> **補足**: Google Search Consoleの「URL検査」のHTML出力にタグが残っていれば、GooglebotがJavaScript実行（レンダリング）後に `hreflang` を正常に抽出できている証拠となります。
>


