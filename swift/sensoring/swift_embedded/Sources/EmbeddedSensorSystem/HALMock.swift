public protocol I2C {
    func write(address: UInt8, data: [UInt8]) -> Result<Void, EmbeddedError>
    func read(address: UInt8, buffer: inout [UInt8], count: Int) -> Result<Void, EmbeddedError>
    func writeRead(address: UInt8, writeData: [UInt8], readBuffer: inout [UInt8], readCount: Int) -> Result<Void, EmbeddedError>
}

public protocol SPI {
    func transfer(buffer: inout [UInt8]) -> Result<Void, EmbeddedError>
}

public protocol UART {
    func write(data: [UInt8]) -> Result<Void, EmbeddedError>
    func read(buffer: inout [UInt8], count: Int) -> Result<Void, EmbeddedError>
    func readByte() -> Result<UInt8, EmbeddedError>
}

public protocol ADC {
    func read(channel: UInt8) -> Result<UInt16, EmbeddedError>
}

public protocol GPIO {
    func set(pin: UInt8, value: Bool)
    func get(pin: UInt8) -> Bool
}

public protocol Timer {
    func millis() -> UInt64
    func micros() -> UInt64
    func delay(ms: UInt32)
}

public struct MockI2C: I2C {
    public init() {}

    public func write(address: UInt8, data: [UInt8]) -> Result<Void, EmbeddedError> {
        return .success(())
    }

    public func read(address: UInt8, buffer: inout [UInt8], count: Int) -> Result<Void, EmbeddedError> {
        buffer = Array(repeating: 0, count: count)
        if count >= 2 {
            buffer[0] = 0x19
            buffer[1] = 0x80
        }
        return .success(())
    }

    public func writeRead(address: UInt8, writeData: [UInt8], readBuffer: inout [UInt8], readCount: Int) -> Result<Void, EmbeddedError> {
        return read(address: address, buffer: &readBuffer, count: readCount)
    }
}

public struct MockSPI: SPI {
    public init() {}

    public func transfer(buffer: inout [UInt8]) -> Result<Void, EmbeddedError> {
        for i in buffer.indices {
            buffer[i] = UInt8(i & 0xFF)
        }
        return .success(())
    }
}

public class MockUART: UART {
    var rxBuffer: [UInt8] = []

    public init() {}

    public func write(data: [UInt8]) -> Result<Void, EmbeddedError> {
        let str = String(bytes: data, encoding: .utf8) ?? "<binary>"
        print("[UART TX] \(str)")
        return .success(())
    }

    public func read(buffer: inout [UInt8], count: Int) -> Result<Void, EmbeddedError> {
        let len = min(count, rxBuffer.count)
        buffer = Array(rxBuffer.prefix(len))
        return .success(())
    }

    public func readByte() -> Result<UInt8, EmbeddedError> {
        return rxBuffer.isEmpty ? .failure(.timeout) : .success(rxBuffer.removeFirst())
    }

    public func injectRX(data: [UInt8]) {
        rxBuffer.append(contentsOf: data)
    }
}

public struct MockADC: ADC {
    public init() {}

    public func read(channel: UInt8) -> Result<UInt16, EmbeddedError> {
        let value = UInt16(512 + (UInt16(channel) * 100))
        return .success(value)
    }
}

public struct MockGPIO: GPIO {
    var states: [UInt8: Bool] = [:]

    public init() {}

    public mutating func set(pin: UInt8, value: Bool) {
        states[pin] = value
    }

    public func get(pin: UInt8) -> Bool {
        return states[pin] ?? false
    }
}

public struct MockTimer: Timer {
    var startTime: UInt64 = 0

    public init() {}

    public func millis() -> UInt64 {
        return startTime &+ 100
    }

    public func micros() -> UInt64 {
        return startTime &* 1000
    }

    public func delay(ms: UInt32) {
        // モックでは何もしない
    }
}
