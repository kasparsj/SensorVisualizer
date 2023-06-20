# SensorVisualizer

SensorVisualizer is a [Processing](https://processing.org/) app that visualizes sensor data, that it receives trough OSC:

It expects the incoming data in these OSC addresses:
- "/prefix/acc" (x y z)
- "/prefix/gyro" (x y z)
- "/prefix/mag" (x y z)
- "/prefix/altitude" (value)
- "/prefix/comp" (heading in radians)
- "/prefix/ecg" (value)
- "/prefix/hr" (heartrate)
- "/prefix/euler" (roll pitch yaw)
- "/prefix/quat" (w x y z)

The project includes a smartphone app [Sensor2OSC](https://github.com/kasparsj/Sensor2OSC) (iOS and Android) that can be used to send IMU sensor data to SensorVisualizer, and it works with [Polar H10](https://www.polar.com/en/sensors/h10-heart-rate-sensor) sensor for sending live ECG an HR data.

Also included are 2 Arduino examples (for [M5StickC](https://github.com/kasparsj/SensorVisualizer/tree/main/Arduino/m5StickC_MPU6886_OSC) and [MPU9250](https://github.com/kasparsj/SensorVisualizer/tree/main/Arduino/MPU9250_DMP_OSC) sensors) for sending IMU data to SensorVisualizer.

SensorVisualizer is also fully compatible with [GyrOSC](https://apps.apple.com/de/app/gyrosc/id418751595) (iOS app) can visualize it's data.

![Polar H10](/Screenshot/polar-h10.png?raw=true "Polar H10")
