/// センサー関連のエラー型
///
/// 組み込みシステムでは、エラーを型安全に扱うことが重要です。
/// Swift の `Error` プロトコルを採用し、do-catch で統一的に処理します。

public enum SensorError: Error, Equatable {
    /// バス通信エラー（I2C/SPI の応答なしなど）
    case busError
    /// 指定したセンサーが見つからない
    case deviceNotFound
    /// 読み取り値が有効範囲外
    case outOfRange
    /// CRC やチェックサム不一致
    case checksumError
    /// キャリブレーション未実施
    case notCalibrated
    /// 未対応のセンサー型
    case unsupportedType
}

public enum CommunicationError: Error, Equatable {
    case framingError
    case parityError
    case overrun
    case invalidCommand
    case invalidArgument
}

public enum SystemError: Error, Equatable {
    case sensor(SensorError)
    case communication(CommunicationError)
    case bufferOverflow
    case invalidParameter
    case notInitialized
    case timeout
}

extension SystemError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sensor(let e):
            return "SensorError: \(e)"
        case .communication(let e):
            return "CommunicationError: \(e)"
        case .bufferOverflow:
            return "Buffer overflow"
        case .invalidParameter:
            return "Invalid parameter"
        case .notInitialized:
            return "Not initialized"
        case .timeout:
            return "Timeout"
        }
    }
}
