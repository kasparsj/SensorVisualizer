import processing.core.PVector;
import processing.core.PMatrix3D;

// https://github.com/kynd/PQuaternion
// https://behreajj.medium.com/3d-rotations-in-processing-vectors-matrices-quaternions-10e2fed5f0a3
public class Quaternion
{
  public float w, x, y, z;

  public Quaternion() {
      x = y = z = 0;
      w = 1;
  }

  public Quaternion(float _w, float _x, float _y, float _z) {
      w = _w;
      x = _x;
      y = _y;
      z = _z;
  }

  public Quaternion(float angle, PVector axis) {
      setAngleAxis(angle, axis);
  }

  public Quaternion(Quaternion q) {
    this(q.x, q.y, q.z, q.w);
  }

  public Quaternion copy() {
      return new Quaternion(w, x, y, z);
  }

  public Quaternion inverse() {
    float norm = dot();
    if (norm > 0.0) {
      float invNorm = 1.0f / norm;
      return new Quaternion(w * invNorm, -x * invNorm, -y * invNorm, -z * invNorm);
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

  public void set(float _w, float _x, float _y, float _z) {
      w = _w;
      x = _x;
      y = _y;
      z = _z;
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
    ret.w = w;
    ret.x = -x;
    ret.y = -y;
    ret.z = -z;
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
    w = w * r;
    x = x * r;
    y = y * r;
    z = z * r;
    return this;
  }

  public Quaternion mult(Quaternion q) {
    w = q.w*w - q.x*x - q.y*y - q.z*z;
    x = q.w*x + q.x*w + q.y*z - q.z*y;
    y = q.w*y - q.x*z + q.y*w + q.z*x;
    z = q.w*z + q.x*y - q.y*x + q.z*w;
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
    // roll (x-axis rotation)
    double sinr_cosp = 2.0f * (w * x + y * z);
    double cosr_cosp = 1.0f - 2.0f * (x * x + y * y);
    euler.x = (float)Math.atan2(sinr_cosp, cosr_cosp);

    // pitch (y-axis rotation)
    double sinp = 2.0f * (w * y - z * x);
    if (Math.abs(sinp) >= 1)
        euler.y = (float)Math.copySign(Math.PI / 2, sinp); // use 90 degrees if out of range
    else
        euler.y = (float)Math.asin(sinp);

    // yaw (z-axis rotation)
    double siny_cosp = 2.0f * (w * z + x * y);
    double cosy_cosp = 1.0f - 2.0f * (y * y + z * z);
    euler.z = (float)Math.atan2(siny_cosp, cosy_cosp);

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
    return new PVector(rot.x, rot.z);
  }

  PVector projYX() {
    PVector rot = mult(new PVector(1.0F, 0.0F, 0.0F));
    return new PVector(rot.y, rot.x);
  }

  PVector projZY() {
    PVector rot = mult(new PVector(0.0F, 0.0F, 1.0F));
    return new PVector(rot.z, rot.y);
  }

  PMatrix3D toMatrix() {
    normalize();
    PMatrix3D matrix = new PMatrix3D(
      // todo: still not correct / not like euler
      //1 - 2*y*y - 2*z*z, 2*x*z + 2*y*w, 2*x*y - 2*z*w, 0,
      //2*x*z - 2*y*w, 1 - 2*x*x - 2*y*y, 2*y*z + 2*x*w, 0,
      //2*x*y + 2*z*w, 2*y*z - 2*x*w, 1 - 2*x*x - 2*z*z, 0,
      //0, 0, 0, 1
      // original:
      1 - 2*y*y - 2*z*z, 2*x*y - 2*z*w, 2*x*z + 2*y*w, 0,
      2*x*y + 2*z*w, 1 - 2*x*x - 2*z*z, 2*y*z - 2*x*w, 0,
      2*x*z - 2*y*w, 2*y*z + 2*x*w, 1 - 2*x*x - 2*y*y, 0,
      0, 0, 0, 1
    );
    return matrix;
  }

  public String toString() {
    return "[ " + w + ", " + x + ", " + y + ", " + z + " ]";
  }

}
