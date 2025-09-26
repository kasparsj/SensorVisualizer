import RotationSensor from "./RotationSensor.js";
import {SensorType} from "../types.js";
import {Quaternion} from "../ds/index.js";
import {HIST_LEN} from "../config.js";

class QuatSensor extends RotationSensor {
    constructor(histLen = HIST_LEN) {
        super(histLen);

        this.type = SensorType.QUAT;
        this.addr = "/quat";
    }

    getOrigEulerAngles() {
        if (!this.value) {
            return null;
        }
        return this.value.toEuler();
    }

    getQuaternion() {
        let quat = null;
        if (!this.value || this.device.fusion) {
            const euler = this.device.getEulerAngles();
            if (euler) {
                quat = new Quaternion().fromEuler(euler);
                this.value = quat; // Update this.value so other methods can use it
                if (this.histLen > 0) {
                    if (!(this.device.isPlaying && this.device.isPaused)) {
                        this.updateHist(quat, null);
                    }
                }
                // this will be lower fps but forward anyway for compatibility
                const values = [quat];
                this.forward(values);
            }
        } else {
            quat = this.value.copy();
        }
        return quat;
    }

    info() {
        const header = [];
        const fusionText = this.device.fusion ? ` fusion: ${this.device.fusion.type}` : "";
        header.push(`${this.filterType}${fusionText}`);
        return header;
    }
}

export default QuatSensor;