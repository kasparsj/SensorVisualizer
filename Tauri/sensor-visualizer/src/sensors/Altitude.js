import Sensor from "./Sensor.js";
import {SensorType} from "../types.js";
import {HIST_LEN2} from "../config.js";

class Altitude extends Sensor {
    constructor(avgLen = 2, histLen = HIST_LEN2) {
        super();

        this.type = SensorType.ALTITUDE;
        this.addr = "/altitude";
        this.enableHistory(histLen);
        this.enableAverage(avgLen);
    }

    updateAvg(value) {
        if (!this.values || this.avgLen <= 0) return;

        let sum = 0;
        let count = 0;
        for (let i = this.avgLen - 1; i >= 0; i--) {
            const index = i > this.histCursor ? this.histLen + (this.histCursor - i) : this.histCursor - i;
            const val = this.values[index];
            if (val !== null && val !== undefined) {
                sum += val;
                count++;
            }
        }
        this.avgValue = count > 0 ? sum / count : null;
    }

    update(val) {
        super.update(val);
        this.updateAvg(val);
    }

    oscEvent(msg) {
        const val = msg.args[0].value;
        this.update(val);
    }

    parse(msg, i) {
        return msg.args[this.firstArg + i].value;
    }

    parseFromRow(row) {
        // For CSV/table data - assuming altitude is in column 2
        return parseFloat(row[2]);
    }

    info() {
        const header = [];
        if (this.normValues && this.normValues[this.histCursor] !== null) {
            let avgMinMax = "";
            if (this.avgLen > 0 && this.avgValue !== null) {
                avgMinMax += `avg/${this.avgLen} ${this.avgValue.toFixed(2)}`;
            }
            if (this.ups > 0 && this.minValue !== null && this.maxValue !== null) {
                avgMinMax += ` (${this.minValue.toFixed(2)}, ${this.maxValue.toFixed(2)})`;
            }
            header.push(`${avgMinMax}`);
        }
        return header;
    }
}

export default Altitude;