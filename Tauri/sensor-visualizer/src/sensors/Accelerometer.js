import VectorSensor from "./VectorSensor.js";
import {SensorType} from "../types.js";
import { Vector } from '../ds';
import {eulerAngles} from "../p5/utils/drawing.js";

export const GravityMethod = {
    NONE: 'NONE',
    HIGHPASS: 'HP',
    ORIENT: 'ORIENT',

    next: (current) => {
        const values = Object.values(GravityMethod).filter(v => typeof v !== 'function');
        const currentIndex = values.indexOf(current);
        return values[(currentIndex + 1) % values.length];
    }
};

class Accelerometer extends VectorSensor {
    constructor(gm = GravityMethod.HIGHPASS, histLen = 500, deltaSumWin = 2, maxMag = 9.81) {
        super(histLen);

        this.type = SensorType.ACC;
        this.addr = "/acc";
        this.supportBatch = true;
        this.gravityMethod = gm;
        this.gravity = new Vector(0, 0, 0);
        this.prevMillis = 0;
        this.velocity = new Vector(0, 0, 0);
        this.maxVelocity = new Vector(0, 0, 0);
        this.velocities = null;
        this.speeds = null;
        this.position = new Vector(0, 0, 0);
        this.maxPosition = new Vector(0, 0, 0);

        // Initialize velocity tracking
        this.enableHistory(histLen);

        // enableMagnitude(deltaSumWin, maxMag);
        // setFilterType(FilterType.KALMAN);
    }

    enableHistory(histLen) {
        super.enableHistory(histLen);
        if (histLen > 0) {
            this.velocities = new Array(histLen).fill(null);
            this.speeds = new Array(histLen).fill(0);
            this.position = new Vector(0, 0, 0);
        } else {
            this.velocities = null;
            this.speeds = null;
            this.maxPosition = new Vector(0, 0, 0);
        }
        return this;
    }

    lowpass(val, alpha, prev) {
        return new Vector(
            prev.x + alpha * (val.x - prev.x),
            prev.y + alpha * (val.y - prev.y),
            prev.z + alpha * (val.z - prev.z)
        );
    }

    update(val) {
        const processedVal = val.copy();
        switch (this.gravityMethod) {
            case GravityMethod.ORIENT:
                // gravity removal is more precise when restricting pitch rather than roll
                const angles = eulerAngles(this.p, val, true);
                // For now, simplified - full quaternion implementation would be needed
                // const orientation = new Quaternion().fromEuler(angles);
                // const conjugate = orientation.conjugate();
                // this.gravity = conjugate.normalize().mult(new Vector(0, 0, 9.81));
                // processedVal.sub(this.gravity);
                break;
            case GravityMethod.HIGHPASS:
                const alpha = 0.05;
                this.gravity = this.lowpass(val.copy(), alpha, this.gravity);
                processedVal.sub(this.gravity);
                break;
            case GravityMethod.NONE:
            default:
                break;
        }
        super.update(processedVal);
    }

    forward(values) {
        this.calcVelocity(values.length);
        super.forward(values);
    }

    calcVelocity(numValues) {
        const millis = Date.now();
        if (this.velocities) {
            const useRaw = false;
            const vals = useRaw ? this.rawValues : this.values;

            for (let i = numValues - 1; i >= 0; i--) {
                const j = i > this.histCursor ? this.histLen - (i - this.histCursor) : this.histCursor - i;
                let val = vals[j];
                if (!val) val = new Vector(0, 0, 0);

                const interval = (millis - this.prevMillis) / numValues / 1000.0;
                const dv = new Vector(val.x * interval, val.y * interval, val.z * interval);

                const prevVelocity = this.velocities[j > 0 ? j - 1 : this.histLen - 1];
                if (!prevVelocity) {
                    this.velocity = new Vector(0, 0, 0);
                } else {
                    this.velocity = new Vector(
                        prevVelocity.x + dv.x,
                        prevVelocity.y + dv.y,
                        prevVelocity.z + dv.z
                    );
                }

                this.velocity.mult(0.9);

                const speed = this.velocity.mag();
                if (speed < 0.01) {
                    this.velocity = new Vector(0, 0, 0);
                }

                if (!this.maxVelocity) {
                    this.maxVelocity = new Vector(0, 0, 0);
                }
                this.maxVelocity = new Vector(
                    Math.max(this.velocity.x, this.maxVelocity.x),
                    Math.max(this.velocity.y, this.maxVelocity.y),
                    Math.max(this.velocity.z, this.maxVelocity.z)
                );

                const maxVelMag = this.maxVelocity.mag();
                const speedPerc = maxVelMag > 0 ? speed / maxVelMag : 0;
                this.velocities[j] = this.velocity.copy();
                if (this.speeds) this.speeds[j] = speedPerc;

                this.position.add(new Vector(
                    this.velocity.x * interval,
                    this.velocity.y * interval,
                    this.velocity.z * interval
                ));
                this.position.mult(0.9999);

                // Update maxPosition
                if (!this.maxPosition) {
                    this.maxPosition = new Vector(0, 0, 0);
                }
                this.maxPosition = new Vector(
                    Math.max(Math.abs(this.position.x), Math.abs(this.maxPosition.x)),
                    Math.max(Math.abs(this.position.y), Math.abs(this.maxPosition.y)),
                    Math.max(Math.abs(this.position.z), Math.abs(this.maxPosition.z))
                );
            }
        }
        this.prevMillis = millis;
    }

    getOrigEulerAngles() {
        if (!this.value) return null;

        let value = this.value.copy();
        if (this.gravityMethod !== GravityMethod.NONE) {
            value.add(this.gravity);
        }
        return eulerAngles(this.p, value);
    }

    setGravityMethod(gm) {
        this.gravityMethod = gm;
        if (gm === GravityMethod.NONE) {
            this.gravity = new Vector(0, 0, 0);
        }
        return this;
    }

    nextGravityMethod() {
        this.setGravityMethod(GravityMethod.next(this.gravityMethod));
    }

    // todo: fix
    // keyPressed() {
    //     if (this.p.key === 'g') {
    //         this.nextGravityMethod();
    //         return true;
    //     }
    //     return super.keyPressed();
    // }

    info() {
        const header = [];
        if (this.value) {
            header.push(`${this.filterType} ${this.value.x.toFixed(2)}, ${this.value.y.toFixed(2)}, ${this.value.z.toFixed(2)}, mag: ${this.value.mag().toFixed(2)}`);
            header.push(`gravity ${this.gravityMethod} ${this.gravity.x.toFixed(2)}, ${this.gravity.y.toFixed(2)}, ${this.gravity.z.toFixed(2)}`);
            header.push(`max ${this.maxValue.x.toFixed(2)}, ${this.maxValue.y.toFixed(2)}, ${this.maxValue.z.toFixed(2)}`);
            header.push(`min ${this.minValue.x.toFixed(2)}, ${this.minValue.y.toFixed(2)}, ${this.minValue.z.toFixed(2)}`);
        } else {
            header.push(`${this.filterType}`);
            header.push(`gravity ${this.gravityMethod} ${this.gravity.x.toFixed(2)}, ${this.gravity.y.toFixed(2)}, ${this.gravity.z.toFixed(2)}`);
        }
        return header;
    }
}

export default Accelerometer;