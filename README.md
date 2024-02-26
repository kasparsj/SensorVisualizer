# SensorVisualizer

SensorVisualizer is a [Processing](https://processing.org/) app that visualizes sensor data, that it receives trough OSC.

# Installation

1. Download and install [Processing](https://processing.org/download).
2. Install contributor libraries (Sketch > Import Library... > Manager Libraries...)
  * oscP5
  * UDP
3. Download and install [JKalman library](https://github.com/kasparsj/JKalman/releases/tag/0.1.0)

# OSC addresses

By default it listens to port 57121 and the following OSC addresses:
- "/deviceId/acc" (x y z)
- "/deviceId/gyro" (x y z)
- "/deviceId/mag" (x y z)
- "/deviceId/altitude" (value)
- "/deviceId/comp" (heading in radians)
- "/deviceId/ecg" (value)
- "/deviceId/hr" (heartrate)
- "/deviceId/euler" (roll pitch yaw)
- "/deviceId/quat" (w x y z)

The "deviceId" prefix must change depending on the sending device.

## Sensor Fusion

- [x] Mahony
- [x] Madgwick
- [ ] Kalman

## Filtering

- [x] Lowpass
- [x] Kalman

## Data Collection

The project includes a smartphone app [Sensor2OSC](https://github.com/kasparsj/Sensor2OSC) (iOS and Android) that can be used to send IMU sensor data to SensorVisualizer, and it works with [Polar H10](https://www.polar.com/en/sensors/h10-heart-rate-sensor) sensor for sending live ECG an HR data.

Also included are 2 Arduino examples (for [M5StickC](https://github.com/kasparsj/SensorVisualizer/tree/main/Arduino/m5StickC_MPU6886_OSC) and [MPU9250](https://github.com/kasparsj/SensorVisualizer/tree/main/Arduino/MPU9250_DMP_OSC) sensors) for sending IMU data to SensorVisualizer.

SensorVisualizer is also fully compatible with [GyrOSC](https://apps.apple.com/de/app/gyrosc/id418751595) (iOS app) can visualize it's data.

## Data Recording

Once data is being received SensorVisualizer can be used to record and later play back sensor data.

## Keyboard Commands

Press key 'i' to display info about all keyboard commands.

## Screenshots

Example screenshot of SensorVisualizer visualizing data from Polar H10 sensor:

![Polar H10](/Screenshot/polar-h10.png?raw=true "Polar H10")
