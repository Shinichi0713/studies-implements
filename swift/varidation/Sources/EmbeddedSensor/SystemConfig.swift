/// システム設定管理
///
/// 不揮発性メモリに保存する設定値を管理します。

public struct SystemConfig: Equatable {
    /// サンプリン周期（ミリ秒）
    public var samplingIntervalMs: UInt32
    /// フィルタ係数（ローパス）
    public var filterAlpha: Int32
    /// 温度アラート閾値（ミリ度）
    public var temperatureAlertThreshold: Int32
    /// センサー設定リスト
    public var sensorConfigs: [SensorConfig]
    /// 通信ボーレート
    public var baudRate: UInt32
    /// デバッグモード
    public var isDebugMode: Bool

    public init(
        samplingIntervalMs: UInt32 = 100,
        filterAlpha: Int32 = 200,
        temperatureAlertThreshold: Int32 = 35_000,
        sensorConfigs: [SensorConfig] = [],
        baudRate: UInt32 = 115_200,
        isDebugMode: Bool = false
    ) {
        self.samplingIntervalMs = samplingIntervalMs
        self.filterAlpha = filterAlpha
        self.temperatureAlertThreshold = temperatureAlertThreshold
        self.sensorConfigs = sensorConfigs
        self.baudRate = baudRate
        self.isDebugMode = isDebugMode
    }

    /// デフォルト設定を生成
    public static func `default`() -> SystemConfig {
        var config = SystemConfig()
        config.addDefaultSensors()
        return config
    }

    /// デフォルトのセンサー設定を追加
    private mutating func addDefaultSensors() {
        sensorConfigs.append(SensorConfig(
            id: 1,
            sensorType: .temperatureI2C,
            i2cAddress: 0x48,
            scaleNumerator: 1,
            scaleDenominator: 1
        ))
        sensorConfigs.append(SensorConfig(
            id: 2,
            sensorType: .pressureSPI,
            spiChipSelect: 0,
            scaleNumerator: 1,
            scaleDenominator: 10
        ))
        sensorConfigs.append(SensorConfig(
            id: 3,
            sensorType: .analogADC,
            adcChannel: 0,
            scaleNumerator: 3300,
            scaleDenominator: 4095
        ))
    }

    /// 設定の妥当性を検証
    public func validate() throws {
        guard samplingIntervalMs > 0 && samplingIntervalMs <= 10_000 else {
            throw SystemError.invalidParameter
        }
        guard filterAlpha >= 0 && filterAlpha <= 1000 else {
            throw SystemError.invalidParameter
        }
    }
}

/// 設定マネージャー
public final class ConfigManager {
    private var config: SystemConfig
    private var isModified: Bool = false

    public init() {
        self.config = .default()
    }

    /// 設定を取得
    public var currentConfig: SystemConfig {
        return config
    }

    /// 設定を更新
    public func updateConfig(_ newConfig: SystemConfig) {
        self.config = newConfig
        self.isModified = true
    }

    /// 変更フラグ
    public var hasChanges: Bool {
        return isModified
    }

    /// 設定を保存（不揮発性メモリへの書き込み）
    public func save() throws {
        // 実際の実装ではフラッシュ書き込みを行う
        isModified = false
    }

    /// 設定を読み込み
    public func load() throws {
        // 実際の実装ではフラッシュ読み出しを行う
        try config.validate()
        isModified = false
    }

    /// 工場出荷時状態にリセット
    public func factoryReset() {
        config = .default()
        isModified = true
    }
}
