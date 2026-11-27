import Foundation

// ============================================================
// BME280 Sensor Driver
// I2C接続のBME280から温度・湿度・気圧を読み取る
// ============================================================

class BME280 {
    private let i2c: I2CBus
    private let address: UInt8
    private(set) var isInitialized = false

    // キャリブレーションデータ
    private var digT: [Int16] = [0, 0, 0]   // Temperature calibration
    private var digP: [UInt16] = [0, 0, 0, 0, 0, 0, 0, 0, 0]  // Pressure calibration
    private var digH: [UInt16] = [0, 0, 0, 0, 0, 0]  // Humidity calibration
    private var tFine: Int32 = 0

    // レジスタアドレス
    private enum Register: UInt8 {
        case chipID       = 0xD0
        case ctrlHum      = 0xF2
        case status       = 0xF3
        case ctrlMeas     = 0xF4
        case config       = 0xF5
        case pressMSB     = 0xF7
        case tempMSB      = 0xFA
        case humMSB       = 0xFD
        case calib00      = 0x88
        case calib26      = 0xE1
    }

    init(i2c: I2CBus?, address: UInt8 = 0x76) {
        self.i2c = i2c!
        self.address = address
    }

    /// BME280を初期化し、キャリブレーションデータを読み込む
    func initialize() -> Bool {
        guard let chipID = i2c.readBytes(register: Register.chipID.rawValue, length: 1, address: address),
              chipID[0] == 0x60 else {
            print("⚠️ BME280 not detected at address 0x\(String(address, radix: 16))")
            return false
        }
        print("✅ BME280 chip ID verified: 0x\(String(chipID[0], radix: 16))")

        // キャリブレーションデータ読み込み
        guard readCalibrationData() else {
            print("❌ Failed to read calibration data")
            return false
        }

        // 設定: 湿度オーバーサンプリング x1
        _ = i2c.writeByte(register: Register.ctrlHum.rawValue, value: 0x01, address: address)

        // 設定: 温度・気圧オーバーサンプリング x1, Normal mode
        _ = i2c.writeByte(register: Register.ctrlMeas.rawValue, value: 0x27, address: address)

        // 設定: スタンバイ 0.5ms, IIRフィルタ off, SPI off
        _ = i2c.writeByte(register: Register.config.rawValue, value: 0x00, address: address)

        isInitialized = true
        return true
    }

    /// キャリブレーションデータを読み込む
    private func readCalibrationData() -> Bool {
        // Temperature/Pressure calibration (0x88-0xA1, 26 bytes)
        guard let calib1 = i2c.readBytes(register: Register.calib00.rawValue, length: 26, address: address) else {
            return false
        }

        digT[0] = Int16(calib1[0]) | (Int16(calib1[1]) << 8)
        digT[1] = Int16(calib1[2]) | (Int16(calib1[3]) << 8)
        digT[2] = Int16(calib1[4]) | (Int16(calib1[5]) << 8)

        digP[0] = UInt16(calib1[6])  | (UInt16(calib1[7])  << 8)
        digP[1] = UInt16(calib1[8])  | (UInt16(calib1[9])  << 8)
        digP[2] = UInt16(calib1[10]) | (UInt16(calib1[11]) << 8)
        digP[3] = UInt16(calib1[12]) | (UInt16(calib1[13]) << 8)
        digP[4] = UInt16(calib1[14]) | (UInt16(calib1[15]) << 8)
        digP[5] = UInt16(calib1[16]) | (UInt16(calib1[17]) << 8)
        digP[6] = UInt16(calib1[18]) | (UInt16(calib1[19]) << 8)
        digP[7] = UInt16(calib1[20]) | (UInt16(calib1[21]) << 8)
        digP[8] = UInt16(calib1[22]) | (UInt16(calib1[23]) << 8)

        // Humidity calibration part 1 (0xA1)
        digH[0] = UInt16(calib1[25])

        // Humidity calibration part 2 (0xE1-0xE7, 7 bytes)
        guard let calib2 = i2c.readBytes(register: Register.calib26.rawValue, length: 7, address: address) else {
            return false
        }

        digH[1] = UInt16(calib2[0]) | (UInt16(calib2[1]) << 8)
        digH[2] = Int8(bitPattern: calib2[2])
        digH[3] = (UInt16(calib2[3]) << 4) | (UInt16(calib2[4]) & 0x0F)
        digH[4] = (UInt16(calib2[4]) >> 4) | (UInt16(calib2[5]) << 4)
        digH[5] = Int8(bitPattern: calib2[6])

        print("✅ Calibration data loaded successfully")
        return true
    }

    /// センサから温度・湿・気圧を読み取る
    func read() -> SensorReading {
        guard isInitialized,
              let data = i2c.readBytes(register: Register.pressMSB.rawValue, length: 8, address: address) else {
            return SensorReading.simulated()
        }

        // Raw ADC values (20-bit, MSB first)
        let adcP = (Int32(data[0]) << 12) | (Int32(data[1]) << 4) | (Int32(data[2]) >> 4)
        let adcT = (Int32(data[3]) << 12) | (Int32(data[4]) << 4) | (Int32(data[5]) >> 4)
        let adcH = (Int32(data[6]) << 8)  | Int32(data[7])

        let temperature = compensateTemperature(adcT: adcT)
        let pressure    = compensatePressure(adcP: adcP)
        let humidity    = compensateHumidity(adcH: adcH)
        let altitude    = 44330.0 * (1.0 - pow(pressure / 1013.25, 0.1903))

        return SensorReading(
            temperature: temperature,
            humidity: humidity,
            pressure: pressure,
            altitude: altitude
        )
    }

    // MARK: - Temperature Compensation
    private func compensateTemperature(adcT: Int32) -> Double {
        let var1 = (((adcT >> 3) - (Int32(digT[0]) << 1)) * Int32(digT[1])) >> 11
        let var2 = (((((adcT >> 4) - Int32(digT[0])) *
                      ((adcT >> 4) - Int32(digT[0]))) >> 12) * Int32(digT[2])) >> 14
        tFine = var1 + var2
        let temp = (tFine * 5 + 128) >> 8
        return Double(temp) / 100.0
    }

    // MARK: - Pressure Compensation
    private func compensatePressure(adcP: Int32) -> Double {
        var var1 = Int64(tFine) - 128000
        var var2 = var1 * var1 * Int64(digP[5])
        var2 += (var1 * Int64(digP[4])) << 17
        var2 += (Int64(digP[3]) << 35)
        var1 = ((var1 * var1 * Int64(digP[2])) >> 8) + ((var1 * Int64(digP[1])) << 12)
        var1 = ((Int64(1) << 47) + var1) * Int64(digP[0]) >> 33

        if var1 == 0 { return 0.0 }

        var p = Int64(1048576) - Int64(adcP)
        p = (((p << 31) - var2) * 3125) / var1
        var1 = (Int64(digP[8]) * (p >> 13) * (p >> 13)) >> 25
        var2 = (Int64(digP[7]) * p) >> 19
        p = ((p + var1 + var2) >> 8) + (Int64(digP[6]) << 4)

        return Double(p) / 25600.0
    }

    // MARK: - Humidity Compensation
    private func compensateHumidity(adcH: Int32) -> Double {
        var v_x1_u32r = Int32(tFine) - Int32(76800)
        v_x1_u32r = (((((adcH << 14) - (Int32(digH[3]) << 20) -
                       (Int32(digH[4]) * v_x1_u32r)) + Int32(16384)) >> 15) *
                     (((((((v_x1_u32r * Int32(digH[5])) >> 10) *
                          (((v_x1_u32r * Int32(digH[2])) >> 11) + Int32(32768))) >> 10) +
                        Int32(2097152)) * Int32(digH[1]) + 8192) >> 14))
        v_x1_u32r = (v_x1_u32r - (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) *
                                    Int32(digH[0])) >> 4))
        v_x1_u32r = v_x1_u32r < 0 ? 0 : v_x1_u32r
        v_x1_u32r = v_x1_u32r > 419430400 ? 419430400 : v_x1_u32r
        return Double(v_x1_u32r >> 12) / 1024.0
    }
}
