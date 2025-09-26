import {SensorType} from "../types.js";
import {Accelerometer, Altitude, Compass, ECG, EulerSensor, Gyroscope, HR, Magnetometer, QuatSensor} from "./index.js";

const factory = (sensorType) => {
    switch (sensorType) {
        case SensorType.GYRO:
            return new Gyroscope();
        case SensorType.ACC:
            return new Accelerometer();
        case SensorType.MAG:
            return new Magnetometer();
        case SensorType.EULER:
            return new EulerSensor();
        case SensorType.HR:
            return new HR();
        case SensorType.ECG:
            return new ECG();
        case SensorType.ALTITUDE:
            return new Altitude();
        case SensorType.QUAT:
            return new QuatSensor();
        case SensorType.COMP:
            return new Compass();
    }
}

export default factory;