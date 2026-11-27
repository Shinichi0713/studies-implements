/// システムコントローラー
///
/// システム全体の状態管理、スケジューリング、メインループを担当します。

public enum SystemMode: Equatable {
    case initializing
    case running
    case configuration
    case lowPower
    case error
    case factoryReset
}

public enum AlertState: Equatable {
    case normal
    case warning
    case alert
}

public struct SystemState: Equatable {
    public var mode: SystemMode
    public var alert: AlertState
    public var sampleCount: UInt32
    public var lastError: UInt32?
    public var isDataReady: Bool

    public init(
        mode: SystemMode = .initializing,
        alert: AlertState = .normal,
        sampleCount: UInt32 = 0,
        lastError: UInt32? = nil,
        isDataReady: Bool = false
    ) {
        self.mode = mode
        self.alert = alert
        self.sampleCount = sampleCount
        self.lastError = lastError
        self.isDataReady = isDataReady
    }
}

public final class SystemController {
    public let sensorManager: SensorManager
    public let commManager: CommunicationManager
    public let configManager: ConfigManager
    public let filterChain: FilterChain
    public let timer: TimerInterface

    public private(set) var state: SystemState
    private var filteredReadings: [SensorReading] = []
    private var nextSampleTime: UInt32 = 0

    public init(
        sensorManager: SensorManager,
        commManager: CommunicationManager,
        configManager: ConfigManager,
        filterChain: FilterChain,
        timer: TimerInterface
    ) {
        self.sensorManager = sensorManager
        self.commManager = commManager
        self.configManager = configManager
        self.filterChain = filterChain
        self.timer = timer
        self.state = SystemState()
    }

    /// システム初期化
    public func initialize() throws {
        try configManager.load()

        let config = configManager.currentConfig
        for sensorConfig in config.sensorConfigs {
            try sensorManager.registerSensor(sensorConfig)
        }

        state.mode = .running
        nextSampleTime = timer.nowMilliseconds()
    }

    /// メインループの1イテレーション
    public func tick() throws {
        try processCommands()

        let now = timer.nowMilliseconds()
        let interval = configManager.currentConfig.samplingIntervalMs

        if now >= nextSampleTime {
            try sampleAndProcess()
            nextSampleTime = now + interval
        }

        checkAlerts()
    }

    /// コマンドを処理
    private func processCommands() throws {
        guard let command = commManager.pollCommand() else {
            return
        }

        switch command {
        case .getAll:
            try commManager.sendSensorData(filteredReadings)

        case .getSensor(let id):
            let filtered = filteredReadings.filter { $0.sensorID == id }
            try commManager.sendSensorData(filtered)

        case .setFilter(let alpha):
            if (0...1000).contains(alpha) {
                var config = configManager.currentConfig
                config.filterAlpha = alpha
                configManager.updateConfig(config)
                filterChain.setLowPassAlpha(alpha)
                try commManager.sendAck()
            } else {
                try commManager.sendError("alpha must be 0...1000")
            }

        case .setInterval(let ms):
            if ms > 0 && ms <= 10_000 {
                var config = configManager.currentConfig
                config.samplingIntervalMs = ms
                configManager.updateConfig(config)
                try commManager.sendAck()
            } else {
                try commManager.sendError("interval must be 1...10000")
            }

        case .getStatus:
            let status = formatSystemState(state)
            try commManager.sendStatus(status)

        case .getVersion:
            try commManager.sendVersion("1.0.0")

        case .unknown:
            try commManager.sendError("Unknown command")
        }
    }

    /// センサーからデータを収集しフィルタ処理
    private func sampleAndProcess() throws {
        let now = timer.nowMilliseconds()
        let readings = try sensorManager.collectAll(timestampMs: now)

        filteredReadings.removeAll(keepingCapacity: true)
        for reading in readings {
            let filteredValue = filterChain.process(reading.scaledValue)
            var filtered = reading
            filtered.scaledValue = filteredValue
            filteredReadings.append(filtered)
        }

        state.sampleCount += 1
        state.isDataReady = true
    }

    /// アラート判定
    private func checkAlerts() {
        let threshold = configManager.currentConfig.temperatureAlertThreshold
        var maxAlert: AlertState = .normal

        for reading in filteredReadings {
            if reading.scaledValue > threshold {
                maxAlert = .alert
                break
            } else if reading.scaledValue > threshold * 9 / 10 {
                if maxAlert == .normal {
                    maxAlert = .warning
                }
            }
        }

        state.alert = maxAlert
    }

    /// フィルタ済みデータを取得
    public func currentData() -> [SensorReading] {
        return filteredReadings
    }
}

private func formatSystemState(_ state: SystemState) -> String {
    let modeStr: String
    switch state.mode {
    case .initializing: modeStr = "INIT"
    case .running: modeStr = "RUN"
    case .configuration: modeStr = "CONFIG"
    case .lowPower: modeStr = "LOWPWR"
    case .error: modeStr = "ERROR"
    case .factoryReset: modeStr = "FRESET"
    }

    let alertStr: String
    switch state.alert {
    case .normal: alertStr = "OK"
    case .warning: alertStr = "WARN"
    case .alert: alertStr = "ALERT"
    }

    return "mode=\(modeStr),alert=\(alertStr),samples=\(state.sampleCount)"
}
