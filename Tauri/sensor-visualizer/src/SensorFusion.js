import p5 from 'p5';
import { Quaternion } from './Quaternion.js';

const FusionType = Object.freeze({
  NONE: "NONE",
  MAHONY: "MAHONY",
  MADGWICK: "MADGWICK",
  KALMAN: "KALMAN",
  next: (current) => {
    const values = Object.values(FusionType).filter(v => typeof v !== 'function');
    const currentIndex = values.indexOf(current);
    return values[(currentIndex + 1) % values.length];
  }
});

class SensorFusion {
  constructor(device) {
    this.device = device;
    this.type = null; // Set by subclass
    this.measuredPose = new p5.Vector();
    this.fusionPose = new p5.Vector();
    this.measuredQPose = new Quaternion();
    this.fusionQPose = new Quaternion();
  }

  calculatePose() {
    const m = new Quaternion();
    const q = new Quaternion();

    const eulerDisplay = this.device.getEuler();
    const accDisplay = this.device.getAccelerometer();

    if (eulerDisplay && eulerDisplay.value) {
      this.measuredPose = eulerDisplay.val();
    } else if (accDisplay) {
      this.measuredPose = accDisplay.getOrigEulerAngles();
    }

    if (!this.measuredPose) {
      this.measuredPose = this.fusionPose.copy();
      this.measuredPose.z = 0;
    }

    const magDisplay = this.device.getMagnetometer();
    if (magDisplay && magDisplay.val()) {
      const magValue = magDisplay.val();
      q.fromEuler(this.measuredPose);
      
      let m = new Quaternion(0, magValue.x, magValue.y, magValue.z);
      
      // m = q.mult(m).mult(q.conjugate());
      let q_m = q.mult(m);
      let q_m_qinv = q_m.mult(q.conjugate());
      m = q_m_qinv;

      this.measuredPose.z = -Math.atan2(m.y, m.x) - magDisplay.magDeclination;
    } else {
      this.measuredPose.z = this.fusionPose.z;
    }

    this.measuredQPose.fromEuler(this.measuredPose);

    // Check for quaternion aliasing
    let maxIndex = -1;
    let maxVal = -10000;
    const measuredQArray = [this.measuredQPose.w, this.measuredQPose.x, this.measuredQPose.y, this.measuredQPose.z];

    for (let i = 0; i < 4; i++) {
      if (Math.abs(measuredQArray[i]) > maxVal) {
        maxVal = Math.abs(measuredQArray[i]);
        maxIndex = i;
      }
    }

    const fusionQArray = [this.fusionQPose.w, this.fusionQPose.x, this.fusionQPose.y, this.fusionQPose.z];
    if (((measuredQArray[maxIndex] < 0) && (fusionQArray[maxIndex] > 0)) ||
        ((measuredQArray[maxIndex] > 0) && (fusionQArray[maxIndex] < 0))) {
      this.measuredQPose.w = -this.measuredQPose.w;
      this.measuredQPose.x = -this.measuredQPose.x;
      this.measuredQPose.y = -this.measuredQPose.y;
      this.measuredQPose.z = -this.measuredQPose.z;
      this.measuredPose = this.measuredQPose.toEuler();
    }
  }

  getEulerAngles() {
    throw new Error("Method 'getEulerAngles()' must be implemented.");
  }
}

export { SensorFusion, FusionType };
