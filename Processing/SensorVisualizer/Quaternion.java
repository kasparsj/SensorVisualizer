import processing.core.PVector;

// https://github.com/kynd/PQuaternion
// https://behreajj.medium.com/3d-rotations-in-processing-vectors-matrices-quaternions-10e2fed5f0a3
public class Quaternion
{  
  public float x, y, z, w;

  public Quaternion() {
      x = y = z = 0;
      w = 1;
  }
  
  public Quaternion(float _x, float _y, float _z, float _w) {
      x = _x;
      y = _y;
      z = _z;
      w = _w;
  }
  
  public Quaternion(float angle, PVector axis) {
      setAngleAxis(angle, axis);
  }
  
  public Quaternion(Quaternion q) {
    this(q.x, q.y, q.z, q.w);
  }
  
  public Quaternion copy() {
      return new Quaternion(x, y, z, w);
  }
  
  public Quaternion preventFlip(Quaternion prev) {
      double dotProduct = dot(prev);
      if (dotProduct < 0.0) {
          x = -x;
          y = -y;
          z = -z;
          w = -w;
      }
      return this;
  }
  
  public Quaternion inverse() {
    float norm = dot();
    if (norm > 0.0) {
      float invNorm = 1.0f / norm;
      return new Quaternion(-x * invNorm, -y * invNorm, -z * invNorm, w * invNorm);
    }
    return null;
  }
  
  public Quaternion difference(Quaternion q) {
    Quaternion inv = inverse();
    if (inv != null) {
      return inv.mult(q);
    }
    return null;
  }
  
  public Boolean equals(Quaternion q) {
      return x == q.x && y == q.y && z == q.z && w == q.w;
  }
  
  public float dot(Quaternion q) {
      return w * q.w + x * q.x + y * q.y + z * q.z;
  }
  
  public float dot() {
    return dot(this);
  }
  
  public float angle() {
    return 2 * (float) Math.atan2(toPVector().mag(), w);
  }
  
  public void set(float _x, float _y, float _z, float _w) {
      x = _x;
      y = _y;
      z = _z;
      w = _w;
  }
  
  public void setAngleAxis(float angle, PVector axis) {
      axis.normalize();
      float hcos = (float) Math.cos(angle / 2);
      float hsin = (float) Math.sin(angle / 2);
      w = hcos;
      x = axis.x * hsin;
      y = axis.y * hsin;
      z = axis.z * hsin;
  }
  
  public Quaternion conjugate() {
    Quaternion ret = new Quaternion();
    ret.x = -x;
    ret.y = -y;
    ret.z = -z;
    ret.w = w;
    return ret;
  }
  
  public static Quaternion add(Quaternion left, Quaternion right) {
    Quaternion ret = new Quaternion(left);
    return ret.add(right);
  }
  
  public static Quaternion sub(Quaternion left, Quaternion right) {
    Quaternion ret = new Quaternion(left);
    return ret.sub(right);
  }
  
  public static Quaternion mult(Quaternion left, float right) {
    Quaternion ret = new Quaternion(left);
    return ret.mult(right);
  }
  
  public static Quaternion mult(Quaternion left, Quaternion right) {
    Quaternion ret = new Quaternion(left);
    return ret.mult(right);
  }
  
  public Quaternion add(Quaternion q) {
    w += q.w;
    x += q.x;
    y += q.y;
    z += q.z;
    return this;
  }
  
  public Quaternion sub(Quaternion q) {
    w -= q.w;
    x -= q.x;
    y -= q.y;
    z -= q.z;
    return this;
  }
  
  public Quaternion mult(float r) {
    x = x * r;
    y = y * r;
    z = z * r;
    w = w * r;
    return this;
  }
  
  public Quaternion mult(Quaternion q) {
    x = q.w*x + q.x*w + q.y*z - q.z*y;
    y = q.w*y - q.x*z + q.y*w + q.z*x;
    z = q.w*z + q.x*y - q.y*x + q.z*w;
    w = q.w*w - q.x*x - q.y*y - q.z*z;
    return this;
  }
  
  
  public PVector mult(PVector v) {
    float px = (1 - 2 * y * y - 2 * z * z) * v.x +
               (2 * x * y - 2 * z * w) * v.y +
               (2 * x * z + 2 * y * w) * v.z;
               
    float py = (2 * x * y + 2 * z * w) * v.x +
               (1 - 2 * x * x - 2 * z * z) * v.y +
               (2 * y * z - 2 * x * w) * v.z;
               
    float pz = (2 * x * z - 2 * y * w) * v.x +
               (2 * y * z + 2 * x * w) * v.y +
               (1 - 2 * x * x - 2 * y * y) * v.z;
    return new PVector(px, py, pz);
  }
  
  public Quaternion normalize() {
    float mag = x * x + y * y + z * z + w * w;
    if (mag != 0.0 && mag != 1.0) {
      mag = 1.0F / ((float) Math.sqrt(mag));
      x *= mag; y *= mag; z *= mag; w *= mag;
    }
    return this;
  }
  
  public Quaternion fromEuler(PVector euler) {
    float cosR = (float) Math.cos(euler.x / 2.0f);
    float sinR = (float) Math.sin(euler.x / 2.0f);
    float cosP = (float) Math.cos(euler.y / 2.0f);
    float sinP = (float) Math.sin(euler.y / 2.0f);
    float cosY = (float) Math.cos(euler.z / 2.0f);
    float sinY = (float) Math.sin(euler.z / 2.0f);

    w = cosR * cosP * cosY + sinR * sinP * sinY;
    x = sinR * cosP * cosY - cosR * sinP * sinY;
    y = cosR * sinP * cosY + sinR * cosP * sinY;
    z = cosR * cosP * sinY - sinR * sinP * cosY;
    
    //return normalize();
    return this;
  }
  
  public PVector toEuler(PVector euler) {
    float sqw = w * w;
    float sqx = x * x;
    float sqy = y * y;
    float sqz = z * z;
    
    // works but pitch is flipping, when rolling
    //euler.x = (float) Math.atan2(2 * (y * z - w * x), 2 * (sqw + sqz) - 1); // phi - roll
    //euler.y = (float) -Math.asin(2 * (x * z + w * y)); // theta - pitch
    //euler.z = (float) Math.atan2(2 * (x * y - w * z), 2 * (sqw + sqx) - 1); // psi - yaw
    
    // works but pitch is flipping many times
    euler.x = (float) Math.atan2(2.0 * (y * z + w * x), 1 - 2.0 * (sqx + sqy)); // roll
    euler.y = (float) Math.asin(2.0 * (w * y - x * z)); // picth
    euler.z = (float) Math.atan2(2.0 * (x * y + w * z), 1 - 2.0 * (sqy + sqz)); // yaw
    
    // this is from M5StickC
    // it works for the box, but does not for the circles
    //euler.x = atan2(2 * (y * z + w * x), -2 * sqx - 2 * sqy + 1);  // roll
    //euler.y = asin(2 * (w * y - x * z));  // pitch
    //euler.z = atan2(2 * (x * y + w * z), sqw + sqx - sqy - sqz);  // yaw
    
    return euler;
  }
  
  public PVector toEuler() {
    return toEuler(new PVector());
  }
  
  public PVector toPVector() {
    return new PVector(x, y, z);
  }
  
  public float[] toArray() {
    float[] arr = {w, x, y, z}; 
    return arr;
  }
  
  PVector projXZ() {
    PVector rot = mult(new PVector(0.0F, 1.0F, 0.0F));
    return new PVector(rot.x, rot.y);
  }
  
  PVector projYX() {
    PVector rot = mult(new PVector(0.0F, 0.0F, 1.0F));
    return new PVector(rot.x, rot.z);
  }
  
  PVector projZY() {
    PVector rot = mult(new PVector(1.0F, 0.0F, 0.0F));
    return new PVector(rot.x, rot.z);
  }
  
  Matrix4x4 toMatrix() {
    float sqw = w * w;
    float sqx = x * x;
    float sqy = y * y;
    float sqz = z * z;
    
    Matrix4x4 m = new Matrix4x4();
    m.setToIdentity();

    // invs (inverse square length) is only required if quaternion is not already normalised
    float invs = 1 / (sqx + sqy + sqz + sqw);
    m.setVal(0, 0, ( sqx - sqy - sqz + sqw) * invs); // since sqw + sqx + sqy + sqz =1/invs*invs
    m.setVal(1, 1, (-sqx + sqy - sqz + sqw) * invs);
    m.setVal(2, 2, (-sqx - sqy + sqz + sqw) * invs);
    
    float tmp1 = x * y;
    float tmp2 = z * w;
    m.setVal(1, 0, 2F * (tmp1 + tmp2) * invs);
    m.setVal(0, 1, 2F * (tmp1 - tmp2) * invs);
    
    tmp1 = x * z;
    tmp2 = y * w;
    m.setVal(2, 0, 2F * (tmp1 - tmp2)*invs);
    m.setVal(0, 2, 2F * (tmp1 + tmp2)*invs);
    tmp1 = y * z;
    tmp2 = x * w;
    m.setVal(2, 1, 2F * (tmp1 + tmp2)*invs);
    m.setVal(1, 2, 2F * (tmp1 - tmp2)*invs);
    
    return m;
  }
  
  public String toString() {
    return "[ " + x + ", " + y + ", " + z + ", " + w + " ]";
  }

}
