import p5 from 'p5';
import { SensorFusion, FusionType } from './SensorFusion.js';

export class MadgwickFusion extends SensorFusion {
  constructor(device) {
    super(device);
    this.type = FusionType.MADGWICK;
    this.beta = 0.1; // 2 * proportional gain

    this.q0 = 1.0;
    this.q1 = 0.0;
    this.q2 = 0.0;
    this.q3 = 0.0;

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
    let s0, s1, s2, s3;
    let qDot1, qDot2, qDot3, qDot4;

    const now = Date.now();
    const deltat = this.lastUpdate ? (now - this.lastUpdate) / 1000.0 : 0.0;
    this.lastUpdate = now;

    const acc = this.device.getAccelerometer().val();
    const gyro = this.device.getGyroscope().val();

    qDot1 = 0.5 * (-this.q1 * gyro.x - this.q2 * gyro.y - this.q3 * gyro.z);
    qDot2 = 0.5 * (this.q0 * gyro.x + this.q2 * gyro.z - this.q3 * gyro.y);
    qDot3 = 0.5 * (this.q0 * gyro.y - this.q1 * gyro.z + this.q3 * gyro.x);
    qDot4 = 0.5 * (this.q0 * gyro.z + this.q1 * gyro.y - this.q2 * gyro.x);

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

        const _2q0mx = 2.0 * this.q0 * mag.x;
        const _2q0my = 2.0 * this.q0 * mag.y;
        const _2q0mz = 2.0 * this.q0 * mag.z;
        const _2q1mx = 2.0 * this.q1 * mag.x;
        const _2q0 = 2.0 * this.q0;
        const _2q1 = 2.0 * this.q1;
        const _2q2 = 2.0 * this.q2;
        const _2q3 = 2.0 * this.q3;
        const _2q0q2 = 2.0 * this.q0 * this.q2;
        const _2q2q3 = 2.0 * this.q2 * this.q3;
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

        const hx = mag.x * q0q0 - _2q0my * this.q3 + _2q0mz * this.q2 + mag.x * q1q1 + _2q1 * mag.y * this.q2 + _2q1 * mag.z * this.q3 - mag.x * q2q2 - mag.x * q3q3;
        const hy = _2q0mx * this.q3 + mag.y * q0q0 - _2q0mz * this.q1 + _2q1mx * this.q2 - mag.y * q1q1 + mag.y * q2q2 + _2q2 * mag.z * this.q3 - mag.y * q3q3;
        const _2bx = Math.sqrt(hx * hx + hy * hy);
        const _2bz = -_2q0mx * this.q2 + _2q0my * this.q1 + mag.z * q0q0 + _2q1mx * this.q3 - mag.z * q1q1 + _2q2 * mag.y * this.q3 - mag.z * q2q2 + mag.z * q3q3;
        const _4bx = 2.0 * _2bx;
        const _4bz = 2.0 * _2bz;

        s0 = -_2q2 * (2.0 * q1q3 - _2q0q2 - acc.x) + _2q1 * (2.0 * q0q1 + _2q2q3 - acc.y) - _2bz * this.q2 * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mag.x) + (-_2bx * this.q3 + _2bz * this.q1) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - mag.y) + _2bx * this.q2 * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mag.z);
        s1 = _2q3 * (2.0 * q1q3 - _2q0q2 - acc.x) + _2q0 * (2.0 * q0q1 + _2q2q3 - acc.y) - 4.0 * this.q1 * (1 - 2.0 * q1q1 - 2.0 * q2q2 - acc.z) + _2bz * this.q3 * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mag.x) + (_2bx * this.q2 + _2bz * this.q0) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - mag.y) + (_2bx * this.q3 - _4bz * this.q1) * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mag.z);
        s2 = -_2q0 * (2.0 * q1q3 - _2q0q2 - acc.x) + _2q3 * (2.0 * q0q1 + _2q2q3 - acc.y) - 4.0 * this.q2 * (1 - 2.0 * q1q1 - 2.0 * q2q2 - acc.z) + (-_4bx * this.q2 - _2bz * this.q0) * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mag.x) + (_2bx * this.q1 + _2bz * this.q3) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - mag.y) + (_2bx * this.q0 - _4bz * this.q2) * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mag.z);
        s3 = _2q1 * (2.0 * q1q3 - _2q0q2 - acc.x) + _2q2 * (2.0 * q0q1 + _2q2q3 - acc.y) + (-_4bx * this.q3 + _2bz * this.q1) * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mag.x) + (-_2bx * this.q0 + _2bz * this.q2) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - mag.y) + _2bx * this.q1 * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mag.z);
      } else {
        const _2q0 = 2.0 * this.q0;
        const _2q1 = 2.0 * this.q1;
        const _2q2 = 2.0 * this.q2;
        const _2q3 = 2.0 * this.q3;
        const _4q0 = 4.0 * this.q0;
        const _4q1 = 4.0 * this.q1;
        const _4q2 = 4.0 * this.q2;
        const _8q1 = 8.0 * this.q1;
        const _8q2 = 8.0 * this.q2;
        const q0q0 = this.q0 * this.q0;
        const q1q1 = this.q1 * this.q1;
        const q2q2 = this.q2 * this.q2;
        const q3q3 = this.q3 * this.q3;

        s0 = _4q0 * q2q2 + _2q2 * acc.x + _4q0 * q1q1 - _2q1 * acc.y;
        s1 = _4q1 * q3q3 - _2q3 * acc.x + 4.0 * q0q0 * this.q1 - _2q0 * acc.y - _4q1 + _8q1 * q1q1 + _8q1 * q2q2 + _4q1 * acc.z;
        s2 = 4.0 * q0q0 * this.q2 + _2q0 * acc.x + _4q2 * q3q3 - _2q3 * acc.y - _4q2 + _8q2 * q1q1 + _8q2 * q2q2 + _4q2 * acc.z;
        s3 = 4.0 * q1q1 * this.q3 - _2q1 * acc.x + 4.0 * q2q2 * this.q3 - _2q2 * acc.y;
      }

      recipNorm = this.invSqrt(s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3);
      s0 *= recipNorm;
      s1 *= recipNorm;
      s2 *= recipNorm;
      s3 *= recipNorm;

      qDot1 -= this.beta * s0;
      qDot2 -= this.beta * s1;
      qDot3 -= this.beta * s2;
      qDot4 -= this.beta * s3;
    }

    this.q0 += qDot1 * deltat;
    this.q1 += qDot2 * deltat;
    this.q2 += qDot3 * deltat;
    this.q3 += qDot4 * deltat;

    recipNorm = this.invSqrt(this.q0 * this.q0 + this.q1 * this.q1 + this.q2 * this.q2 + this.q3 * this.q3);
    this.q0 *= recipNorm;
    this.q1 *= recipNorm;
    this.q2 *= recipNorm;
    this.q3 *= recipNorm;

    const roll = Math.atan2(this.q0 * this.q1 + this.q2 * this.q3, 0.5 - this.q1 * this.q1 - this.q2 * this.q2);
    const pitch = Math.asin(-2.0 * (this.q1 * this.q3 - this.q0 * this.q2));
    const yaw = Math.atan2(this.q1 * this.q2 + this.q0 * this.q3, 0.5 - this.q2 * this.q2 - this.q3 * this.q3);

    return new p5.Vector(roll, pitch, yaw);
  }
}
