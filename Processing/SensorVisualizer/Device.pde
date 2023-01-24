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
  HR,
  COMP;
};

public class Device {
  
  String id;
  String inPrefix;
  String outPrefix;
  int firstArg = 1;
  long lastUps = 0;
  Map<SensorType, SensorDisplay> sensors;
  SensorDisplay curSensor = null;
  SensorFusion fusion;
  Map<SensorType, PrintWriter> recorders;
  boolean isRecording;
  Map<SensorType, Table> loadedTables;
  Map<SensorType, Integer> nextRowCursor;
  boolean isPlaying;
  long lastMs = 0;
  int playPos = 0;
  long playMinMs = -1;
  long playMaxMs = -1;
  boolean isPaused;
  
  Device(String id, String inPrefix, String outPrefix, int firstArg, Map<SensorType, SensorDisplay> sensors, FusionType fusionType) {
    this.id = id;
    this.inPrefix = inPrefix;
    this.outPrefix = outPrefix;
    this.firstArg = firstArg;
    this.sensors = sensors;
    this.recorders = new HashMap<SensorType, PrintWriter>();
    this.loadedTables = new HashMap<SensorType, Table>();
    for (SensorDisplay sensor : sensors.values()) {
      sensor.device = this;
    }
  }
  
  Device(String id, String inPrefix, String outPrefix, int firstArg, Map<SensorType, SensorDisplay> sensors) {
    this(id, inPrefix, outPrefix, firstArg, sensors, FusionType.NONE);
  }
  
  void update() {
    if (isPlaying && !isPaused) {
      playEvent();
    }
    boolean updateUps = millis() - lastUps >= 1000;
    for (SensorDisplay sensor : sensors.values()) {
      if (updateUps) {
        sensor.updateUps();
      }
    }
    if (updateUps) {
      lastUps = millis();
    }
  }
  
  void drawTab(int idx, boolean isActive) {
    int w = 200;
    pushMatrix();
    translate(idx * w, height - 20);
    pushStyle();
    stroke(255);
    if (isActive) {
      fill(0, 0, 255);
    }
    else {
      noFill();
    }
    rect(0, 0, w, 20);
    fill(255);
    textAlign(CENTER);
    text(id, w/2, 13);
    popStyle();
    if (isRecording || isPlaying) {
      fill(isRecording ? 255 : 0, isPlaying ? (isPaused ? 127 : 255) : 0, 0);
      ellipse(10, 10, 10, 10);
    }
    popMatrix();
  }
  
  void drawSensors() {  
    Map<SensorType, SensorDisplay> copy = new HashMap<SensorType, SensorDisplay>();
    copy.putAll(sensors);        
    for (SensorDisplay sensor : copy.values()) {
      if (sensor.visible) {
        sensor.draw();
      }
    }
  }
  
  PVector getEulerAngles() {
    if (!(isPlaying && isPaused)) {
      if (fusion != null && hasAccelerometer() && hasGyroscope()) {
        return fusion.getEulerAngles();
      } 
    }
    if (hasAccelerometer()) {
      return getAccelerometer().getOrigEulerAngles();
    }
    return null;
  }
  
  void oscEvent(OscMessage msg) {
    if (isPlaying) {
      return;
    }
    try {
      SensorDisplay sensor = null;
      switch (msg.addrPattern().substring(inPrefix.length())) {
        case "/acc":
        case "/accel":
          sensor = getOrCreateSensor(SensorType.ACC);
          break;
        case "/gyro":
        case "/gyro_deg":
        case "/gyro_rad":
          sensor = getOrCreateSensor(SensorType.GYRO);
          break;
        case "/mag":
          sensor = getOrCreateSensor(SensorType.MAG);
          break;
        case "/comp":
          sensor = getOrCreateSensor(SensorType.COMP);
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
        case "/alt":
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
  
  void playEvent() {
    long ms = millis();
    playPos += (ms - lastMs);
    lastMs = ms;
    for (SensorType st : loadedTables.keySet()) {
      Table table = loadedTables.get(st);
      Integer cursor = nextRowCursor.get(st);
      if (cursor == null) { cursor = 0; }
      int loop = floor(cursor / table.getRowCount());
      while ((table.getRow(cursor % table.getRowCount()).getInt(1) - playMinMs + (playMaxMs - playMinMs) * loop) <= playPos) {
        TableRow row = table.getRow(cursor % table.getRowCount());
        getOrCreateSensor(st).playEvent(row);
        cursor = (cursor + 1);
        nextRowCursor.put(st, cursor);
        loop = floor(cursor / table.getRowCount());
      }
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
        return new AccDisplay(firstArg);
      case GYRO:
        return new GyroDisplay(firstArg);
      case MAG:
        return new MagDisplay(firstArg);
      case EULER:
        return new EulerDisplay(firstArg);
      case HR:
        return new HRDisplay(firstArg);
      case ECG:
        return new ECGDisplay(firstArg);
      case ALTITUDE:
        return new AltitudeDisplay(firstArg);
      case QUAT:
        return new QuatDisplay(firstArg);
      case COMP:
        return new CompDisplay(firstArg);
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
  
  EulerDisplay getEuler() {
    return ((EulerDisplay) sensors.get(SensorType.EULER));
  }
    
  PrintWriter getOrCreateRecorder(SensorType st) {
    PrintWriter recorder = recorders.get(st);
    if (recorder == null) {
      recorder = createRecorder(st);
    }
    return recorder;
  }
  
  PrintWriter createRecorder(SensorType st, String folder) {
    PrintWriter recorder = createWriter("data/" + folder + "/" + id + "_" + st.toString() + ".csv");
    recorders.put(st, recorder);
    return recorder;
  }
  
  PrintWriter createRecorder(SensorType st) {
    SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HHmmss");
    String date = df.format(new Date());
    return createRecorder(st, date);
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
    if (key == ' ') {
      togglePaused();
      return true;
    }
    if (key == 'u') {
      setFusionType((fusion == null ? FusionType.NONE : fusion.type).next());
      return true;
    }
    if (key == 'e') {
      toggleVisible(SensorType.EULER);
      if (sensors.get(SensorType.QUAT) != null) {
        sensors.get(SensorType.QUAT).visible = false;
      }
      return true;
    }
    if (key == 'q') {
      toggleVisible(SensorType.QUAT);
      if (sensors.get(SensorType.EULER) != null) {
        sensors.get(SensorType.EULER).visible = false;
      }
      return true;
    }
    if (key == 'r') {
      toggleRecording();
      return true;
    }
    if (key == 's') {
      stopPlaying();
      return true;
    }
    if (key == 'p') {
      startPlaying();
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
  
  void setFusionType(FusionType ft) {
    switch (ft) {
      case MAHONY:
        fusion = new MahonyFusion(this);
        break;
      case MADGWICK:
        fusion = new MadgwickFusion(this);
        break;
      case KALMAN:
        fusion = new KalmanFusion(this);
        break;
      case NONE:
      default:
        fusion = null;
        break;
    }
  }
  
  void toggleVisible(SensorType st) {
    SensorDisplay sensor = sensors.get(st);
    if (sensor == null) {
      sensor = getOrCreateSensor(st);
    }
    else {
      sensor.visible = !sensor.visible;
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
    if (isRecording) {
      SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HHmmss");
      String date = df.format(new Date());
      for (SensorType st : sensors.keySet()) {
        createRecorder(st, date);
      }
    }
  }
  
  void openFile(File file) {
    if (isRecording) {
      toggleRecording();
    }
    String fileName = file.getName();
    String type = fileName.substring(fileName.lastIndexOf('_')+1, fileName.lastIndexOf('.'));
    SensorDisplay sensor = null;
    try {
      SensorType sensorType = SensorType.valueOf(type);
      sensor = getOrCreateSensor(sensorType);
    }
    catch (Exception e) {
      println("Cannot open unknown file type: " + type + "!");
    }
    if (sensor != null) {
      Table table = sensor.loadFile(file);
      if (table != null) {
        loadedTables.put(sensor.type, table);
        playMinMs = playMaxMs = -1;
        nextRowCursor = new HashMap<SensorType, Integer>();
        startPlaying();
        isPaused = true;
      }
    }
  }
  
  void stopPlaying() {
    isPlaying = false;
    lastMs = 0;
    playPos = 0;
    nextRowCursor = new HashMap<SensorType, Integer>();
    
    OscMessage fw = new OscMessage(outPrefix + "/stop_play");
    fw.add(id);
    oscP5.send(fw, forwardAddr);
  }
  
  void startPlaying() {
    if (loadedTables.keySet().size() > 0) {
      isPlaying = true;
      lastMs = millis();
      playPos = 0;
      
      OscMessage fw = new OscMessage(outPrefix + "/start_play");
      fw.add(id);
      oscP5.send(fw, forwardAddr);
    }
  }
  
  void togglePaused() {
    isPaused = !isPaused;
    lastMs = millis();
    
    OscMessage fw = new OscMessage(outPrefix + (isPaused ? "/pause" : "/resume"));
    fw.add(id);
    oscP5.send(fw, forwardAddr);
  }
  
  long[] getMinMaxMs() {
    long minMaxMs[] = new long[] {-1, -1};
    for (Table tbl : loadedTables.values()) {
      if (minMaxMs[0] == -1 || tbl.getRow(0).getInt(1) < minMaxMs[0]) {
        minMaxMs[0] = tbl.getRow(0).getInt(1);
      }
      if (minMaxMs[1] == -1 || tbl.getRow(tbl.getRowCount()-1).getInt(1) > minMaxMs[1]) {
        minMaxMs[1] = tbl.getRow(tbl.getRowCount()-1).getInt(1);
      }
    }
    return minMaxMs;
  }
}
