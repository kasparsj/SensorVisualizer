public class MahonyFusion extends SensorFusion {
  
  final float twoKpDef = (2.0f * 0.5f);  // 2 * proportional gain
  final float twoKiDef = (2.0f * 0.0f);  // 2 * integral gain
  
  float twoKp;            // Mahony: 2 * proportional gain (Kp)
  float twoKi;            // Mahony: 2 * integral gain (Ki)
  float q0, q1, q2, q3;   // quaternion of sensor frame relative to auxiliary frame
  float integralFBx, integralFBy, integralFBz;  // integral error terms scaled by Ki
  
  long lastUpdate = 0;
  
  MahonyFusion(Device dev) {
    super(dev);
    type = FusionType.MAHONY;
    twoKp = twoKpDef;  
    twoKi = twoKiDef;  
    q0 = 1.0f;
    q1 = 0.0f;
    q2 = 0.0f;
    q3 = 0.0f;
    integralFBx = 0.0f;
    integralFBy = 0.0f;
    integralFBz = 0.0f;
  }
  
  float invSqrt(float x) {
    float xhalf = 0.5f * x;
    int i = Float.floatToIntBits(x);
    i = 0x5f3759df - (i >> 1);
    x = Float.intBitsToFloat(i);
    x *= (1.5f - xhalf * x * x);
    return x;
  }
  
  PVector getEulerAngles() {
    
    float recipNorm;
    float halfvx, halfvy, halfvz;
    float halfex, halfey, halfez;
    float qa, qb, qc;
    
    long Now = millis();
    float deltat = ((float)(Now - lastUpdate) / 1000.0f); // set integration time by time elapsed since last filter update
    lastUpdate = Now;
    
    PVector acc = device.getAccelerometer().val();
    PVector gyro = device.getGyroscope().val();
    
    // Compute feedback only if accelerometer measurement valid
    // (avoids NaN in accelerometer normalisation)
    if (!acc.equals(new PVector(0, 0, 0))) {
      
      // Normalise accelerometer measurement
      recipNorm = invSqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z);
      acc.x *= recipNorm;
      acc.y *= recipNorm;
      acc.z *= recipNorm;
      
      if (device.hasMagnetometer() && !device.getMagnetometer().val().equals(new PVector(0, 0, 0))) {
        float q0q0, q0q1, q0q2, q0q3, q1q1, q1q2, q1q3, q2q2, q2q3, q3q3;
        float hx, hy, bx, bz;
        float halfwx, halfwy, halfwz;
        
        PVector mag = device.getMagnetometer().val();
      
        // Normalise magnetometer measurement
        recipNorm = invSqrt(mag.x * mag.x + mag.y * mag.y + mag.z * mag.z);
        mag.x *= recipNorm;
        mag.y *= recipNorm;
        mag.z *= recipNorm;
    
        // Auxiliary variables to avoid repeated arithmetic
        q0q0 = q0 * q0;
        q0q1 = q0 * q1;
        q0q2 = q0 * q2;
        q0q3 = q0 * q3;
        q1q1 = q1 * q1;
        q1q2 = q1 * q2;
        q1q3 = q1 * q3;
        q2q2 = q2 * q2;
        q2q3 = q2 * q3;
        q3q3 = q3 * q3;
    
        // Reference direction of Earth's magnetic field
        hx = 2.0f * (mag.x * (0.5f - q2q2 - q3q3) + mag.y * (q1q2 - q0q3) + mag.z * (q1q3 + q0q2));
        hy = 2.0f * (mag.x * (q1q2 + q0q3) + mag.y * (0.5f - q1q1 - q3q3) + mag.z * (q2q3 - q0q1));
        bx = sqrt(hx * hx + hy * hy);
        bz = 2.0f * (mag.x * (q1q3 - q0q2) + mag.y * (q2q3 + q0q1) + mag.z * (0.5f - q1q1 - q2q2));
    
        // Estimated direction of gravity and magnetic field
        halfvx = q1q3 - q0q2;
        halfvy = q0q1 + q2q3;
        halfvz = q0q0 - 0.5f + q3q3;
        halfwx = bx * (0.5f - q2q2 - q3q3) + bz * (q1q3 - q0q2);
        halfwy = bx * (q1q2 - q0q3) + bz * (q0q1 + q2q3);
        halfwz = bx * (q0q2 + q1q3) + bz * (0.5f - q1q1 - q2q2);
    
        // Error is sum of cross product between estimated direction
        // and measured direction of field vectors
        halfex = (acc.y * halfvz - acc.z * halfvy) + (mag.y * halfwz - mag.z * halfwy);
        halfey = (acc.z * halfvx - acc.x * halfvz) + (mag.z * halfwx - mag.x * halfwz);
        halfez = (acc.x * halfvy - acc.y * halfvx) + (mag.x * halfwy - mag.y * halfwx);
    
        // Compute and apply integral feedback if enabled
        if(twoKi > 0.0f) {
          // integral error scaled by Ki
          integralFBx += twoKi * halfex * deltat;
          integralFBy += twoKi * halfey * deltat;
          integralFBz += twoKi * halfez * deltat;
          gyro.x += integralFBx;  // apply integral feedback
          gyro.y += integralFBy;
          gyro.z += integralFBz;
        } else {
          integralFBx = 0.0f;  // prevent integral windup
          integralFBy = 0.0f;
          integralFBz = 0.0f;
        }
      }
      else {    
        // Estimated direction of gravity
        halfvx = q1 * q3 - q0 * q2;
        halfvy = q0 * q1 + q2 * q3;
        halfvz = q0 * q0 - 0.5f + q3 * q3;
    
        // Error is sum of cross product between estimated
        // and measured direction of gravity
        halfex = (acc.y * halfvz - acc.z * halfvy);
        halfey = (acc.z * halfvx - acc.x * halfvz);
        halfez = (acc.x * halfvy - acc.y * halfvx);
    
        // Compute and apply integral feedback if enabled
        if(twoKi > 0.0f) {
          // integral error scaled by Ki
          integralFBx += twoKi * halfex * deltat;
          integralFBy += twoKi * halfey * deltat;
          integralFBz += twoKi * halfez * deltat;
          gyro.x += integralFBx;  // apply integral feedback
          gyro.y += integralFBy;
          gyro.z += integralFBz;
        } else {
          integralFBx = 0.0f;  // prevent integral windup
          integralFBy = 0.0f;
          integralFBz = 0.0f;
        }
      }
      
      // Apply proportional feedback
      gyro.x += twoKp * halfex;
      gyro.y += twoKp * halfey;
      gyro.z += twoKp * halfez;
    }
    
    // Integrate rate of change of quaternion
    gyro.x *= (0.5f * deltat);    // pre-multiply common factors
    gyro.y *= (0.5f * deltat);
    gyro.z *= (0.5f * deltat);
    qa = q0;
    qb = q1;
    qc = q2;
    q0 += (-qb * gyro.x - qc * gyro.y - q3 * gyro.z);
    q1 += (qa * gyro.x + qc * gyro.z - q3 * gyro.y);
    q2 += (qa * gyro.y - qb * gyro.z + q3 * gyro.x);
    q3 += (qa * gyro.z + qb * gyro.y - qc * gyro.x);
    
    // Normalise quaternion
    recipNorm = invSqrt(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
    q0 *= recipNorm;
    q1 *= recipNorm;
    q2 *= recipNorm;
    q3 *= recipNorm;
    
    float roll = atan2(q0*q1 + q2*q3, 0.5f - q1*q1 - q2*q2);
    float pitch = asin(-2.0f * (q1*q3 - q0*q2));
    float yaw = atan2(q1*q2 + q0*q3, 0.5f - q2*q2 - q3*q3);
    
    //float pitch = asin(-2 * q1 * q3 + 2 * q0 * q2);  // pitch
    //float roll  = atan2(2 * q2 * q3 + 2 * q0 * q1,
    //              -2 * q1 * q1 - 2 * q2 * q2 + 1);  // roll
    //float yaw   = atan2(2 * (q1 * q2 + q0 * q3),
    //             q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3);  // yaw
    
    return new PVector(roll, pitch, yaw);
  }
}
