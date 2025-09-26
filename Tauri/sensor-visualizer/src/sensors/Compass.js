import Sensor from "./Sensor.js";
import {SensorType} from "../types.js";

class Compass extends Sensor {
    constructor() {
        super();

        this.type = SensorType.COMP;
        this.addr = "/comp";
        this.value = null;
    }

    parse(msg, i) {
        return msg.args[this.firstArg + i].value;
    }

    parseFromRow(row) {
        // For CSV/table data - assuming compass heading is in column 2
        return parseFloat(row[2]);
    }

    oscEvent(msg) {
        const val = msg.args[0].value;
        this.update(val);
    }

    info() {
        const header = [];
        if (this.value !== null && this.value !== undefined) {
            header.push(`${this.value.toFixed(2)} ${this.filterType.toString()}`);
        }
        return header;
    }
}

export default Compass;