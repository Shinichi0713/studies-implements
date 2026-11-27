/// センサー関連のデータ型定義

/// センサータイプ
public enum SensorType: Equatable {
    case temperatureI2C
    case pressureSPI
    case analogADC
    case digitalIO
}

/// データ品質
public enum DataQuality: Equatable {
    case good
    case uncertain
    case bad
}

/// センサー読み取りデータ
public struct SensorReading: Equatable {
    /// センサーID
    public let sensorID: UInt8
    /// 生のセンサー値
    public let rawValue: Int32
    /// スケーリング済み値（単位: 1/1000）
    public var scaledValue: Int32
    /// データ品質
    public let quality: DataQuality
    /// タイムスタンプ（ミリ秒）
    public let timestampMs: UInt32

    public init(
        sensorID: UInt8,
        rawValue: Int32,
        scaledValue: Int32,
        quality: DataQuality,
        timestampMs: UInt32
    ) {
        self.sensorID = sensorID
        self.rawValue = rawValue
        self.scaledValue = scaledValue
        self.quality = quality
        self.timestampMs = timestampMs
    }
}

/// センサー設定
public struct SensorConfig: Equatable {
    public let id: UInt8
    public let sensorType: SensorType
    public let i2cAddress: UInt8?
    public let adcChannel: UInt8?
    public let spiChipSelect: UInt8?
    public let scaleNumerator: Int32
    public let scaleDenominator: Int32
    public let offset: Int32
    public var isEnabled: Bool

    public init(
        id: UInt8,
        sensorType: SensorType,
        i2cAddress: UInt8? = nil,
        adcChannel: UInt8? = nil,
        spiChipSelect: UInt8? = nil,
        scaleNumerator: Int32 = 1,
        scaleDenominator: Int32 = 1,
        offset: Int32 = 0,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.sensorType = sensorType
        self.i2cAddress = i2cAddress
        self.adcChannel = adcChannel
        self.spiChipSelect = spiChipSelect
        self.scaleNumerator = scaleNumerator
        self.scaleDenominator = scaleDenominator
        self.offset = offset
        self.isEnabled = isEnabled
    }
}
