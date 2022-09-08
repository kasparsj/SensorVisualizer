//  The QVALUE affects the gyro response.

final float KALMAN_QVALUE = 0.001F;

//  The RVALUE controls the influence of the accels and compass.
//  The bigger the value, the more sluggish the response.

final float KALMAN_RVALUE = 0.0005F;

public class KalmanFusion extends SensorFusion {
  
  boolean firstTime = true;
  long lastFusionTime;
  float timeDelta;
  Quaternion stateQ;
  Quaternion stateQError;                               // difference between stateQ and measuredQ
  boolean debug = false;

  Matrix4x4 m_Kk;                                       // the Kalman gain matrix
  Matrix4x4 m_Pkk_1;                                    // the predicted estimated covariance matrix
  Matrix4x4 m_Pkk;                                      // the updated estimated covariance matrix
  Matrix4x4 m_PDot;                                     // the derivative of the covariance matrix
  Matrix4x4 m_Q;                                        // process noise covariance
  Matrix4x4 m_Fk;                                       // the state transition matrix
  Matrix4x4 m_FkTranspose;                              // the state transition matrix transposed
  Matrix4x4 m_Rk;                                       // the measurement noise covariance
  
  KalmanFusion(Device dev) {
    super(dev);
    stateQ = new Quaternion();
    m_Pkk = new Matrix4x4();
    m_Q = new Matrix4x4();
    m_Fk = new Matrix4x4();
    m_Rk = new Matrix4x4();

    m_Q.fill(KALMAN_QVALUE);
    m_Rk.fill(KALMAN_RVALUE);
  }
  
  void predict() {
    Matrix4x4 mat;
    Quaternion tQuat;
    float x2, y2, z2;
    PVector gyroVal = null;

    //  compute the state transition matrix

    if (device.hasGyroscope()) {
      gyroVal = device.getGyroscope().val();
    }
    if (gyroVal == null) {
      gyroVal = new PVector(0, 0, 0);
    }
    x2 = gyroVal.x / (float)2.0;
    y2 = gyroVal.y / (float)2.0;
    z2 = gyroVal.z / (float)2.0;

    m_Fk.setVal(0, 1, -x2);
    m_Fk.setVal(0, 2, -y2);
    m_Fk.setVal(0, 3, -z2);

    m_Fk.setVal(1, 0, x2);
    m_Fk.setVal(1, 2, z2);
    m_Fk.setVal(1, 3, -y2);

    m_Fk.setVal(2, 0, y2);
    m_Fk.setVal(2, 1, -z2);
    m_Fk.setVal(2, 3, x2);

    m_Fk.setVal(3, 0, z2);
    m_Fk.setVal(3, 1, y2);
    m_Fk.setVal(3, 2, -x2);

    m_FkTranspose = m_Fk.transposed();

    // Predict new state estimate Xkk_1 = Fk * Xk_1k_1

    tQuat = Matrix4x4.mult(m_Fk, stateQ);
    tQuat.mult(timeDelta);
    stateQ.add(tQuat);

    // Compute PDot = Fk * Pk_1k_1 + Pk_1k_1 * FkTranspose (note Pkk == Pk_1k_1 at this stage)

    m_PDot = Matrix4x4.mult(m_Fk, m_Pkk);
    mat = Matrix4x4.mult(m_Pkk, m_FkTranspose);
    m_PDot.add(mat);

    // add in Q to get the new prediction

    m_Pkk_1 = Matrix4x4.add(m_PDot, m_Q);

    //  multiply by deltaTime (variable name is now misleading though)

    m_Pkk_1.mult(timeDelta);
  }
  
  void update() {
    Quaternion delta;
    Matrix4x4 Sk, SkInverse;

    if (device.hasMagnetometer() || device.hasAccelerometer()) {
        stateQError = Quaternion.sub(measuredQPose, stateQ);
    } else {
        stateQError = new Quaternion();
    }

    //  Compute residual covariance Sk = Hk * Pkk_1 * HkTranspose + Rk
    //  Note: since Hk is the identity matrix, this has been simplified

    Sk = Matrix4x4.add(m_Pkk_1, m_Rk);

    //  Compute Kalman gain Kk = Pkk_1 * HkTranspose * SkInverse
    //  Note: again, the HkTranspose part is omitted

    SkInverse = Sk.inverted();

    m_Kk = Matrix4x4.mult(m_Pkk_1, SkInverse);

    // make new state estimate

    delta = Matrix4x4.mult(m_Kk, stateQError);

    stateQ.add(delta);

    stateQ.normalize();

    //  produce new estimate covariance Pkk = (I - Kk * Hk) * Pkk_1
    //  Note: since Hk is the identity matrix, it is omitted

    m_Pkk.setToIdentity();
    m_Pkk.sub(m_Kk);
    m_Pkk = Matrix4x4.mult(m_Pkk, m_Pkk_1);
  }
  
  PVector getEulerAngles() {
    if (device.hasAccelerometer() && device.getAccelerometer().val() == null) {
      return null;
    }
    if (firstTime) {
        lastFusionTime = millis();
        calculatePose();
        m_Fk.fill(0);

        //  init covariance matrix to something
        m_Pkk.fill(0.5);
        
        // initialize the observation model Hk
        // Note: since the model is the state vector, this is an identity matrix so it won't be used

        //  initialize the poses

        stateQ.fromEuler(measuredPose);
        fusionQPose = stateQ.copy();
        fusionPose = measuredPose.copy();
        firstTime = false;
    } else {
        timeDelta = (float)(millis() - lastFusionTime);
        lastFusionTime = millis();
        if (timeDelta <= 0)
            return fusionPose;

        if (debug) {
            println("\n------\n");
            println("IMU update delta time: " + timeDelta);
        }
        calculatePose();
        predict();
        update();
        fusionPose = stateQ.toEuler();
        fusionQPose = stateQ.copy();
        if (debug) {
            println("Measured pose" + measuredPose);
            println("Kalman pose" + fusionPose);
            println("Measured quat" + measuredPose);
            println("Kalman quat" + stateQ);
            println("Error quat" + stateQError);
         }
    }
    return fusionPose;
  }
}
