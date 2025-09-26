import Sensor from "./Sensor.js";
import {SensorType} from "../types.js";
import KalmanFilter from "kalmanjs";

class ECG extends Sensor {
    constructor(histLen = 500) {
        super();

        this.type = SensorType.ECG;
        this.addr = "/ecg";
        this.supportBatch = true;
        this.enableHistory(histLen);
        this.kalman = null;
    }

    setFilterType(ft) {
        super.setFilterType(ft);
        if (ft === 'KALMAN' && !this.kalman) {
            this.kalman = new KalmanFilter({R: 0.01, Q: 3});
        }
    }

    kalman(val) {
        if (this.kalman) {
            return this.kalman.filter(val);
        }
        return val;
    }

    oscEvent(msg) {
        const val = msg.args[0].value;
        this.update(val);
    }

    info() {
        const header = [];
        if (this.value != null) {
            header.push(this.filterType + " " + nf(this.value, 0, 2));
            header.push("min, max "+nf(this.minValue, 0, 2)+", "+nf(this.maxValue, 0, 2));
        }
        else {
            header.push(this.filterType);
        }
        return header;
    }
}

export default ECG;