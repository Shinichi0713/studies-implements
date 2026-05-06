大学の研究室で画像処理系の研究室に入った場合、まず研究室で当たり前のように"特徴量"という言葉を聞くことになります。
ですが、大学の講義で画像処理を受けてこなかった場合、"?"となることが多いはずです。

画像処理を行う場合、ほぼ確実に出てくる特徴量という言葉。
特徴量とは一体何なんでしょう？

本日は特徴量の正体について説明します。

## 特徴量

画像処理で扱うことになる特徴量は、おおまかに次の3つに分けられます。

1. **画素値そのもの（輝度・色）**
   - 最も原始的な特徴量で、画像をグレースケールにしたときの「明るさ（輝度）」や、カラー画像のR/G/Bチャンネル値などです。
   - 多くの処理は、この画素値の集合に対してフィルタや統計処理をかけることから始まります。

2. **局所的な形状・エッジ・テクスチャ**
   - **エッジ**：Sobelフィルタ、Cannyエッジ検出などで抽出される「輪郭」や「境界」。
   - **コーナー**：Harrisコーナー、FASTなどで検出される「角」や「特徴点」。
   - **テクスチャ**：LBP（Local Binary Patterns）、Gaborフィルタなどで表される「模様」や「質感」。
   - 物体認識やマッチングでは、こうした局所特徴が非常に重要になります。

3. **統計的・大域的な特徴**
   - **ヒストグラム**：画像全体の明るさや色の分布。
   - **HOG（Histogram of Oriented Gradients）**：局所的な勾配方向の分布をまとめた特徴。
   - **SIFT / SURF / ORB**：スケールや回転に比較的頑健な局所特徴量（最近はディープラーニングに置き換えられつつありますが、基礎として学ぶことが多いです）。

最近はディープラーニング（CNNなど）で「特徴量を自動学習する」ことが主流ですが、その入力として使われるのは結局「画素値」であり、学習された特徴の中身を分解すると、上記のようなエッジ・テクスチャ・形状の組み合わせになっていることが多いです。

まとめると、
- 画像処理の基本は「画素値（輝度・色）」を出発点に、
- そこから「エッジ・コーナー・テクスチャ」などの局所特徴を抽出し、
- 必要に応じて「ヒストグラム」などの統計特徴にまとめる、
という流れで、これらはほぼ必ず扱うことになる特徴量と言えます。


## 実装してイメージ

実際に画像を使って求めてみるとイメージが良くわきます。
以下では、OpenCVとscikit-imageを使って、エッジ・コーナー・テクスチャを求めるPythonコード例を示します。

### 事前準備

```bash
pip install opencv-python scikit-image matplotlib numpy
```

### 1. エッジ（Sobel, Canny）

```python
import cv2
import numpy as np
import matplotlib.pyplot as plt

# 画像読み込み（グレースケール）
img = cv2.imread("input.jpg", cv2.IMREAD_GRAYSCALE)
assert img is not None, "画像が読み込めませんでした"

# Sobelエッジ（x方向・y方向）
sobelx = cv2.Sobel(img, cv2.CV_64F, 1, 0, ksize=3)
sobely = cv2.Sobel(img, cv2.CV_64F, 0, 1, ksize=3)
sobel_mag = np.sqrt(sobelx**2 + sobely**2)  # 勾配の大きさ

# Cannyエッジ
edges_canny = cv2.Canny(img, threshold1=50, threshold2=150)

# 可視化
plt.figure(figsize=(12, 4))
plt.subplot(1, 3, 1)
plt.imshow(img, cmap="gray")
plt.title("Original")
plt.subplot(1, 3, 2)
plt.imshow(sobel_mag, cmap="gray")
plt.title("Sobel magnitude")
plt.subplot(1, 3, 3)
plt.imshow(edges_canny, cmap="gray")
plt.title("Canny edges")
plt.tight_layout()
plt.show()
```

### 2. コーナー（Harris, FAST）

__Harrisコーナー__

```python
import cv2
import numpy as np
import matplotlib.pyplot as plt

img = cv2.imread("input.jpg", cv2.IMREAD_GRAYSCALE)
assert img is not None, "画像が読み込めませんでした"

# Harrisコーナー検出
dst = cv2.cornerHarris(img.astype(np.float32), blockSize=2, ksize=3, k=0.04)
dst = cv2.dilate(dst, None)  # コーナーを強調

# 閾値以上の点をコーナーとしてマーク
img_color = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
img_color[dst > 0.01 * dst.max()] = [0, 0, 255]  # 赤点

plt.imshow(cv2.cvtColor(img_color, cv2.COLOR_BGR2RGB))
plt.title("Harris corners")
plt.axis("off")
plt.show()
```

__FASTコーナー__

```python
import cv2
import matplotlib.pyplot as plt

img = cv2.imread("input.jpg", cv2.IMREAD_GRAYSCALE)
assert img is not None, "画像が読み込めませんでした"

# FAST検出器
fast = cv2.FastFeatureDetector_create(threshold=30)

# キーポイント検出
keypoints = fast.detect(img, None)

# 描画
img_kp = cv2.drawKeypoints(img, keypoints, None, color=(255, 0, 0))

plt.imshow(img_kp, cmap="gray")
plt.title("FAST keypoints")
plt.axis("off")
plt.show()
```

### 3. テクスチャ（LBP, Gabor）

__LBP（Local Binary Patterns）__

```python
import cv2
import numpy as np
from skimage.feature import local_binary_pattern
import matplotlib.pyplot as plt

img = cv2.imread("input.jpg", cv2.IMREAD_GRAYSCALE)
assert img is not None, "画像が読み込めませんでした"

# LBPパラメータ
radius = 1
n_points = 8 * radius

# LBP画像を計算
lbp = local_binary_pattern(img, n_points, radius, method="uniform")

# 可視化
plt.figure(figsize=(10, 4))
plt.subplot(1, 2, 1)
plt.imshow(img, cmap="gray")
plt.title("Original")
plt.subplot(1, 2, 2)
plt.imshow(lbp, cmap="gray")
plt.title("LBP image")
plt.tight_layout()
plt.show()
```

__Gaborフィルタ__

```python
import cv2
import numpy as np
from skimage.filters import gabor
import matplotlib.pyplot as plt

img = cv2.imread("input.jpg", cv2.IMREAD_GRAYSCALE)
assert img is not None, "画像が読み込めませんでした"

# Gaborフィルタ適用（実部・虚部）
freq = 0.1
theta = np.pi / 4  # 45度
real, imag = gabor(img, frequency=freq, theta=theta)

# 応答の大きさ
gabor_mag = np.sqrt(real**2 + imag**2)

# 可視化
plt.figure(figsize=(12, 4))
plt.subplot(1, 3, 1)
plt.imshow(img, cmap="gray")
plt.title("Original")
plt.subplot(1, 3, 2)
plt.imshow(real, cmap="gray")
plt.title("Gabor real")
plt.subplot(1, 3, 3)
plt.imshow(gabor_mag, cmap="gray")
plt.title("Gabor magnitude")
plt.tight_layout()
plt.show()
```

### 補足

- `input.jpg` は適宜、ご自身の画像ファイル名に置き換えてください。
- 閾値やフィルタパラメータ（`threshold1`, `threshold2`, `radius`, `frequency` など）は画像に応じて調整してください。
- LBPやGaborの結果は「画像としてのテクスチャ表現」であり、これをさらにヒストグラム化して特徴ベクトルとして使うことも多いです。

以上が、エッジ・コーナー・テクスチャを求める基本的なPythonコード例です。


