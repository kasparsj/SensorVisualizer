import java.util.Arrays;

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
  boolean debug = true;

  PMatrix3D m_Kk;                                       // the Kalman gain matrix
  PMatrix3D m_Pkk_1;                                    // the predicted estimated covariance matrix
  PMatrix3D m_Pkk;                                      // the updated estimated covariance matrix
  PMatrix3D m_PDot;                                     // the derivative of the covariance matrix
  PMatrix3D m_Q;                                        // process noise covariance
  PMatrix3D m_Fk;                                       // the state transition matrix
  PMatrix3D m_FkTranspose;                              // the state transition matrix transposed
  PMatrix3D m_Rk;                                       // the measurement noise covariance
  
  KalmanFusion(Device dev) {
    super(dev);
    type = FusionType.KALMAN;
    stateQ = new Quaternion();
    m_Pkk = new PMatrix3D();
    
    m_Q = new PMatrix3D();
    float[] qValues = new float[16];
    Arrays.fill(qValues, KALMAN_QVALUE);
    m_Q.set(qValues);
    
    m_Fk = new PMatrix3D();
    
    m_Rk = new PMatrix3D();
    float[] rValues = new float[16];
    Arrays.fill(rValues, KALMAN_RVALUE);
    m_Rk.set(rValues);
  }
  
  void predict() {
    PMatrix3D mat;
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

    m_Fk.set(
      m_Fk.m00, -x2, -y2, -z2,
      x2, m_Fk.m11, z2, -y2,
      y2, -z2, m_Fk.m22, x2,
      z2, y2, -x2, m_Fk.m33
    );

    m_FkTranspose = new PMatrix3D(m_Fk);
    m_FkTranspose.transpose();

// todo: fix

    //// Predict new state estimate Xkk_1 = Fk * Xk_1k_1

    //tQuat = Matrix4x4.mult(m_Fk, stateQ);
    //tQuat.mult(timeDelta);
    //stateQ.add(tQuat);

    //// Compute PDot = Fk * Pk_1k_1 + Pk_1k_1 * FkTranspose (note Pkk == Pk_1k_1 at this stage)

    //m_PDot = Matrix4x4.mult(m_Fk, m_Pkk);
    //mat = Matrix4x4.mult(m_Pkk, m_FkTranspose);
    //m_PDot.add(mat);

    //// add in Q to get the new prediction

    //m_Pkk_1 = Matrix4x4.add(m_PDot, m_Q);

    ////  multiply by deltaTime (variable name is now misleading though)

    //m_Pkk_1.mult(timeDelta);
  }
  
  void update() {
    Quaternion delta;
    PMatrix3D Sk, SkInverse;

    if (device.hasMagnetometer() || device.hasAccelerometer()) {
        stateQError = Quaternion.sub(measuredQPose, stateQ);
    } else {
        stateQError = new Quaternion();
    }
    
    // todo: fix

    ////  Compute residual covariance Sk = Hk * Pkk_1 * HkTranspose + Rk
    ////  Note: since Hk is the identity matrix, this has been simplified

    //Sk = Matrix4x4.add(m_Pkk_1, m_Rk);

    ////  Compute Kalman gain Kk = Pkk_1 * HkTranspose * SkInverse
    ////  Note: again, the HkTranspose part is omitted

    //SkInverse = Sk.inverted();

    //m_Kk = Matrix4x4.mult(m_Pkk_1, SkInverse);

    //// make new state estimate

    //delta = Matrix4x4.mult(m_Kk, stateQError);

    //stateQ.add(delta);

    //stateQ.normalize();

    ////  produce new estimate covariance Pkk = (I - Kk * Hk) * Pkk_1
    ////  Note: since Hk is the identity matrix, it is omitted

    //m_Pkk.setToIdentity();
    //m_Pkk.sub(m_Kk);
    //m_Pkk = Matrix4x4.mult(m_Pkk, m_Pkk_1);
  }
  
  PVector getEulerAngles() {
    if (true) {
      if (firstTime) {
        println("Kalman Fusion implementation incomplete/disabled");
        firstTime = false;
      }
      return new PVector();
    }    
    if (firstTime) {
        lastFusionTime = millis();
        calculatePose();
        float[] values = new float[16];
        Arrays.fill(values, 0);
        m_Fk.set(values);

        //  init covariance matrix to something
        Arrays.fill(values, 0.5);
        m_Pkk.set(values);
        
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
