import Foundation

public struct SystemConfig {
    public var tempThreshold: Float
    public var pressureThreshold: Float
    public var sampleRateMs: UInt32
    public var filterType: UInt8

    public init() {
        tempThreshold = 80.0
        pressureThreshold = 1000.0
        sampleRateMs = 100
        filterType = 1
    }

    public func serialize() -> [UInt8] {
        var bytes: [UInt8] = []
        withUnsafeBytes(of: tempThreshold) { ptr in bytes.append(contentsOf: ptr.bindMemory(to: UInt8.self)) }
        withUnsafeBytes(of: pressureThreshold) { ptr in bytes.append(contentsOf: ptr.bindMemory(to: UInt8.self)) }
        withUnsafeBytes(of: sampleRateMs) { ptr in bytes.append(contentsOf: ptr.bindMemory(to: UInt8.self)) }
        bytes.append(filterType)
        return bytes
    }

    public static func deserialize(_ bytes: [UInt8]) -> Result<SystemConfig, EmbeddedError> {
        guard bytes.count >= 9 else { return .failure(.configError) }
        var cfg = SystemConfig()
        cfg.filterType = bytes.last ?? 0
        return .success(cfg)
    }
}

public struct ConfigManager {
    var config: SystemConfig
    var storage: [UInt8] = []

    public init() {
        config = SystemConfig()
    }

    public mutating func load() -> Result<Void, EmbeddedError> {
        if storage.count >= 9 {
            switch SystemConfig.deserialize(storage) {
            case .failure(let e): return .failure(e)
            case .success(let cfg):
                config = cfg
                return .success(())
            }
        }
        config = SystemConfig()
        return .success(())
    }

    public mutating func save() -> Result<Void, EmbeddedError> {
        let bytes = config.serialize()
        let crc = computeCRC16(bytes)
        var toStore = bytes
        toStore.append(UInt8(crc >> 8))
        toStore.append(UInt8(crc & 0xFF))
        storage = toStore
        return .success(())
    }

    public mutating func setTempThreshold(_ value: Float) {
        config.tempThreshold = value
    }

    public func getTempThreshold() -> Float {
        return config.tempThreshold
    }

    func computeCRC16(_ data: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in data {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                if crc & 0x8000 != 0 {
                    crc = (crc << 1) ^ 0x1021
                } else {
                    crc <<= 1
                }
            }
        }
        return crc
    }

    public func verifyChecksum(_ data: [UInt8]) -> Bool {
        guard data.count >= 3 else { return false }
        let payload = data.prefix(data.count - 2)
        let stored = (UInt16(data[data.count-2]) << 8) | UInt16(data[data.count-1])
        return computeCRC16(Array(payload)) == stored
    }
}
