
## anyRAN

anyRANが実現しようとしていることは、一言で言えば「**無線アクセスネットワーク（RAN）を、専用ハードウェアに縛られない柔軟なソフトウェア定義のネットワークへ変革する**」ことです。

具体的には、以下の4つのことを実現します。

### 1. どんなサーバー・クラウドでもRANが動くようにする

従来の基地局（RAN）は、Nokiaや各ベンダーが提供する専用のハードウェア（purpose-built RAN）上で動作していました。これは性能は高いものの、ベンダーに依存しやすく、柔軟性に欠けていました。

anyRANはこの常識を覆し、**NokiaのRANソフトウェアを「どのベンダーのサーバー」「どのクラウドプラットフォーム」上でも動作させられる**ようにしました。例えばDell、HPE、Red Hatなどのパートナー企業のインフラ上でNokiaのRANソフトウェアが動作します。[Nokia anyRAN](https://www.nokia.com/mobile-networks/ran/anyran/)

これにより、通信事業者は「Nokiaのソフトウェアは使いたいが、サーバーは自社で選びたい」という要望を実現できます。

### 2. 専用RANとCloud RANを混在させる「ハイブリッドRAN」の実現

通信事業者が抱える大きな課題の一つは、既存の専用基地局（purpose-built RAN）を全て一度にクラウド化するのは現実的でない、という点です。

anyRANは、**従来の専用RANと新しいCloud RANを同じネットワーク内で混在させる**ことを可能にします。これを「ハイブリッドRAN」と呼びます。事業者は自社のペースで、一部の基地局から順番にCloud RANへ移行することができます。[Nokia anyRAN](https://www.nokia.com/mobile-networks/ran/anyran/)

### 3. マルチベンダー環境でも性能と機能の一貫性を保つ

Open RANやCloud RANの課題の一つは、「別のベンダーのハードウェアに乗せ替えると性能が落ちる」ことです。

anyRANは、NokiaのCloud RAN SmartNIC（Layer 1加速カード）を活用することで、**専用ハードウェア上のRANと、汎用サーバー上のCloud RANで性能の差をほぼなくす**ことを実現しました。これにより、通信事業者はインフラを選びながらも、ユーザーに提供する通信品質を一定に保てます。[Nokia MWC23 Press Release](https://www.nokia.com/newsroom/nokia-launches-anyran-to-drive-cloudran-partnerships-enabling-flexibility-for-mobile-network-operators-and-enterprises-mwc23/)

### 4. AI-RANへの橋渡し（AIと通信の融合）

anyRANの最終的な目標は、単なるクラウド化だけではありません。それは**AIワークロードとRANワークロードを同一のインフラ上で同時に実行できる「AI-RAN」** への移行です。

NokiaのanyRANソフトウェアはNvidiaのAerial RAN Computer（GPU加速プラットフォーム）上で動作することで、基地局が「通信だけでなく、AI推論も同時に行うコンピューティングノード」へと進化します。例えば、5G通信をしながら、ロボットの制御AIや音声認識AIを同じサーバーで処理できるようになります。[NVIDIA Newsroom](https://nvidianews.nvidia.com/news/nvidia-nokia-and-leading-telecom-operators-turn-networks-into-distributed-intelligence-platforms)


## anyRANとNvidia

anyRANはNokiaが開発したRAN（無線アクセスネットワーク）のソフトウェア・アプローチですが、このanyRANの枠組みの中でNvidiaは以下のような重要な役割を果たしています。

### 1. GPU加速コンピューティングプラットフォーム「Aerial RAN Computer（ARC）」の提供

Nokiaが2023年2月に発表したanyRANは、パートナー企業のクラウドや汎用サーバー上でもNokiaのRANソフトウェアを実行できるアプローチです。このanyRANエコシステムの中で、Nvidiaは**Aerial RAN Computer（ARC）**というGPU加速コンピューティングプラットフォームを提供しました。これにより、NokiaのanyRANソフトウェアはNvidiaのGPU上で高速に動作するようになりました。[Nokia anyRAN](https://www.nokia.com/mobile-networks/ran/anyran/)

### 2. AI-RAN（AIとRANの融合）の実現

anyRANの進化形として、NokiaとNvidiaはAI-RAN（AIと無線アクセスネットワークの融合）を共同で推進しています。NokiaのAI-native anyRANソフトウェアは、**NvidiaのAerial AI-RANプラットフォーム**上に構築されており、これにより2028年までにスペクトル効率が100%以上向上し、既存のスペクトル資産の容量が2倍になる見込みが示されています。[Nokia AI-RAN Platform](https://www.nokia.com/newsroom/nokia-defines-the-next-era-of-radio-with-the-industrys-first-ai-native-ran-platform/)


### 3. CUDA加速によるanyRANソフトウェアの商用化

Nvidiaは、NokiaのanyRANソフトウェアを**NVIDIA CUDAで加速**させる技術を提供しました。2026年10月の発表では、NokiaのCUDA加速anyRANソフトウェアがNvidia Aerial RAN Computer上で動作し、BT・Deutsche Telekom・Elisa・Orangeなどの通信事業者による現場での試験が行われていることが明らかになっています。[NVIDIA Newsroom](https://nvidianews.nvidia.com/news/nvidia-nokia-and-leading-telecom-operators-turn-networks-into-distributed-intelligence-platforms)

### 4. グローバル通信事業者との共同AI-RAN試験

anyRANの枠組みを活用し、Nvidiaは通信事業者とのAI-RAN試験を主導的な役割で支えています。具体的には：

- **T-Mobile**: 世界初のAI-RAN商用ネットワーク通話をNokiaおよびNvidiaと共同で達成
- **Elisa**: 欧州初のAI-RAN現場試験を、Nokia anyRANソフトウェアとNvidia ARCを用いて実施
- **Deutsche Telekom**: AI強化アップリンクチャネル推定の検証を、NokiaおよびNvidiaの商用AI-RANプラットフォームで実施
- **BT・Orange**: Nokia 5GソフトウェアをNvidia ARC上でテストし、AI-RANのスペクトル効率向上とエッジサービスを検証

全世界で約20の通信事業者が、Nokia anyRANソフトウェアとNvidia ARCを組み合わせたAI-RAN協業を公表しています。[NVIDIA Newsroom](https://nvidianews.nvidia.com/news/nvidia-nokia-and-leading-telecom-operators-turn-networks-into-distributed-intelligence-platforms)

### 5. AIモデルとエージェントツールによる自律ネットワーク運用の支援

anyRANの枠組みを超えて、Nvidiaは通信ネットワークの自律運用（Autonomous Network Operations）にも貢献しています。Nvidiaは**Nematronオープンモデル**と**Agent Toolkitソフトウェア**を提供し、NokiaがこれをAutonomous Networks Suiteに統合して、固定網・無線網・コア網・輸送網全体を管理する信頼性の高いエージェントを構築できるようにしました。[NVIDIA Newsroom](https://nvidianews.nvidia.com/news/nvidia-nokia-and-leading-telecom-operators-turn-networks-into-distributed-intelligence-platforms)




