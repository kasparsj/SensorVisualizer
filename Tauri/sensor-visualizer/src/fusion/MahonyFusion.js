import { Vector } from '../ds';
import { SensorFusion, FusionType } from './SensorFusion.js';

class MahonyFusion extends SensorFusion {
  constructor(device) {
    super(device);
    this.type = FusionType.MAHONY;

    this.twoKpDef = 2.0 * 0.5; // 2 * proportional gain
    this.twoKiDef = 2.0 * 0.0; // 2 * integral gain

    this.twoKp = this.twoKpDef;
    this.twoKi = this.twoKiDef;
    
    this.q0 = 1.0;
    this.q1 = 0.0;
    this.q2 = 0.0;
    this.q3 = 0.0;
    
    this.integralFBx = 0.0;
    this.integralFBy = 0.0;
    this.integralFBz = 0.0;

    this.lastUpdate = 0;
  }

  invSqrt(x) {
    const buf = new ArrayBuffer(4);
    const f32 = new Float32Array(buf);
    const i32 = new Int32Array(buf);
    f32[0] = x;
    let i = i32[0];
    i = 0x5f3759df - (i >> 1);
    i32[0] = i;
    let y = f32[0];
    y = y * (1.5 - (x * 0.5 * y * y));
    return y;
  }

  getEulerAngles() {
    let recipNorm;
    let halfvx, halfvy, halfvz;
    let halfex, halfey, halfez;
    let qa, qb, qc;

    const now = Date.now();
    const deltat = this.lastUpdate ? (now - this.lastUpdate) / 1000.0 : 0.0;
    this.lastUpdate = now;

    const acc = this.device.getAccelerometer().val();
    const gyro = this.device.getGyroscope().val();

    if (acc.x !== 0 || acc.y !== 0 || acc.z !== 0) {
      recipNorm = this.invSqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z);
      acc.x *= recipNorm;
      acc.y *= recipNorm;
      acc.z *= recipNorm;

      const mag = this.device.getMagnetometer() ? this.device.getMagnetometer().val() : null;

      if (mag && (mag.x !== 0 || mag.y !== 0 || mag.z !== 0)) {
        recipNorm = this.invSqrt(mag.x * mag.x + mag.y * mag.y + mag.z * mag.z);
        mag.x *= recipNorm;
        mag.y *= recipNorm;
        mag.z *= recipNorm;

        const q0q0 = this.q0 * this.q0;
        const q0q1 = this.q0 * this.q1;
        const q0q2 = this.q0 * this.q2;
        const q0q3 = this.q0 * this.q3;
        const q1q1 = this.q1 * this.q1;
        const q1q2 = this.q1 * this.q2;
        const q1q3 = this.q1 * this.q3;
        const q2q2 = this.q2 * this.q2;
        const q2q3 = this.q2 * this.q3;
        const q3q3 = this.q3 * this.q3;

        const hx = 2.0 * (mag.x * (0.5 - q2q2 - q3q3) + mag.y * (q1q2 - q0q3) + mag.z * (q1q3 + q0q2));
        const hy = 2.0 * (mag.x * (q1q2 + q0q3) + mag.y * (0.5 - q1q1 - q3q3) + mag.z * (q2q3 - q0q1));
        const bx = Math.sqrt(hx * hx + hy * hy);
        const bz = 2.0 * (mag.x * (q1q3 - q0q2) + mag.y * (q2q3 + q0q1) + mag.z * (0.5 - q1q1 - q2q2));

        halfvx = q1q3 - q0q2;
        halfvy = q0q1 + q2q3;
        halfvz = q0q0 - 0.5 + q3q3;
        const halfwx = bx * (0.5 - q2q2 - q3q3) + bz * (q1q3 - q0q2);
        const halfwy = bx * (q1q2 - q0q3) + bz * (q0q1 + q2q3);
        const halfwz = bx * (q0q2 + q1q3) + bz * (0.5 - q1q1 - q2q2);

        halfex = (acc.y * halfvz - acc.z * halfvy) + (mag.y * halfwz - mag.z * halfwy);
        halfey = (acc.z * halfvx - acc.x * halfvz) + (mag.z * halfwx - mag.x * halfwz);
        halfez = (acc.x * halfvy - acc.y * halfvx) + (mag.x * halfwy - mag.y * halfwx);
      } else {
        halfvx = this.q1 * this.q3 - this.q0 * this.q2;
        halfvy = this.q0 * this.q1 + this.q2 * this.q3;
        halfvz = this.q0 * this.q0 - 0.5 + this.q3 * this.q3;

        halfex = (acc.y * halfvz - acc.z * halfvy);
        halfey = (acc.z * halfvx - acc.x * halfvz);
        halfez = (acc.x * halfvy - acc.y * halfvx);
      }

      if (this.twoKi > 0.0) {
        this.integralFBx += this.twoKi * halfex * deltat;
        this.integralFBy += this.twoKi * halfey * deltat;
        this.integralFBz += this.twoKi * halfez * deltat;
        gyro.x += this.integralFBx;
        gyro.y += this.integralFBy;
        gyro.z += this.integralFBz;
      } else {
        this.integralFBx = 0.0;
        this.integralFBy = 0.0;
        this.integralFBz = 0.0;
      }

      gyro.x += this.twoKp * halfex;
      gyro.y += this.twoKp * halfey;
      gyro.z += this.twoKp * halfez;
    }

    gyro.x *= (0.5 * deltat);
    gyro.y *= (0.5 * deltat);
    gyro.z *= (0.5 * deltat);

    qa = this.q0;
    qb = this.q1;
    qc = this.q2;
    this.q0 += (-qb * gyro.x - qc * gyro.y - this.q3 * gyro.z);
    this.q1 += (qa * gyro.x + qc * gyro.z - this.q3 * gyro.y);
    this.q2 += (qa * gyro.y - qb * gyro.z + this.q3 * gyro.x);
    this.q3 += (qa * gyro.z + qb * gyro.y - qc * gyro.x);

    recipNorm = this.invSqrt(this.q0 * this.q0 + this.q1 * this.q1 + this.q2 * this.q2 + this.q3 * this.q3);
    this.q0 *= recipNorm;
    this.q1 *= recipNorm;
    this.q2 *= recipNorm;
    this.q3 *= recipNorm;

    const roll = Math.atan2(this.q0 * this.q1 + this.q2 * this.q3, 0.5 - this.q1 * this.q1 - this.q2 * this.q2);
    const pitch = Math.asin(-2.0 * (this.q1 * this.q3 - this.q0 * this.q2));
    const yaw = Math.atan2(this.q1 * this.q2 + this.q0 * this.q3, 0.5 - this.q2 * this.q2 - this.q3 * this.q3);

    return new Vector(roll, pitch, yaw);
  }
}

export default MahonyFusion;