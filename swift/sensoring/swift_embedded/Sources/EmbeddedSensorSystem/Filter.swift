import Foundation

public protocol Filter {
    mutating func process(_ input: Float) -> Float
    mutating func reset()
}

public struct LowPassFilter: Filter {
    var alpha: Float
    var y: Float = 0
    var first: Bool = true

    public init(cutoffHz: Float, sampleRateHz: Float) {
        let rc = 1.0 / (2.0 * Float.pi * cutoffHz)
        let dt = 1.0 / sampleRateHz
        self.alpha = dt / (rc + dt)
    }

    public mutating func process(_ input: Float) -> Float {
        if first {
            y = input
            first = false
            return y
        }
        y = alpha * input + (1 - alpha) * y
        return y
    }

    public mutating func reset() {
        first = true
        y = 0
    }
}

public struct MovingAverageFilter: Filter {
    var buffer: [Float]
    var index: Int = 0
    var filled: Bool = false

    public init(size: Int) {
        buffer = Array(repeating: 0, count: size)
    }

    public mutating func process(_ input: Float) -> Float {
        buffer[index] = input
        index += 1
        if index >= buffer.count {
            index = 0
            filled = true
        }
        let count = filled ? buffer.count : index
        let sum = buffer.prefix(count).reduce(0, +)
        return sum / Float(count)
    }

    public mutating func reset() {
        index = 0
        filled = false
        buffer = Array(repeating: 0, count: buffer.count)
    }
}

public struct MedianFilter: Filter {
    var buffer: [Float]
    var index: Int = 0

    public init(size: Int) {
        buffer = Array(repeating: 0, count: size)
    }

    public mutating func process(_ input: Float) -> Float {
        buffer[index] = input
        index = (index + 1) % buffer.count
        let sorted = buffer.sorted()
        return sorted[buffer.count / 2]
    }

    public mutating func reset() {
        index = 0
        buffer = Array(repeating: 0, count: buffer.count)
    }
}

public struct SimpleKalmanFilter: Filter {
    var q: Float
    var r: Float
    var x: Float = 0
    var p: Float = 1
    var k: Float = 0
    var first: Bool = true

    public init(q: Float, r: Float) {
        self.q = q
        self.r = r
    }

    public mutating func process(_ input: Float) -> Float {
        if first {
            x = input
            p = 1
            first = false
            return x
        }
        p = p + q
        k = p / (p + r)
        x = x + k * (input - x)
        p = (1 - k) * p
        return x
    }

    public mutating func reset() {
        first = true
        x = 0
        p = 1
        k = 0
    }
}
