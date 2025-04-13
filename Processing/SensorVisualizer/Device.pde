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
  COMP,
  PPG,
  PPI;
};

public class Device {
  
  String id;
  String ip;
  String inPrefix;
  String outPrefix;
  int firstArg = 0;
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
  float x = 0, y = 0, w, h;
  int idx;
  ButtonBar menu;
  boolean isMenuVisible = false;
  
  Device(String id, String inPrefix, String outPrefix, Map<SensorType, SensorDisplay> sensors, FusionType fusionType) {
    this.id = id;
    this.inPrefix = inPrefix;
    this.outPrefix = outPrefix;
    this.sensors = sensors;
    this.recorders = new HashMap<SensorType, PrintWriter>();
    this.loadedTables = new HashMap<SensorType, Table>();
    for (SensorDisplay sensor : sensors.values()) {
      sensor.device = this;
    }
    this.w = 200;
    this.h = 20;
  }
  
  Device(String id, String inPrefix, String outPrefix, Map<SensorType, SensorDisplay> sensors) {
    this(id, inPrefix, outPrefix, sensors, FusionType.NONE);
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
  
  void draw(int idx, boolean isActive, ControlP5 cp5) {
    this.idx = idx;
    x = idx * w;
    y = height - h;
    if (cp5 == null) {
      drawTab(isActive);
    }
    else if (menu == null) {
      drawMenu(isActive, cp5);
    }
  }
  
  void drawTab(boolean isActive) {
    pushMatrix();
    translate(x, y);
    pushStyle();
    stroke(255);
    if (isActive) {
      fill(0, 0, 255);
    }
    else {
      noFill();
    }
    rect(0, 0, w, h);
    fill(255);
    textAlign(CENTER);
    textSize(13);
    text(id, w/2, 13);
    popStyle();
    if (isRecording || isPlaying) {
      fill(isRecording ? 255 : 0, isPlaying ? (isPaused ? 127 : 255) : 0, 0);
      ellipse(10, 10, 10, 10);
    }
    popMatrix();
  }
  
  void drawMenu(boolean isActive, ControlP5 cp5) {
    cp5.addButton("toggleMenu")
      .setValue(idx)
      .setPosition(x, y)
      .setSize((int) w, (int) h)
      .setLabel(id);
    String[] items = split("Item1,Item2,Item3", ",");
    menu = cp5.addButtonBar(id + "Menu")
      .setPosition(x, y-100)
      .setSize((int) w, 100)
      .addItems(items)
      .setVisible(false);
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
    if (hasEuler() && getEuler().value != null) {
      return getEuler().val();
    }
    if (hasQuat() && getQuat().value != null) {
      return getQuat().getOrigEulerAngles();  
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
      String addr = msg.addrPattern();
      int len = inPrefix.length();
      int slash2 = addr.indexOf("/", len+1);
      String which = slash2 > -1 ? addr.substring(len, slash2) : addr.substring(len);
      String param = null;
      if (slash2 > -1) {
        param = addr.substring(slash2+1);
      }

      switch (which) {
        case "/acc":
        case "/accel":
        case "/accelerometer":
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
        case "/ppg":
          sensor = getOrCreateSensor(SensorType.PPG);
          break;
        case "/ppi":
          sensor = getOrCreateSensor(SensorType.PPI);
          break;
      }
      if (sensor != null) {
        if (param == null) {
          sensor.oscEvent(msg);
          if (isRecording) {
            sensor.record(msg);
          }
        }
        else {
          sensor.oscEventParam(msg, param);
          if (isRecording) {
            sensor.recordParam(msg, param);
          }
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
      case COMP:
        return new CompDisplay();
      //case PPG:
      //  return new PPGDisplay();
      //case PPI:
      //  return new PPIDisplay();
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
  
  boolean hasQuat() {
    return sensors.get(SensorType.QUAT) != null;
  }
  
  QuatDisplay getQuat() {
    return ((QuatDisplay) sensors.get(SensorType.QUAT));
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
  
  boolean toggleMenu(float val) {
    if (menu != null && val == (float) idx) {
      isMenuVisible = !isMenuVisible;
      menu.setVisible(isMenuVisible);
      return true;
    }
    return false;
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
      boolean vis = toggleVisible(SensorType.EULER);
      if (vis && hasQuat()) {
        getQuat().visible = false;
      }
      return true;
    }
    if (key == 'q') {
      boolean vis = toggleVisible(SensorType.QUAT);
      if (vis && hasEuler()) {
        getEuler().visible = false;
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
    if (key == 'g') {
      if (hasEuler()) {
        getEuler().glPrevent = !getEuler().glPrevent;
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
  
  boolean toggleVisible(SensorType st) {
    SensorDisplay sensor = sensors.get(st);
    if (sensor == null) {
      sensor = getOrCreateSensor(st);
    }
    else {
      sensor.visible = !sensor.visible;
    }
    return sensor.visible;
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
