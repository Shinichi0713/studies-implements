public enum EmbeddedError: Error, Equatable {
    case i2cError(code: UInt8)
    case spiError(code: UInt8)
    case uartError(code: UInt8)
    case sensorNotInitialized
    case invalidSensorId
    case filterError
    case configError
    case checksumMismatch
    case invalidCommand
    case bufferOverflow
    case timeout

    public var description: String {
        switch self {
        case .i2cError(let code): return "I2C Error: \(code)"
        case .spiError(let code): return "SPI Error: \(code)"
        case .uartError(let code): return "UART Error: \(code)"
        case .sensorNotInitialized: return "Sensor not initialized"
        case .invalidSensorId: return "Invalid sensor ID"
        case .filterError: return "Filter error"
        case .configError: return "Config error"
        case .checksumMismatch: return "Checksum mismatch"
        case .invalidCommand: return "Invalid command"
        case .bufferOverflow: return "Buffer overflow"
        case .timeout: return "Timeout"
        }
    }
}
