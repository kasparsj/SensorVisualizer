import Sensor from "./Sensor.js";
import {Quaternion} from "../ds";

class RotationSensor extends Sensor {
    constructor(histLen) {
        super();

        this.enableHistory(histLen);

        this.xz = new Array(histLen).fill(null);
        this.yx = new Array(histLen).fill(null);
        this.zy = new Array(histLen).fill(null);
    }

    updateHist(val, rawVal) {
        super.updateHist(val, rawVal);
        this.xz[this.histCursor] = val.projXZ();
        this.yx[this.histCursor] = val.projYX();
        this.zy[this.histCursor] = val.projZY();
    }

    oscEvent(msg) {
        const val = new Quaternion(msg.args[0].value, msg.args[1].value, msg.args[2].value, msg.args[3].value);
        this.update(val);
    }

    update(val) {
        this.updateHist(val, null);
        this.value = val;
        this.numUpdates++;
        this.curValue = val;
    }

    getProjections() {
        return [
            this.xz[this.histCursor],
            this.yx[this.histCursor],
            this.zy[this.histCursor]
        ];
    }

    info() {
        const header = [];
        if (this.value) {
            header.push(this.value.toString());
        }
        return header;
    }
}

export default RotationSensor;