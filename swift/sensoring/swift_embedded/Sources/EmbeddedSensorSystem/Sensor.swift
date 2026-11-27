public struct TemperatureReading {
    public let celsius: Float
    public let raw: Int16

    public init(celsius: Float, raw: Int16) {
        self.celsius = celsius
        self.raw = raw
    }
}

public struct PressureReading {
    public let pascal: Float
    public let raw: UInt32
}

public struct LM75ADriver {
    let i2c: I2C
    let address: UInt8
    var initialized: Bool = false

    public init(i2c: I2C, address: UInt8 = 0x48) {
        self.i2c = i2c
        self.address = address
    }

    public mutating func initDevice() -> Result<Void, EmbeddedError> {
        initialized = true
        return .success(())
    }

    public func read() -> Result<TemperatureReading, EmbeddedError> {
        guard initialized else {
            return .failure(.sensorNotInitialized)
        }
        var buf: [UInt8] = []
        switch i2c.read(address: address, buffer: &buf, count: 2) {
        case .failure(let err):
            return .failure(err)
        case .success:
            let raw = (Int16(buf[0]) << 8) | Int16(buf[1])
            let celsius = Float(raw) / 256.0
            return .success(TemperatureReading(celsius: celsius, raw: raw))
        }
    }
}

public struct MockPressureSensor {
    let spi: SPI
    var initialized: Bool = false

    public init(spi: SPI) {
        self.spi = spi
    }

    public mutating func initDevice() -> Result<Void, EmbeddedError> {
        initialized = true
        return .success(())
    }

    public func read() -> Result<PressureReading, EmbeddedError> {
        guard initialized else {
            return .failure(.sensorNotInitialized)
        }
        var buf: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        switch spi.transfer(buffer: &buf) {
        case .failure(let err):
            return .failure(err)
        case .success:
            let raw = (UInt32(buf[0]) << 24) | (UInt32(buf[1]) << 16) | (UInt32(buf[2]) << 8) | UInt32(buf[3])
            let pascal = Float(raw) * 0.01
            return .success(PressureReading(pascal: pascal, raw: raw))
        }
    }
}

public struct ADCSensor {
    let adc: ADC
    let channel: UInt8

    public init(adc: ADC, channel: UInt8) {
        self.adc = adc
        self.channel = channel
    }

    public func readVoltage() -> Result<Float, EmbeddedError> {
        switch adc.read(channel: channel) {
        case .failure(let err):
            return .failure(err)
        case .success(let raw):
            let voltage = Float(raw) * (3.3 / 4095.0)
            return .success(voltage)
        }
    }
}

public struct SensorData {
    public var temperature: Float
    public var pressure: Float
    public var voltage: Float

    public init(temperature: Float, pressure: Float, voltage: Float) {
        self.temperature = temperature
        self.pressure = pressure
        self.voltage = voltage
    }
}

public struct SensorManager {
    var tempSensor: LM75ADriver
    var pressureSensor: MockPressureSensor
    var adcSensor: ADCSensor

    public init(tempSensor: LM75ADriver, pressureSensor: MockPressureSensor, adcSensor: ADCSensor) {
        self.tempSensor = tempSensor
        self.pressureSensor = pressureSensor
        self.adcSensor = adcSensor
    }

    public mutating func initializeAll() -> Result<Void, EmbeddedError> {
        if case .failure(let e) = tempSensor.initDevice() { return .failure(e) }
        if case .failure(let e) = pressureSensor.initDevice() { return .failure(e) }
        return .success(())
    }

    public func readAll() -> Result<SensorData, EmbeddedError> {
        guard case .success(let t) = tempSensor.read() else {
            return .failure(.sensorNotInitialized)
        }
        guard case .success(let p) = pressureSensor.read() else {
            return .failure(.sensorNotInitialized)
        }
        guard case .success(let v) = adcSensor.readVoltage() else {
            return .failure(.sensorNotInitialized)
        }
        return .success(SensorData(temperature: t.celsius, pressure: p.pascal, voltage: v))
    }
}
