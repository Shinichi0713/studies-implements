/// デジタルフィルタモジュール
///
/// センサーデータに対して各種デジタルフィルタ処理を提供します。

/// フィルタ係数のスケール（固定小数点）
public let filterScale: Int32 = 1000

/// 1次ローパスフィルタ
///
/// 式: y[n] = alpha * x[n] + (1 - alpha) * y[n-1]
/// alpha: 0〜1000（大きいほど新しい値に追従）
public final class LowPassFilter1 {
    private var alpha: Int32
    private var previousOutput: Int32 = 0
    private var isInitialized: Bool = false

    public init(alpha: Int32) {
        precondition(alpha >= 0 && alpha <= filterScale,
                     "alpha must be in 0...\(filterScale)")
        self.alpha = alpha
    }

    public func setAlpha(_ alpha: Int32) {
        precondition(alpha >= 0 && alpha <= filterScale)
        self.alpha = alpha
    }

    public func process(_ input: Int32) -> Int32 {
        if !isInitialized {
            previousOutput = input
            isInitialized = true
            return input
        }

        let output = (alpha * input
            + (filterScale - alpha) * previousOutput)
            / filterScale
        previousOutput = output
        return output
    }

    public func reset() {
        isInitialized = false
        previousOutput = 0
    }
}

/// 移動平均フィルタ
public final class MovingAverageFilter {
    private let capacity: Int
    private var buffer: [Int32] = []
    private var sum: Int32 = 0

    public init(capacity: Int) {
        self.capacity = capacity
    }

    public func process(_ input: Int32) -> Int32 {
        if buffer.count >= capacity {
            sum -= buffer.removeFirst()
        }
        buffer.append(input)
        sum += input
        return sum / Int32(buffer.count)
    }

    public var isFull: Bool {
        return buffer.count >= capacity
    }

    public var count: Int {
        return buffer.count
    }

    public func reset() {
        buffer.removeAll(keepingCapacity: true)
        sum = 0
    }
}

/// 簡易カルマンフィルタ
public final class KalmanFilter {
    private var estimateError: Int32
    private let measurementError: Int32
    private let processNoise: Int32
    private var estimate: Int32 = 0
    private var isInitialized: Bool = false
    private let scale: Int32

    public init(measurementError: Int32,
                processNoise: Int32,
                scale: Int32) {
        self.estimateError = measurementError
        self.measurementError = measurementError
        self.processNoise = processNoise
        self.scale = scale
    }

    public func process(_ measurement: Int32) -> Int32 {
        if !isInitialized {
            estimate = measurement
            isInitialized = true
            return measurement
        }

        // 予測ステップ
        estimateError += processNoise

        // カルマンゲイン計算
        let kalmanGain = (estimateError * scale)
            / (estimateError + measurementError)

        // 更新ステップ
        estimate = estimate
            + (kalmanGain * (measurement - estimate)) / scale

        // 誤差共分散の更新
        estimateError =
            (scale - kalmanGain) * estimateError / scale

        return estimate
    }

    public var currentEstimate: Int32 {
        return estimate
    }

    public func reset() {
        isInitialized = false
        estimateError = measurementError
        estimate = 0
    }
}

/// メディアンフィルタ
public final class MedianFilter {
    private let capacity: Int
    private var buffer: [Int32] = []

    public init(capacity: Int) {
        self.capacity = capacity
    }

    public func process(_ input: Int32) -> Int32 {
        if buffer.count >= capacity {
            buffer.removeFirst()
        }
        buffer.append(input)

        let sorted = buffer.sorted()
        return sorted[sorted.count / 2]
    }

    public func reset() {
        buffer.removeAll(keepingCapacity: true)
    }
}

/// フィルタチェーン
///
/// 複数のフィルタ順次適用する。
public final class FilterChain {
    private let lowPass: LowPassFilter1
    private let movingAverage: MovingAverageFilter

    public init(lowPassAlpha: Int32, movingAverageCapacity: Int = 8) {
        self.lowPass = LowPassFilter1(alpha: lowPassAlpha)
        self.movingAverage = MovingAverageFilter(capacity: movingAverageCapacity)
    }

    public func process(_ input: Int32) -> Int32 {
        let stage1 = lowPass.process(input)
        return movingAverage.process(stage1)
    }

    public func setLowPassAlpha(_ alpha: Int32) {
        lowPass.setAlpha(alpha)
    }

    public func reset() {
        lowPass.reset()
        movingAverage.reset()
    }
}
