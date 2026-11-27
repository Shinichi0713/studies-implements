import EmbeddedSensor

/// システム初期化関数
///
/// 実際の組み込み環境では `@main` 構造体や
/// プラットフォーム固有のエントリポイントを使用します。
func systemInit() -> SystemController {
    // 1. ハードウェア初期化（モックを使用）
    let i2c = MockI2C()
    let spi = MockSPI()
    let uart = MockUART()
    let adc = MockADC()
    let timer = MockTimer()

    // 2. センサーマネージャー初期化
    let sensorManager = SensorManager()

    let tempDriver = LM75ADriver(i2c: i2c, address: 0x48)
    sensorManager.setTemperatureDriver(tempDriver)

    let pressureDriver = PressureSensorDriver(spi: spi, chipSelect: 0)
    sensorManager.setPressureDriver(pressureDriver)

    let adcDriver = ADCSensorDriver(adc: adc, channel: 0)
    sensorManager.setADCDriver(adcDriver)

    // 3. 通信マネージャー初期化
    let commManager = CommunicationManager(uart: uart)

    // 4. 設定マネージャー初期化
    let configManager = ConfigManager()

    // 5. フィルタチェーン初期化
    let filterChain = FilterChain(
        lowPassAlpha: 200,
        movingAverageCapacity: 8
    )

    // 6. システムコントローラー作成
    let controller = SystemController(
        sensorManager: sensorManager,
        commManager: commManager,
        configManager: configManager,
        filterChain: filterChain,
        timer: timer
    )

    // 初期化実行
    do {
        try controller.initialize()
    } catch {
        fatalError("System initialization failed: \(error)")
    }

    return controller
}

/// メインループ
///
/// 実際の組み込み環境では無限ループとして実行します。
func mainLoop() {
    let controller = systemInit()

    // テスト用: コマンドを注入
    if let uart = controller.commManager {
        // UARTの直接アクセスは不可なので、
        // 実際の環境では外部からコマンドを受信
    }

    // シミュレーション: 10回のティックを実行
    for _ in 0..<10 {
        do {
            try controller.tick()
            if let timer = controller.timer as? MockTimer {
                timer.advance(milliseconds: 100)
            }
        } catch {
            print("Error during tick: \(error)")
        }
    }

    // 結果を表示
    print("Sample count: \(controller.state.sampleCount)")
    print("System state: \(controller.state)")
    for reading in controller.currentData() {
        print("Sensor \(reading.sensorID): \(Double(reading.scaledValue) / 1000.0)")
    }
}

// エントリポイント
mainLoop()
