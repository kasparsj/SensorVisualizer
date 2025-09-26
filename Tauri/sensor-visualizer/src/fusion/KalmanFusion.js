import { Vector, Quaternion, Matrix } from '../ds';
import { SensorFusion, FusionType } from './SensorFusion.js';

const KALMAN_QVALUE = 0.001;
const KALMAN_RVALUE = 0.0005;

class KalmanFusion extends SensorFusion {
  constructor(device) {
    super(device);
    this.type = FusionType.KALMAN;
    this.firstTime = true;
    this.lastFusionTime = 0;
    this.timeDelta = 0;
    this.stateQ = new Quaternion();
    this.stateQError = new Quaternion();
    this.debug = true;

    this.m_Kk = new Matrix();
    this.m_Pkk_1 = new Matrix();
    this.m_Pkk = new Matrix();
    this.m_PDot = new Matrix();
    this.m_Q = new Matrix();
    this.m_Fk = new Matrix();
    this.m_FkTranspose = new Matrix();
    this.m_Rk = new Matrix();

    const qValues = new Array(16).fill(KALMAN_QVALUE);
    this.m_Q.set(qValues);

    const rValues = new Array(16).fill(KALMAN_RVALUE);
    this.m_Rk.set(rValues);
  }

  predict() {
    let gyroVal = this.device.hasGyroscope() ? this.device.getGyroscope().val() : new Vector(0, 0, 0);
    if (!gyroVal) {
      gyroVal = new Vector(0, 0, 0);
    }

    const x2 = gyroVal.x / 2.0;
    const y2 = gyroVal.y / 2.0;
    const z2 = gyroVal.z / 2.0;

    const fk_elements = this.m_Fk.elements;
    this.m_Fk.set([
      fk_elements[0], -x2, -y2, -z2,
      x2, fk_elements[5], z2, -y2,
      y2, -z2, fk_elements[10], x2,
      z2, y2, -x2, fk_elements[15]
    ]);

    this.m_FkTranspose = new Matrix();
    this.m_FkTranspose.set(this.m_Fk.elements);
    this.m_FkTranspose.transpose();

    // todo: fix
    /*
    // Predict new state estimate Xkk_1 = Fk * Xk_1k_1
    let tQuat = Matrix.mult(this.m_Fk, this.stateQ); // This is not correct matrix * quaternion
    tQuat.mult(this.timeDelta);
    this.stateQ.add(tQuat);

    // Compute PDot = Fk * Pk_1k_1 + Pk_1k_1 * FkTranspose (note Pkk == Pk_1k_1 at this stage)
    this.m_PDot = Matrix.mult(this.m_Fk, this.m_Pkk);
    let mat = Matrix.mult(this.m_Pkk, this.m_FkTranspose);
    this.m_PDot.add(mat);

    // add in Q to get the new prediction
    this.m_Pkk_1 = Matrix.add(this.m_PDot, this.m_Q);

    //  multiply by deltaTime (variable name is now misleading though)
    this.m_Pkk_1.mult(this.timeDelta);
    */
  }

  update() {
    if (this.device.hasMagnetometer() || this.device.hasAccelerometer()) {
      this.stateQError = this.measuredQPose.difference(this.stateQ);
    } else {
      this.stateQError = new Quaternion();
    }

    // todo: fix
    /*
    //  Compute residual covariance Sk = Hk * Pkk_1 * HkTranspose + Rk
    //  Note: since Hk is the identity matrix, this has been simplified
    let Sk = Matrix.add(this.m_Pkk_1, this.m_Rk);

    //  Compute Kalman gain Kk = Pkk_1 * HkTranspose * SkInverse
    //  Note: again, the HkTranspose part is omitted
    let SkInverse = Sk.inverted();
    this.m_Kk = Matrix.mult(this.m_Pkk_1, SkInverse);

    // make new state estimate
    let delta = Matrix.mult(this.m_Kk, this.stateQError); // This is not correct matrix * quaternion
    this.stateQ.add(delta);
    this.stateQ.normalize();

    //  produce new estimate covariance Pkk = (I - Kk * Hk) * Pkk_1
    //  Note: since Hk is the identity matrix, it is omitted
    this.m_Pkk.identity();
    this.m_Pkk.sub(this.m_Kk);
    this.m_Pkk = Matrix.mult(this.m_Pkk, this.m_Pkk_1);
    */
  }

  getEulerAngles() {
    if (true) {
      if (this.firstTime) {
        console.log("Kalman Fusion implementation incomplete/disabled");
        this.firstTime = false;
      }
      return new Vector();
    }

    if (this.firstTime) {
      this.lastFusionTime = Date.now();
      this.calculatePose();
      
      const zeros = new Array(16).fill(0);
      this.m_Fk.set(zeros);

      const pkk_init = new Array(16).fill(0.5);
      this.m_Pkk.set(pkk_init);

      this.stateQ.fromEuler(this.measuredPose);
      this.fusionQPose = this.stateQ.copy();
      this.fusionPose = this.measuredPose.copy();
      this.firstTime = false;
    } else {
      const now = Date.now();
      this.timeDelta = now - this.lastFusionTime;
      this.lastFusionTime = now;
      if (this.timeDelta <= 0) {
        return this.fusionPose;
      }

      if (this.debug) {
        console.log("\n------\n");
        console.log("IMU update delta time: " + this.timeDelta);
      }
      this.calculatePose();
      this.predict();
      this.update();
      this.fusionPose = this.stateQ.toEuler();
      this.fusionQPose = this.stateQ.copy();
      if (this.debug) {
        console.log("Measured pose", this.measuredPose);
        console.log("Kalman pose", this.fusionPose);
        console.log("Measured quat", this.measuredQPose);
        console.log("Kalman quat", this.stateQ);
        console.log("Error quat", this.stateQError);
      }
    }
    return this.fusionPose;
  }
}

export default KalmanFusion;