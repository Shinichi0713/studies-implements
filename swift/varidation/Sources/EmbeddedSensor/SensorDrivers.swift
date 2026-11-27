/// センサーデバイスドライバ群
///
/// I2C温度センサー（LM75A互換）、SPI圧力センサー、ADCアナログセンサーの
/// 各ドライバを実装します。

/// LM75A I2C温度センサードライバ
public final class LM75ADriver {
    /// 温度レジスタアドレス
    private let tempRegister: UInt8 = 0x00
    /// I2Cバス
    private let i2c: I2CInterface
    /// デバイスI2Cアドレス
    private let address: UInt8

    public init(i2c: I2CInterface, address: UInt8) {
        self.i2c = i2c
        self.address = address
    }

    /// 温度を読み取る（ミリ度で返す）
    ///
    /// LM75Aの温度レジスタは16bitで、上位11bitが温度データ。
    /// - 上位8bit: 整数部（符号付き）
    /// - 下位8bitの上位3bit: 小数部（0.125℃刻み）
    public func readTemperature() throws -> Int32 {
        let data = try i2c.writeRead(
            address: address,
            writeData: [tempRegister],
            readLength: 2
        )

        let raw = (UInt16(data[0]) << 8) | UInt16(data[1])
        let tempRaw = raw >> 5  // 上位11bitを抽出

        let tempSigned: Int16
        if (tempRaw & 0x0400) != 0 {
            // 負の値（2の補数変換）
            tempSigned = Int16(bitPattern: tempRaw | 0xF800)
        } else {
            tempSigned = Int16(bitPattern: tempRaw)
        }

        // 0.125℃刻みなので、ミリ度に変換（×125）
        return Int32(tempSigned) * 125
    }

    /// デバイス存在確認
    public func probe() -> Bool {
        do {
            try i2c.write(address: address, data: [])
            return true
        } catch {
            return false
        }
    }
}

/// SPI圧力センサードライバ
public final class PressureSensorDriver {
    private let spi: SPIInterface
    private let chipSelect: UInt8

    public init(spi: SPIInterface, chipSelect: UInt8) {
        self.spi = spi
        self.chipSelect = chipSelect
    }

    /// 圧力を読み取る（生の値を返す）
    public func readPressure() throws -> Int32 {
        let txData: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        let rxData = try spi.transfer(txData)

        // 24bitの生データを仮定
        let raw = (Int32(rxData[1]) << 16)
            | (Int32(rxData[2]) << 8)
            | Int32(rxData[3])
        return raw
    }
}

/// ADCアナログセンサードライバ
public final class ADCSensorDriver {
    private let adc: ADCInterface
    private let channel: UInt8

    public init(adc: ADCInterface, channel: UInt8) {
        self.adc = adc
        self.channel = channel
    }

    /// ADC値を読み取る（12bit想定）
    public func read() throws -> UInt16 {
        return try adc.read(channel: channel)
    }
}
