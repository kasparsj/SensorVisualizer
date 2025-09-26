import VectorSensor from "./VectorSensor.js";
import {SensorType} from "../types.js";

class EulerSensor extends VectorSensor {
    constructor(histLen = 500, glPrevent = false) {
        super(histLen);

        this.type = SensorType.EULER;
        this.addr = "/euler";
        this.supportBatch = true;
        this.glPrevent = glPrevent;
        this.glAngle = 65;
    }

    preventGimbalLock(val) {
        if (this.glPrevent) {
            // To be implemented
        }
    }

    update(val) {
        this.preventGimbalLock(val);
        super.update(val);
    }
}

export default EulerSensor;