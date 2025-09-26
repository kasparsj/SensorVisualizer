import Sensor from "./Sensor.js";
import {SensorType} from "../types.js";

class HR extends Sensor {
    constructor(avgLen = 0, histLen = 50) {
        super();

        this.type = SensorType.HR;
        this.addr = "/hr";
        this.supportBatch = false;
        this.enableHistory(histLen);
        this.enableAverage(avgLen);
    }

    oscEvent(msg) {
        const val = msg.args[0].value;
        this.update(val);
    }

    info() {
        const header = [];
        header.push("avg/"+this.avgLen+" "+this.avgValue.toFixed(2));
        return header;
    }
}

export default HR;