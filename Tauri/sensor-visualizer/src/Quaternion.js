import p5 from 'p5';

export class Quaternion {
  constructor(w = 1, x = 0, y = 0, z = 0) {
    this.w = w;
    this.x = x;
    this.y = y;
    this.z = z;
  }

  copy() {
    return new Quaternion(this.w, this.x, this.y, this.z);
  }

  inverse() {
    const norm = this.dot();
    if (norm > 0.0) {
      const invNorm = 1.0 / norm;
      return new Quaternion(this.w * invNorm, -this.x * invNorm, -this.y * invNorm, -this.z * invNorm);
    }
    return null;
  }

  difference(q) {
    const inv = this.inverse();
    if (inv) {
      return inv.mult(q);
    }
    return null;
  }

  equals(q) {
    return this.x === q.x && this.y === q.y && this.z === q.z && this.w === q.w;
  }

  dot(q = this) {
    return this.w * q.w + this.x * q.x + this.y * q.y + this.z * q.z;
  }

  angle() {
    return 2 * Math.atan2(this.toPVector().mag(), this.w);
  }

  set(w, x, y, z) {
    this.w = w;
    this.x = x;
    this.y = y;
    this.z = z;
  }

  setAngleAxis(angle, axis) {
    axis.normalize();
    const hcos = Math.cos(angle / 2);
    const hsin = Math.sin(angle / 2);
    this.w = hcos;
    this.x = axis.x * hsin;
    this.y = axis.y * hsin;
    this.z = axis.z * hsin;
  }

  conjugate() {
    return new Quaternion(this.w, -this.x, -this.y, -this.z);
  }

  add(q) {
    this.w += q.w;
    this.x += q.x;
    this.y += q.y;
    this.z += q.z;
    return this;
  }

  sub(q) {
    this.w -= q.w;
    this.x -= q.x;
    this.y -= q.y;
    this.z -= q.z;
    return this;
  }

  mult(r) {
    if (r instanceof Quaternion) {
      const w = this.w, x = this.x, y = this.y, z = this.z;
      const newW = r.w * w - r.x * x - r.y * y - r.z * z;
      const newX = r.w * x + r.x * w + r.y * z - r.z * y;
      const newY = r.w * y - r.x * z + r.y * w + r.z * x;
      const newZ = r.w * z + r.x * y - r.y * x + r.z * w;
      return new Quaternion(newW, newX, newY, newZ);
    } else {
      return new Quaternion(this.w * r, this.x * r, this.y * r, this.z * r);
    }
  }

  multVec(v) {
    const px = (1 - 2 * this.y * this.y - 2 * this.z * this.z) * v.x +
               (2 * this.x * this.y - 2 * this.z * this.w) * v.y +
               (2 * this.x * this.z + 2 * this.y * this.w) * v.z;

    const py = (2 * this.x * this.y + 2 * this.z * this.w) * v.x +
               (1 - 2 * this.x * this.x - 2 * this.z * this.z) * v.y +
               (2 * this.y * this.z - 2 * this.x * this.w) * v.z;

    const pz = (2 * this.x * this.z - 2 * this.y * this.w) * v.x +
               (2 * this.y * this.z + 2 * this.x * this.w) * v.y +
               (1 - 2 * this.x * this.x - 2 * this.y * this.y) * v.z;
    return new p5.Vector(px, py, pz);
  }

  normalize() {
    let mag = this.dot();
    if (mag !== 0.0 && mag !== 1.0) {
      mag = 1.0 / Math.sqrt(mag);
      this.x *= mag;
      this.y *= mag;
      this.z *= mag;
      this.w *= mag;
    }
    return this;
  }

  fromEuler(euler) {
    const cosR = Math.cos(euler.x / 2.0);
    const sinR = Math.sin(euler.x / 2.0);
    const cosP = Math.cos(euler.y / 2.0);
    const sinP = Math.sin(euler.y / 2.0);
    const cosY = Math.cos(euler.z / 2.0);
    const sinY = Math.sin(euler.z / 2.0);

    this.w = cosR * cosP * cosY + sinR * sinP * sinY;
    this.x = sinR * cosP * cosY - cosR * sinP * sinY;
    this.y = cosR * sinP * cosY + sinR * cosP * sinY;
    this.z = cosR * cosP * sinY - sinR * sinP * cosY;

    return this;
  }

  toEuler() {
    const euler = new p5.Vector();
    const sinr_cosp = 2.0 * (this.w * this.x + this.y * this.z);
    const cosr_cosp = 1.0 - 2.0 * (this.x * this.x + this.y * this.y);
    euler.x = Math.atan2(sinr_cosp, cosr_cosp);

    const sinp = 2.0 * (this.w * this.y - this.z * this.x);
    if (Math.abs(sinp) >= 1)
      euler.y = Math.sign(sinp) * Math.PI / 2;
    else
      euler.y = Math.asin(sinp);

    const siny_cosp = 2.0 * (this.w * this.z + this.x * this.y);
    const cosy_cosp = 1.0 - 2.0 * (this.y * this.y + this.z * this.z);
    euler.z = Math.atan2(siny_cosp, cosy_cosp);

    return euler;
  }

  toPVector() {
    return new p5.Vector(this.x, this.y, this.z);
  }
  
  projXZ() {
    const rot = this.multVec(new p5.Vector(0.0, 1.0, 0.0));
    return new p5.Vector(rot.x, rot.z);
  }

  projYX() {
    const rot = this.multVec(new p5.Vector(1.0, 0.0, 0.0));
    return new p5.Vector(rot.y, rot.x);
  }

  projZY() {
    const rot = this.multVec(new p5.Vector(0.0, 0.0, 1.0));
    return new p5.Vector(rot.z, rot.y);
  }

  toMatrix() {
    const x = this.x, y = this.y, z = this.z, w = this.w;
    const x2 = x + x, y2 = y + y, z2 = z + z;
    const xx = x * x2, xy = x * y2, xz = x * z2;
    const yy = y * y2, yz = y * z2, zz = z * z2;
    const wx = w * x2, wy = w * y2, wz = w * z2;

    return [
      1 - (yy + zz), xy + wz, xz - wy, 0,
      xy - wz, 1 - (xx + zz), yz + wx, 0,
      xz + wy, yz - wx, 1 - (xx + yy), 0,
      0, 0, 0, 1
    ];
  }
}
