
LLM関係で最近衝撃を与え続けているAI cook "Anthropic"社が発表した論文で「Tracing the thoughts of a large language model」について調べてみました。

## 概要
AnthropicのTracing the thoughts of a large language modelは、**LLM内部の“思考プロセス”を回路（circuit）として可視化する**研究です。  
関連する2本の論文（方法論＋生物学的解釈）から構成されており、**「LLMはどうやって答えを出しているのか？」** をかなり具体的に明らかにしています。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)


### 1. 研究の目的：LLMの「思考」を解剖する

- 従来の解釈可能性（interpretability）研究は、  
  - 個々のニューロンが何を表しているか  
  - 特定の特徴量（feature）がどこで活性化するか  
  といった**局所的な分析**が中心でした。
- この研究は、**「特徴量同士がどうつながり、情報がどう流れるか」** を“回路”としてマッピングし、  
  **LLM内部の計算グラフ（computational graph）を可視化する**ことを目指しています。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

### 2. 手法：Circuit tracing（回路トレース）

__2本の論文で構成__
1. **Circuit tracing: Revealing computational graphs in language models**（方法論）  
2. **On the biology of a large language model**（生物学的解釈・応用）

__手法のポイント__
- 既存の「特徴量マッピング」を拡張し、  
  - 特徴量同士を結びつける  
  - 入力から出力までの**情報の流れを“回路”として再構成**する  
  という手法（attribution graphs）を提案しています。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)
- これにより、**「どの特徴量が、どの層を経て、どの出力に寄与したか」** をグラフとして追跡できます。

### 3. 主な発見：Claudeの内部で何が起きているか
発見内容自体は結構インパクトがあります。
Anthropicは、自社モデルClaudeに対してこの手法を適用し、次のような発見を報告しています。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

__① 多言語間の共通概念空間__
- Claudeは、**異なる言語（英語・フランス語など）で同じ概念を表現する際、内部では共通の“概念空間”を使っている**ことが確認されました。
- つまり、「dog」と「chien」は別の単語ですが、**内部の特徴量レベルでは同じ回路を共有している**ことが示されています。

__② 詩作における“先読み”計画__
- 詩を作るタスクで、Claudeは**数単語先の韻を計画する**ような回路を持っていることが観測されました。
- 単に「次の単語を予測」しているのではなく、**長いスパンで構造を計画している**ことが回路トレースで証明されています。

__③ 計算タスクでの並列経路__
- 計算問題（例：暗算）では、  
  - **近似計算用の経路**  
  - **精密計算用の経路**  
  が並列に存在し、状況に応じて使い分けていることが示されました。
- 興味深いことに、**モデルが口頭で説明する戦略と、内部で実際に使っている経路が異なる**ケースもあり、「後付けの説明」と「実際の計算」の乖離も観測されています。

__④ 忠実な推論 vs “もっともらしい嘘”__
- 回路トレースにより、  
  - **忠実に推論しているときの情報の流れ**  
  - **“もっともらしい嘘”（bullshitting）をしているときの情報の流れ**  
  を区別できる可能性が示されました。
- これにより、「モデルが本当に考えているのか、それとも“それっぽい説明”をでっち上げているのか」を**内部から監査**できるようになります。

__⑤ 幻覚（hallucination）と拒否のメカニズム__
- Claude内部では、**「答えない」がデフォルト状態**であり、  
  「既知の実体（known-entity）」に関する特徴量が活性化することで、**回答を許可する**仕組みがあることが示されました。
- 幻覚（hallucination）は、この**“既知実体”の判定が誤作動した結果**として説明されています。

__⑥ 安全ガードレールと文法的一貫性の衝突__
- 危険なプロンプト（jailbreak）に対して、  
  - **安全ガードレールを守ろうとする回路**  
  - **文法的に一貫した文章を生成しようとする回路**  
  が衝突している様子が観測されました。
- これにより、**安全性と一貫性のトレードオフ**が内部でどう処理されているかが可視化されています。

### 4. なぜこの研究が重要か

__① 「LLMは本当に考えているのか？」への回答__
- これまで「LLMは単に統計的パターンマッチングをしているだけ」という批判がありましたが、  
  この研究は、**内部で計画・並列計算・概念共有といった“思考らしいプロセス”が実際に起きている**ことを示しています。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

__② AI安全性・アライメントへの応用__
- 「忠実な推論」と「もっともらしい嘘」を区別できるようになれば、  
  - モデルが**本当に理解しているか**を監査できる  
  - 安全性評価（red teaming）の精度が上がる  
  など、**AIアライメント研究**に直接役立ちます。

__③ モデル設計へのフィードバック__
- どの回路が有用で、どの回路が危険かがわかれば、  
  - 有用な回路を強化する  
  - 危険な回路を抑制する  
  といった**モデル設計の指針**が得られます。



## 回路トレースアルゴリズム

Anthropicの回路トレースは、**「どの特徴量が、どの層を経て、どの出力に寄与したか」をグラフとして再構成する**手法です。  
公式の方法論論文と解説ページに基づき、アルゴリズムの流れを簡潔にまとめます。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

![1775901980807](image/Tracingthethoughtsofalargelanguagemodel/1775901980807.png)

### 1. 前提：LLM内部の「特徴量」と「回路」

- LLM（Transformer）内部には、各層・各トークン位置で**多数のニューロン（あるいは特徴量）** が活性化しています。
- 従来の解釈可能性研究では、  
  - 「このニューロンは“猫”を表している」  
  - 「この特徴量は“否定”を表している」  
  といった**個々の特徴量の意味**を調べるのが主流でした。
- 回路トレースは、**特徴量同士の接続関係**に注目し、  
  「入力 → 特徴量A → 特徴量B → … → 出力」という**情報の流れ（回路）** を再構築します。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

### 2. アルゴリズムの全体像（3ステップ）

大まかには次の3ステップで回路を構築します。

1. **特徴量の同定（Feature identification）**  
2. **寄与度の計算（Attribution calculation）**  
3. **回路の構築（Circuit construction）**

### 3. ステップ1：特徴量の同定

__目的__
- LLM内部で「意味のある単位」として働いている**特徴量（feature）** を特定します。

__手法（概要）__
- 既存の「辞書学習（dictionary learning）」や「スパースコーディング」に近い手法を使い、  
  - 多数のニューロン活性化パターンから  
  - **スパースな基底ベクトル（特徴量）**を抽出します。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)
- これにより、「猫」「否定」「数値」など、**人間が解釈しやすい概念に対応する特徴量**を特定します。

### 4. ステップ2：寄与度の計算（Attribution）

__目的__
- 「ある特徴量が、特定の出力（単語・トークン）にどれだけ寄与したか」を数値化します。

__手法（概要）__
- 入力トークン列 $x$ に対して、モデルが出力トークン $y$ を生成する過程で、  
  - 各特徴量 $f_i$ が**どれだけ活性化したか**  
  - その活性化が**出力 $y$ にどれだけ影響したか**  
  を計算します。
- 具体的には、**勾配ベースの寄与度計算**（例：integrated gradients, activation × gradient など）を用い、  
  - 「特徴量 $f_i$ が出力 $y$ に与えた寄与度 $a_{i \to y}$」  
  を推定します。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

### 5. ステップ3：回路の構築（Circuit construction）

__目的__
- 寄与度の高い特徴量同士を結びつけ、**「入力 → 特徴量 → 出力」の経路（回路）** をグラフとして構築します。

__手法（概要）__
1. **ノードの定義**  
   - 各特徴量 $f_i$ をノードとします。  
   - 入力トークンや出力トークンもノードとして含めます。

2. **エッジの重み付け**  
   - 特徴量 $f_i$ から特徴量 $f_j$ への寄与度 $a_{i \to j}$ を計算し、  
     - 寄与度が閾値以上のものを**有向エッジ**として追加します。  
   - 同様に、入力トークンから特徴量、特徴量から出力トークンへのエッジも追加します。

3. **回路の抽出**  
   - 特定の出力トークン $y$ に対して、  
     - 寄与度の高いノードとエッジだけを残し、**サブグラフ（回路）** を抽出します。  
   - これが「Circuit tracing」で得られる**attribution graph**です。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

### 6. 具体的な例：詩作タスクでの回路

- 入力：「Write a poem about the moon」  
- 出力：「The moon shines bright / In the dark of night ...」

回路トレースでは、例えば次のような経路が可視化されます。

- 入力トークン「moon」 → 特徴量「天体・夜」 → 特徴量「韻（-ight）」 → 出力トークン「bright」「night」  
- ここで、「数単語先の韻を計画する」ような**長距離の接続**が観測され、  
  「単なる次トークン予測ではなく、構造的な計画がある」ことが示されます。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

### 7. 技術的な工夫（簡潔に）

- **スケーラビリティ**：全ノード・全エッジを計算すると計算量が膨大になるため、  
  - 寄与度の高い特徴量に絞る  
  - 層ごとにサンプリングする  
  などの工夫で現実的な計算量に抑えています。
- **解釈性**：特徴量を人間が理解しやすい概念（例：「猫」「否定」「数値」）に対応づけることで、  
  回路を**“読める形”**にしています。


### 8. 回路トレースのアルゴリズム

1. **特徴量の同定**：LLM内部の活性化パターンから、意味のある特徴量を抽出。  
2. **寄与度の計算**：各特徴量が出力にどれだけ寄与したかを勾配ベースで推定。  
3. **回路の構築**：寄与度の高い特徴量同士を結び、入力→特徴量→出力の経路をグラフ化。

これにより、**「LLMがどう考えて答えを出したか」を、内部の計算経路として可視化**できます。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)


## 総括

- Anthropicの「Tracing the thoughts of a large language model」は、  
  **LLM内部の情報の流れを“回路”として可視化する**画期的な解釈可能性手法です。
- Claudeを対象にした実験から、  
  - 多言語間の共通概念空間  
  - 詩作における先読み計画  
  - 計算の並列経路  
  - 忠実な推論 vs もっともらしい嘘の区別  
  - 幻覚・拒否・安全ガードレールのメカニズム  
  など、**LLMの“思考”の実態**が具体的に明らかになりました。[Anthropic Research](https://www.anthropic.com/research/tracing-thoughts-language-model)

この研究は、「LLMをブラックボックスとして扱う」時代から、  
**「内部の計算プロセスを可視化し、安全性・信頼性を担保する」** 時代への転換点として、非常に重要な位置づけにあります。

