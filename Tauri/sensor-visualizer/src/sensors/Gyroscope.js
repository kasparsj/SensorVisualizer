import VectorSensor from "./VectorSensor.js";
import {SensorType} from "../types.js";
import {HIST_LEN} from "../config.js";

class Gyroscope extends VectorSensor {
    constructor(histLen = HIST_LEN, deltaSumWin = 2) {
        super(histLen);

        this.type = SensorType.GYRO;
        this.supportBatch = true;
        // this.enableMagnitude(deltaSumWin);
        // this.setFilterType(FilterType.LOWPASS);
    }

    info() {
        const header = [];
        header.push(`${this.filterType} ${this.value.x.toFixed(2)}, ${this.value.y.toFixed(2)}, ${this.value.z.toFixed(2)}, mag: ${this.value.mag().toFixed(2)}`);
        return header;
    }
}

export default Gyroscope;