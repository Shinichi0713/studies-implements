public enum SystemState: Equatable {
    case initializing
    case standby
    case measuring
    case error(EmbeddedError)
    case shutdown
}

public struct SystemController {
    var sensorManager: SensorManager
    var configManager: ConfigManager
    var comms: CommProtocol
    var timer: Timer
    public var state: SystemState = .initializing
    var tempFilter: LowPassFilter
    var pressureFilter: MovingAverageFilter
    public var lastSensorData: SensorData?
    var alertPin: UInt8 = 0

    public init(sensorManager: SensorManager, configManager: ConfigManager, comms: CommProtocol, timer: Timer) {
        self.sensorManager = sensorManager
        self.configManager = configManager
        self.comms = comms
        self.timer = timer
        self.tempFilter = LowPassFilter(cutoffHz: 1.0, sampleRateHz: 10.0)
        self.pressureFilter = MovingAverageFilter(size: 5)
    }

    public mutating func startup() -> Result<Void, EmbeddedError> {
        state = .initializing
        if case .failure(let e) = configManager.load() {
            state = .error(e)
            return .failure(e)
        }
        if case .failure(let e) = sensorManager.initializeAll() {
            state = .error(e)
            return .failure(e)
        }
        state = .standby
        return .success(())
    }

    public mutating func runOnce() {
        switch state {
        case .standby, .measuring:
            state = .measuring
            guard case .success(let rawData) = sensorManager.readAll() else {
                state = .error(.sensorNotInitialized)
                return
            }
            let filteredTemp = tempFilter.process(rawData.temperature)
            let filteredPressure = pressureFilter.process(rawData.pressure)
            lastSensorData = SensorData(temperature: filteredTemp, pressure: filteredPressure, voltage: rawData.voltage)
            checkAlerts()
            handleCommands()
        case .error, .initializing, .shutdown:
            break
        }
    }

    mutating func checkAlerts() {
        guard let data = lastSensorData else { return }
        if data.temperature > configManager.getTempThreshold() {
            print("ALERT: Temperature exceeded threshold: \(data.temperature)")
        }
    }

    mutating func handleCommands() {
        switch comms.receive() {
        case .success(let cmd):
            switch cmd {
            case .readSensor:
                if let data = lastSensorData {
                    _ = comms.send(.sensorData(data))
                }
            case .reset:
                tempFilter.reset()
                pressureFilter.reset()
                state = .standby
            default:
                break
            }
        case .failure:
            break
        }
    }

    public mutating func shutdown() {
        state = .shutdown
    }
}
