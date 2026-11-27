/// センサーマネージャー
///
/// 複数のセンサーデバイスを一元管理し、統一されたインタフェースでデータを提供します。

public final class SensorManager {
    /// 登録済みセンサー設定
    private var configs: [SensorConfig] = []
    /// I2C温度センサードライバ
    private var tempDriver: LM75ADriver?
    /// SPI圧力センサードライバ
    private var pressureDriver: PressureSensorDriver?
    /// ADCドライバ
    private var adcDriver: ADCSensorDriver?

    public init() {}

    /// センサー設定を登録
    public func registerSensor(_ config: SensorConfig) throws {
        guard configs.count < 8 else {
            throw SystemError.bufferOverflow
        }
        configs.append(config)
    }

    /// I2C温度センサードライバを設定
    public func setTemperatureDriver(_ driver: LM75ADriver) {
        self.tempDriver = driver
    }

    /// SPI圧力センサードライバを設定
    public func setPressureDriver(_ driver: PressureSensorDriver) {
        self.pressureDriver = driver
    }

    /// ADCドライバを設定
    public func setADCDriver(_ driver: ADCSensorDriver) {
        self.adcDriver = driver
    }

    /// 全センサーからデータを収集
    public func collectAll(timestampMs: UInt32) throws -> [SensorReading] {
        var readings: [SensorReading] = []

        for config in configs where config.isEnabled {
            let reading = try readSingle(config: config, timestampMs: timestampMs)
            readings.append(reading)
        }

        return readings
    }

    /// 単一センサーを読み取り
    private func readSingle(config: SensorConfig,
                            timestampMs: UInt32) throws -> SensorReading {
        let (raw, scaled, quality): (Int32, Int32, DataQuality)

        switch config.sensorType {
        case .temperatureI2C:
            guard let driver = tempDriver else {
                throw SystemError.sensor(.deviceNotFound)
            }
            let value = try driver.readTemperature()
            raw = value
            scaled = value * config.scaleNumerator / config.scaleDenominator + config.offset
            quality = .good

        case .pressureSPI:
            guard let driver = pressureDriver else {
                throw SystemError.sensor(.deviceNotFound)
            }
            let value = try driver.readPressure()
            raw = value
            scaled = value * config.scaleNumerator / config.scaleDenominator + config.offset
            quality = .good

        case .analogADC:
            guard let driver = adcDriver else {
                throw SystemError.sensor(.deviceNotFound)
            }
            let value = try driver.read()
            raw = Int32(value)
            scaled = raw * config.scaleNumerator / config.scaleDenominator + config.offset
            quality = .good

        case .digitalIO:
            raw = 0
            scaled = 0
            quality = .good
        }

        return SensorReading(
            sensorID: config.id,
            rawValue: raw,
            scaledValue: scaled,
            quality: quality,
            timestampMs: timestampMs
        )
    }

    /// 登録済みセンサー数
    public var sensorCount: Int {
        return configs.count
    }
}
