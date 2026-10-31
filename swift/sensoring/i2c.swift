import Glibc

let I2C_SLAVE = 0x0703
let file = open("/dev/i2c-1", O_RDWR)
ioctl(file, I2C_SLAVE, 0x76)  // BME280アドレスを設定

var buf: [UInt8] = [0xFA]     // 読み出すレジスタアドレス
write(file, &buf, 1)

var data = [UInt8](repeating: 0, count: 3)
read(file, &data, 3)          // 3バイト読み込み


import SwiftIO

let i2c = I2C(Id.I2C0)
let bme = BME280(i2c)

while true {
    let temp = bme.readTemperature()
    print(temp)
    sleep(ms: 1000)
}

