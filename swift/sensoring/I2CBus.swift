import Foundation

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

// ============================================================
// I2C Bus Controller
// Linux /dev/i2c-* デバイスをioctlで操作
// ============================================================

let I2C_SLAVE: UInt = 0x0703
let I2C_SMBUS: UInt = 0x0720

class I2CBus {
    private let fileDescriptor: Int32
    private let busNumber: Int
    private var currentAddress: UInt8 = 0

    init?(busNumber: Int) {
        self.busNumber = busNumber
        let path = "/dev/i2c-\(busNumber)"
        self.fileDescriptor = open(path, O_RDWR)
        if self.fileDescriptor < 0 {
            print("❌ Failed to open I2C bus \(path): \(String(cString: strerror(errno)))")
            return nil
        }
    }

    deinit {
        close(fileDescriptor)
    }

    /// 通信するSlaveアドレスを設定
    func setAddress(_ address: UInt8) -> Bool {
        guard address != currentAddress else { return true }
        let result = ioctl(fileDescriptor, I2C_SLAVE, Int(address))
        if result < 0 {
            print("❌ Failed to set I2C address 0x\(String(address, radix: 16)): \(String(cString: strerror(errno)))")
            return false
        }
        currentAddress = address
        return true
    }

    /// レジスタに1バイト書き込み
    func writeByte(register: UInt8, value: UInt8, address: UInt8) -> Bool {
        guard setAddress(address) else { return false }
        var buf: [UInt8] = [register, value]
        let result = buf.withUnsafeMutableBufferPointer {
            write(fileDescriptor, $0.baseAddress!, 2)
        }
        return result == 2
    }

    /// レジスタアドレスを書いてから複数バイト読み込み
    func readBytes(register: UInt8, length: Int, address: UInt8) -> [UInt8]? {
        guard setAddress(address) else { return nil }

        // レジスタアドレスを書き込み
        var reg = register
        let writeResult = write(fileDescriptor, &reg, 1)
        guard writeResult == 1 else {
            print("❌ Failed to write register address")
            return nil
        }

        // データを読み込み
        var buffer = [UInt8](repeating: 0, count: length)
        let readResult = buffer.withUnsafeMutableBufferPointer {
            read(fileDescriptor, $0.baseAddress!, length)
        }
        guard readResult == length else {
            print("❌ Failed to read data: expected \(length), got \(readResult)")
            return nil
        }
        return buffer
    }

    /// 単一バイト書き込み（アドレス指定なし）
    func write(_ data: [UInt8], address: UInt8) -> Bool {
        guard setAddress(address) else { return false }
        let result = data.withUnsafeBytes {
            write(fileDescriptor, $0.baseAddress!, data.count)
        }
        return result == data.count
    }

    /// 単純読み込み
    func read(length: Int, address: UInt8) -> [UInt8]? {
        guard setAddress(address) else { return nil }
        var buffer = [UInt8](repeating: 0, count: length)
        let result = buffer.withUnsafeMutableBufferPointer {
            read(fileDescriptor, $0.baseAddress!, length)
        }
        guard result == length else { return nil }
        return buffer
    }
}
