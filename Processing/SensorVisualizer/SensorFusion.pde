enum FusionType {
  NONE,
  KALMAN;
  
  private static FusionType[] vals = values();
  public FusionType next()
  {
      return vals[(this.ordinal()+1) % vals.length];
  }
};

abstract class SensorFusion {
  
  Device device;
  FusionType type;
  PVector measuredPose;
  PVector fusionPose;
  Quaternion measuredQPose;  
  Quaternion fusionQPose;
  
  SensorFusion(Device dev) {
    device = dev;
    fusionPose = new PVector();
    measuredQPose = new Quaternion();
    fusionQPose = new Quaternion();
  }
  
  public void calculatePose() {
    Quaternion m = new Quaternion();
    Quaternion q = new Quaternion();

    if (device.hasEuler() && device.getEuler().value != null || device.hasAccelerometer()) {
        measuredPose = device.hasEuler() && device.getEuler().value != null ? device.getEuler().val() : device.getAccelerometer().getOrigEulerAngles();
    }
    if (measuredPose == null) {
        measuredPose = fusionPose.copy();
        measuredPose.z = 0;
    }

    MagDisplay mag = device.getMagnetometer();
    if (mag != null && mag.val() != null) {
      
      PVector magValue = mag.val();
      q.fromEuler(measuredPose);
      m.w = 0;
      m.x = magValue.x;
      m.y = magValue.y;
      m.z = magValue.z;

      m = q.mult(m).mult(q.conjugate());
      measuredPose.z = -atan2(m.y, m.x) - mag.magDeclination;
    } else {
      measuredPose.z = fusionPose.z;
    }

    measuredQPose.fromEuler(measuredPose);

    //  check for quaternion aliasing. If the quaternion has the wrong sign
    //  the kalman filter will be very unhappy.

    int maxIndex = -1;
    float maxVal = -10000;
    float[] measuredQArray = measuredQPose.toArray();

    for (int i = 0; i < 4; i++) {
        if (abs(measuredQArray[i]) > maxVal) {
            maxVal = abs(measuredQArray[i]);
            maxIndex = i;
        }
    }

    //  if the biggest component has a different sign in the measured and kalman poses,
    //  change the sign of the measured pose to match.

    float[] fusionQArray = fusionQPose.toArray();
    if (((measuredQArray[maxIndex] < 0) && (fusionQArray[maxIndex] > 0)) ||
            ((measuredQArray[maxIndex] > 0) && (fusionQArray[maxIndex] < 0))) {
        measuredQPose.w = -measuredQPose.w;
        measuredQPose.x = -measuredQPose.x;
        measuredQPose.y = -measuredQPose.y;
        measuredQPose.z = -measuredQPose.z;
        measuredPose = measuredQPose.toEuler();
    }
  }
  
  public abstract PVector getEulerAngles();
}
