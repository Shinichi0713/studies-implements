/// 通信マネージャー
///
/// シリアル通信（UART）を介したコマンド受信・データ送信を管理します。
/// コマンドプロトコルはテキストベースです。

public enum Command: Equatable {
    case getAll
    case getSensor(id: UInt8)
    case setFilter(alpha: Int32)
    case setInterval(ms: UInt32)
    case getStatus
    case getVersion
    case unknown
}

public final class CommunicationManager {
    private let uart: UARTInterface
    private var rxBuffer: String = ""

    public init(uart: UARTInterface) {
        self.uart = uart
    }

    /// 受信バファをチェックしてコマンドを解析
    public func pollCommand() -> Command? {
        guard uart.isReadable else {
            return nil
        }

        while let byte = uart.readByte() {
            if byte == UInt8(ascii: "\n") || byte == UInt8(ascii: "\r") {
                if !rxBuffer.isEmpty {
                    let cmd = parseCommand(rxBuffer)
                    rxBuffer = ""
                    return cmd
                }
            } else if byte >= 0x20 && byte <= 0x7E {
                rxBuffer.append(Character(UnicodeScalar(byte)))
            }
        }

        return nil
    }

    /// コマンド文字列を解析
    private func parseCommand(_ input: String) -> Command {
        let parts = input.uppercased().split(separator: " ")
        guard let first = parts.first else {
            return .unknown
        }

        switch first {
        case "GETALL":
            return .getAll
        case "GET":
            if parts.count >= 2,
               let id = UInt8(parts[1]) {
                return .getSensor(id: id)
            }
            return .unknown
        case "FILTER":
            if parts.count >= 2,
               let alpha = Int32(parts[1]) {
                return .setFilter(alpha: alpha)
            }
            return .unknown
        case "INTERVAL":
            if parts.count >= 2,
               let ms = UInt32(parts[1]) {
                return .setInterval(ms: ms)
            }
            return .unknown
        case "STATUS":
            return .getStatus
        case "VERSION":
            return .getVersion
        default:
            return .unknown
        }
    }

    /// センサーデータをJSON風のテキストフォーマットで送信
    public func sendSensorData(_ readings: [SensorReading]) throws {
        var output = "{\"sensors\":["
        for (i, r) in readings.enumerated() {
            if i > 0 { output += "," }
            let q = r.quality == .good ? "G"
                : r.quality == .uncertain ? "U" : "B"
            output += "{\"id\":\(r.sensorID),\"val\":\(r.scaledValue),\"q\":\"\(q)\"}"
        }
        output += "]}\n"
        try sendString(output)
    }

    /// ステータスメッセージを送信
    public func sendStatus(_ status: String) throws {
        try sendString("STATUS: \(status)\n")
    }

    /// バージョン情報を送信
    public func sendVersion(_ version: String) throws {
        try sendString("VERSION: \(version)\n")
    }

    /// エラーメッセージを送信
    public func sendError(_ message: String) throws {
        try sendString("ERROR: \(message)\n")
    }

    /// 確認応答を送信
    public func sendAck() throws {
        try sendString("OK\n")
    }

    /// 文字列をUARTに送信
    private func sendString(_ string: String) throws {
        for byte in string.utf8 {
            try uart.writeByte(byte)
        }
    }
}
