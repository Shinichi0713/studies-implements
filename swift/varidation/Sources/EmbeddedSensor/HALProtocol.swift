/// ハードウェア抽象化レイヤー（HAL）プロトコル定義
///
/// 実際のMCUでは各ベンーのHAL実装に準拠します。
/// ここではプロトコルでインタフェースを抽象化し、
/// モック実装と実機実装を切り替え可能にします。

/// I2Cバスインタフェース
public protocol I2CInterface {
    /// デバイスに書き込み
    func write(address: UInt8, data: [UInt8]) throws
    /// 書き込み後に読み出し
    func writeRead(address: UInt8, writeData: [UInt8], readLength: Int) throws -> [UInt8]
}

/// SPIバスインタフェース
public protocol SPIInterface {
    /// データ転送（同時送受信）
    func transfer(_ data: [UInt8]) throws -> [UInt8]
}

/// UARTインタフェース
public protocol UARTInterface {
    /// 1バイト送信
    func writeByte(_ byte: UInt8) throws
    /// 1バイト受信（nilの場合はデータなし）
    func readByte() -> UInt8?
    /// 受信可能か
    var isReadable: Bool { get }
}

/// ADCインタフェース
public protocol ADCInterface {
    /// 指定チャンネルを読み取り
    func read(channel: UInt8) throws -> UInt16
}

/// タイマー・ディレイインタフェース
public protocol TimerInterface {
    /// ミリ秒待機
    func delay(milliseconds: UInt32)
    /// マイクロ秒待機
    func delay(microseconds: UInt32)
    /// 現在時刻（ミリ秒）を取得
    func nowMilliseconds() -> UInt32
}

/// GPIOピンインタフェース
public protocol GPIOInterface {
    func setHigh()
    func setLow()
    var isHigh: Bool { get }
    func toggle()
}
