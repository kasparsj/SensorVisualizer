import java.util.Date;
import java.text.SimpleDateFormat;

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
  Map<SensorType, PrintWriter> recorders;
  boolean isRecording;
  
  Device(String id, String oscPrefix, Map<SensorType, SensorDisplay> sensors, FusionType fusionType) {
    this.id = id;
    this.oscPrefix = oscPrefix;
    this.sensors = sensors;
    this.recorders = new HashMap<SensorType, PrintWriter>();
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
    pushMatrix();
    translate(idx * 100, height - 20);
    pushStyle();
    stroke(255);
    if (isActive) {
      fill(0, 0, 255);
    }
    else {
      noFill();
    }
    rect(0, 0, 100, 20);
    fill(255);
    textAlign(CENTER);
    text(id, 50, 13);
    popStyle();
    if (isRecording) {
      fill(255, 0, 0);
      ellipse(10, 10, 10, 10);
    }
    popMatrix();
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
      SensorDisplay sensor = null;
      switch (msg.addrPattern().substring(oscPrefix.length())) {
        case "/acc":
          sensor = getOrCreateSensor(SensorType.ACC);
          break;
        case "/gyro":
          sensor = getOrCreateSensor(SensorType.GYRO);
          break;
        case "/mag":
          sensor = getOrCreateSensor(SensorType.MAG);
          break;
        case "/euler":
        case "/euler_rad":
        case "/euler_deg":
          sensor = getOrCreateSensor(SensorType.EULER);
          break;
        case "/hr":
          sensor = getOrCreateSensor(SensorType.HR);
          break;
        case "/ecg":
          sensor = getOrCreateSensor(SensorType.ECG);
          break;
        case "/altitude":
          sensor = getOrCreateSensor(SensorType.ALTITUDE);
          break;
        case "/quat":
          sensor = getOrCreateSensor(SensorType.QUAT);
          break;
      }
      if (sensor != null) {
        sensor.oscEvent(msg);
        if (isRecording) {
          sensor.record(msg);
        }
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
    
  PrintWriter getOrCreateRecorder(SensorType st) {
    PrintWriter recorder = recorders.get(st);
    if (recorder == null) {
      SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HHmmss");
      String date = df.format(new Date());
      recorder = createWriter("data/" + id + "_" + st.toString() + "_" + date + ".csv");
      recorders.put(st, recorder);
    }
    return recorder;
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
      toggleVisible(SensorType.EULER);
      return true;
    }
    if (key == 'g') {
      toggleVisible(SensorType.GYRO);
      return true;
    }
    if (key == 'r') {
      toggleRecording();
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
  
  void toggleVisible(SensorType st) {
    SensorDisplay euler = sensors.get(st);
    if (euler == null) {
      euler = getOrCreateSensor(st);
    }
    else {
      euler.visible = !euler.visible;
    }
  }
  
  void toggleRecording() {
    isRecording = !isRecording;
    if (!isRecording) {
      for (PrintWriter recorder : recorders.values()) {
        recorder.flush();
        recorder.close();        
      }
    }
    recorders = null;
    recorders = new HashMap<SensorType, PrintWriter>();
  }
}
