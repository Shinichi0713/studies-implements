import Foundation

// ハードウェア初期化（モック）
let i2c = MockI2C()
var spi = MockSPI()
let adc = MockADC()
let uart = MockUART()
let timer = MockTimer()

// センサー初期化
var tempDriver = LM75ADriver(i2c: i2c, address: 0x48)
let pressureDriver = MockPressureSensor(spi: spi)
let adcSensor = ADCSensor(adc: adc, channel: 0)

// マネージャー初期化
var sensorManager = SensorManager(
    tempSensor: tempDriver,
    pressureSensor: pressureDriver,
    adcSensor: adcSensor
)

// 設定・通信初期化
var configManager = ConfigManager()
let comms = CommProtocol(uart: uart)

// システムコントローラー初期化
var system = SystemController(
    sensorManager: sensorManager,
    configManager: configManager,
    comms: comms,
    timer: timer
)

// 起動
switch system.startup() {
case .failure(let e):
    print("Startup failed: \(e.description)")
case .success:
    print("System started successfully")
}

// メインループ（10回実行）
for i in 0..<10 {
    system.runOnce()
    if let data = system.lastSensorData {
        print("Loop \(i): Temp=\(data.temperature) C, Pressure=\(data.pressure) Pa, Voltage=\(data.voltage) V")
    }
    timer.delay(ms: 100)
}

system.shutdown()
print("System shutdown")
