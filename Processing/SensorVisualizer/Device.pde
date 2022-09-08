enum SensorType {
  ACC,
  GYRO,
  MAG, 
  QUAT,
  EULER,
  ALTITUDE,
  ECG,
  HR;
};

public class Device {
  
  String id;
  String oscPrefix;

  Map<SensorType, SensorDisplay> sensors;
  SensorDisplay curSensor = null;
  SensorFusion fusion;
  boolean enableFusion;
  
  Device(String id, String oscPrefix, Map<SensorType, SensorDisplay> sensors, FusionType fusionType) {
    this.id = id;
    this.oscPrefix = oscPrefix;
    this.sensors = sensors;
    for (SensorDisplay sensor : sensors.values()) {
      sensor.device = this;
    }
    
    switch (fusionType) {
      case KALMAN:
        println("WIP - KalmanFusion");
        //fusion = new KalmanFusion(this);
        break;
      case NONE:
      default:
        break;
    }
    enableFusion = (fusion != null);
  }
  
  Device(String id, String oscPrefix, Map<SensorType, SensorDisplay> sensors) {
    this(id, oscPrefix, sensors, FusionType.NONE);
  }
  
  void tick() {
    for (SensorDisplay sensor : sensors.values()) {
      sensor.tick();
    }
  }
  
  void drawTab(int idx, boolean isActive) {
    pushStyle();
    stroke(255);
    if (isActive) {
      fill(0, 0, 255);
    }
    else {
      noFill();
    }
    rect(idx * 100, height - 20, 100, 20);
    fill(255);
    textAlign(CENTER);
    text(id, idx*100 + 50, height - 7);
    popStyle();
  }
  
  void drawSensors() {
    for (SensorDisplay sensor : sensors.values()) {
      if (sensor.visible) {
        sensor.draw();
      }
    }
  }
  
  PVector getEulerAngles() {
    if (enableFusion && fusion != null) {
      return fusion.getEulerAngles();
    }
    if (hasAccelerometer()) {
      return getAccelerometer().getOrigEulerAngles();
    }
    return null;
  }
  
  void oscEvent(OscMessage msg) {
    try {
      switch (msg.addrPattern().substring(oscPrefix.length())) {
        case "/acc":
          getOrCreateSensor(SensorType.ACC).oscEvent(msg);
          break;
        case "/gyro":
          getOrCreateSensor(SensorType.GYRO).oscEvent(msg);
          break;
        case "/mag":
          getOrCreateSensor(SensorType.MAG).oscEvent(msg);
          break;
        case "/euler":
          getOrCreateSensor(SensorType.EULER).oscEvent(msg);
          break;
        case "/hr":
          getOrCreateSensor(SensorType.HR).oscEvent(msg);
          break;
        case "/ecg":
          getOrCreateSensor(SensorType.ECG).oscEvent(msg);
          break;
        case "/altitude":
          getOrCreateSensor(SensorType.ALTITUDE).oscEvent(msg);
          break;
        case "/quat":
          getOrCreateSensor(SensorType.QUAT).oscEvent(msg);
          break;
      }
    }
    catch (Exception e) {
      e.printStackTrace();
    }
  }
  
  SensorDisplay getOrCreateSensor(SensorType st) {
    if (sensors.get(st) == null) {
      SensorDisplay sensor = createSensor(st);
      sensor.device = this;
      sensors.put(st, sensor);
    }
    return sensors.get(st);
  }
  
  SensorDisplay createSensor(SensorType st) {
    switch (st) {
      case ACC:
        return new AccDisplay();
      case GYRO:
        return new GyroDisplay();
      case MAG:
        return new MagDisplay();
      case EULER:
        return new EulerDisplay();
      case HR:
        return new HRDisplay();
      case ECG:
        return new ECGDisplay();
      case ALTITUDE:
        return new AltitudeDisplay();
      case QUAT:
        return new QuatDisplay();
    }
    return null;
  }
  
  boolean hasAccelerometer() {
    return sensors.get(SensorType.ACC) != null;
  }
  
  AccDisplay getAccelerometer() {
    return ((AccDisplay) sensors.get(SensorType.ACC));
  }
  
  boolean hasGyroscope() {
    return sensors.get(SensorType.GYRO) != null;
  }
  
  GyroDisplay getGyroscope() {
    return ((GyroDisplay) sensors.get(SensorType.GYRO));
  }
  
  boolean hasMagnetometer() {
    return sensors.get(SensorType.MAG) != null;
  }
  
  MagDisplay getMagnetometer() {
    return ((MagDisplay) sensors.get(SensorType.MAG));
  }
  
  boolean hasEuler() {
    return sensors.get(SensorType.EULER) != null;
  }
  
  boolean mouseClicked() {
    for (SensorDisplay sensor : sensors.values()) {
      if (sensor.mouseClicked()) {
        return true;     
      }
    }
    return false;
  }
  
  boolean keyPressed() {
    if (key == 'u') {
      enableFusion = !enableFusion;
      return true;
    }
    if (key == 'e') {
      SensorDisplay euler = sensors.get(SensorType.EULER);
      if (euler == null) {
        euler = getOrCreateSensor(SensorType.EULER);
      }
      else {
        euler.visible = !euler.visible;
      }
      
      return true;
    }
    if (curSensor != null && curSensor.keyPressed()) {
      return true;
    }
    for (SensorDisplay sensor : sensors.values()) {
      if (sensor.keyPressed()) {
        return true;     
      }
    }
    return false;
  }
}
