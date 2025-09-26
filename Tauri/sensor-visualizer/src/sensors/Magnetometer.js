import VectorSensor from "./VectorSensor.js";
import {SensorType} from "../types.js";

class Magnetometer extends VectorSensor {
    constructor(histLen = 500, deltaSumWin = 2) {
        super(histLen);

        this.type = SensorType.MAG;
        this.addr = "/mag";
        // this.enableMagnitude(deltaSumWin);
    }

    computeCompassHeading(mag) {
        let heading;
        if (mag.y === 0) {
            heading = (mag.x < 0) ? Math.PI : 0;
        } else {
            heading = Math.atan2(mag.x, mag.y);
        }

        if (heading > Math.PI) heading -= (2 * Math.PI);
        else if (heading < -Math.PI) heading += (2 * Math.PI);
        else if (heading < 0) heading += 2 * Math.PI;

        return heading;
    }
}

export default Magnetometer;