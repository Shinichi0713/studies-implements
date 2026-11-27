import Foundation

public enum Command: Equatable {
    case readSensor(id: UInt8)
    case setConfig(key: String, value: Float)
    case getConfig(key: String)
    case reset
    case unknown

    public static func parse(from bytes: [UInt8]) -> Command {
        guard bytes.count >= 1 else { return .unknown }
        switch bytes[0] {
        case 0x01:
            guard bytes.count >= 2 else { return .unknown }
            return .readSensor(id: bytes[1])
        case 0x02:
            return .setConfig(key: "threshold", value: 0)
        case 0x03:
            return .getConfig(key: "threshold")
        case 0xFF:
            return .reset
        default:
            return .unknown
        }
    }
}

public struct Response {
    public let data: [UInt8]

    public init(data: [UInt8]) {
        self.data = data
    }

    public static func ok() -> Response {
        return Response(data: [0x00])
    }

    public static func error(_ err: EmbeddedError) -> Response {
        return Response(data: [0x01])
    }

    public static func sensorData(_ data: SensorData) -> Response {
        var bytes: [UInt8] = []
        withUnsafeBytes(of: data.temperature) { ptr in
            bytes.append(contentsOf: ptr.bindMemory(to: UInt8.self))
        }
        withUnsafeBytes(of: data.pressure) { ptr in
            bytes.append(contentsOf: ptr.bindMemory(to: UInt8.self))
        }
        withUnsafeBytes(of: data.voltage) { ptr in
            bytes.append(contentsOf: ptr.bindMemory(to: UInt8.self))
        }
        return Response(data: bytes)
    }
}

public struct CommProtocol {
    let uart: UART

    public init(uart: UART) {
        self.uart = uart
    }

    public func send(_ response: Response) -> Result<Void, EmbeddedError> {
        return uart.write(data: response.data)
    }

    public func receive() -> Result<Command, EmbeddedError> {
        var buf: [UInt8] = []
        switch uart.read(buffer: &buf, count: 8) {
        case .failure(let e):
            return .failure(e)
        case .success:
            return .success(Command.parse(from: buf))
        }
    }
}
