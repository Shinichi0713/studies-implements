/// HALモック実装
///
/// テストおよび構造理解用のモック実装。
/// 実際のMCUでは各ベンダーのHAL実装に置き換えます。

public final class MockI2C: I2CInterface {
    public init() {}

    public func write(address: UInt8, data: [UInt8]) throws {
        // モック: 常に成功
    }

    public func writeRead(
        address: UInt8,
        writeData: [UInt8],
        readLength: Int
    ) throws -> [UInt8] {
        // モック: LM75A の温度データをシミュレート
        // 約 25.5℃ を返す（0x19 0x80）
        var result = [UInt8](repeating: 0, count: readLength)
        if readLength > 0 { result[0] = 0x19 }
        if readLength > 1 { result[1] = 0x80 }
        return result
    }
}

public final class MockSPI: SPIInterface {
    public init() {}

    public func transfer(_ data: [UInt8]) throws -> [UInt8] {
        // モック: 入力データをそのまま返すエコー
        return data
    }
}

public final class MockUART: UARTInterface {
    private var rxBuffer: [UInt8] = []

    public init() {}

    public func writeByte(_ byte: UInt8) throws {
        // モック: 送信を無視
    }

    public func readByte() -> UInt8? {
        return rxBuffer.isEmpty ? nil : rxBuffer.removeFirst()
    }

    public var isReadable: Bool {
        return !rxBuffer.isEmpty
    }

    /// テスト用: 受信データを注入
    public func injectReceive(data: [UInt8]) {
        rxBuffer.append(contentsOf: data)
    }
}

public final class MockADC: ADCInterface {
    public init() {}

    public func read(channel: UInt8) throws -> UInt16 {
        // モック: 12bit ADC の半分の値を返す
        return 2048
    }
}

public final class MockTimer: TimerInterface {
    private var currentTime: UInt32 = 0

    public init() {}

    public func delay(milliseconds: UInt32) {
        currentTime += milliseconds
    }

    public func delay(microseconds: UInt32) {
        currentTime += microseconds / 1000
    }

    public func nowMilliseconds() -> UInt32 {
        return currentTime
    }

    /// テスト用: 時刻を進める
    public func advance(milliseconds: UInt32) {
        currentTime += milliseconds
    }
}

public final class MockGPIO: GPIOInterface {
    private var _isHigh: Bool = false

    public init() {}

    public func setHigh() {
        _isHigh = true
    }

    public func setLow() {
        _isHigh = false
    }

    public var isHigh: Bool {
        return _isHigh
    }

    public func toggle() {
        _isHigh.toggle()
    }
}
