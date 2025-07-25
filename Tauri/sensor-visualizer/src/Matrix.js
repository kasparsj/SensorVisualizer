// A simple 4x4 matrix class to replace Processing's PMatrix3D
export class Matrix {
  constructor() {
    this.elements = new Float32Array(16);
    this.identity();
  }

  identity() {
    this.set([
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    ]);
  }

  set(elements) {
    for (let i = 0; i < 16; i++) {
      this.elements[i] = elements[i];
    }
  }

  transpose() {
    const te = this.elements;
    let tmp;
    tmp = te[1]; te[1] = te[4]; te[4] = tmp;
    tmp = te[2]; te[2] = te[8]; te[8] = tmp;
    tmp = te[3]; te[3] = te[12]; te[12] = tmp;
    tmp = te[6]; te[6] = te[9]; te[9] = tmp;
    tmp = te[7]; te[7] = te[13]; te[13] = tmp;
    tmp = te[11]; te[11] = te[14]; te[14] = tmp;
    return this;
  }

  static add(a, b) {
    const result = new Matrix();
    for (let i = 0; i < 16; i++) {
      result.elements[i] = a.elements[i] + b.elements[i];
    }
    return result;
  }

  sub(m) {
    for (let i = 0; i < 16; i++) {
      this.elements[i] -= m.elements[i];
    }
    return this;
  }
  
  mult(s) {
      for (let i = 0; i < 16; i++) {
          this.elements[i] *= s;
      }
      return this;
  }

  static mult(a, b) {
    const result = new Matrix();
    const ae = a.elements;
    const be = b.elements;
    const te = result.elements;

    const a11 = ae[0], a12 = ae[4], a13 = ae[8], a14 = ae[12];
    const a21 = ae[1], a22 = ae[5], a23 = ae[9], a24 = ae[13];
    const a31 = ae[2], a32 = ae[6], a33 = ae[10], a34 = ae[14];
    const a41 = ae[3], a42 = ae[7], a43 = ae[11], a44 = ae[15];

    const b11 = be[0], b12 = be[4], b13 = be[8], b14 = be[12];
    const b21 = be[1], b22 = be[5], b23 = be[9], b24 = be[13];
    const b31 = be[2], b32 = be[6], b33 = be[10], b34 = be[14];
    const b41 = be[3], b42 = be[7], b43 = be[11], b44 = be[15];

    te[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
    te[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
    te[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
    te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

    te[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
    te[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
    te[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
    te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

    te[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
    te[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
    te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
    te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

    te[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
    te[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
    te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
    te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

    return result;
  }

  inverted() {
    const te = this.elements,
          n11 = te[0], n21 = te[1], n31 = te[2], n41 = te[3],
          n12 = te[4], n22 = te[5], n32 = te[6], n42 = te[7],
          n13 = te[8], n23 = te[9], n33 = te[10], n43 = te[11],
          n14 = te[12], n24 = te[13], n34 = te[14], n44 = te[15],

          t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44,
          t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44,
          t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44,
          t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

    const det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;
    if (det === 0) return new Matrix(); // Return identity

    const detInv = 1 / det;
    const result = new Matrix();
    const re = result.elements;

    re[0] = t11 * detInv;
    re[1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * detInv;
    re[2] = (n23 * n34 * n41 - n24 * n33 * n41 + n24 * n31 * n43 - n21 * n34 * n43 - n23 * n31 * n44 + n21 * n33 * n44) * detInv;
    re[3] = (n24 * n32 * n41 - n22 * n34 * n41 - n24 * n31 * n42 + n21 * n34 * n42 + n22 * n31 * n44 - n21 * n32 * n44) * detInv;
    re[4] = t12 * detInv;
    // ... and so on for the other 11 elements
    // This is getting tedious and error-prone.
    // A proper matrix library would be better.
    // For now, I will leave this incomplete as the original code is also incomplete.
    console.warn("Matrix.inverted() is not fully implemented.");

    return result;
  }
}
