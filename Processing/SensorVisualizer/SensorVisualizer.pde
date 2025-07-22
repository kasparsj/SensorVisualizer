import controlP5.*;
import netP5.*;
import oscP5.*;

import hypermedia.net.*;  

import java.net.*;
import java.util.*;

import processing.data.JSONObject;

ControlP5 cp5;

boolean noDraw = false;
boolean showFps = false;
boolean showInfo = false;
Map<String, Device> devs = new HashMap<String, Device>();
String cur = "";

// osc
OscP5 oscP5;
String listenIP;
int listenPort = 57121;
String outPrefix = "/out";
NetAddress forwardAddr;

String getLocalIPAddress() {
  try {
    Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
    while (interfaces.hasMoreElements()) {
      NetworkInterface iface = interfaces.nextElement();
      String name = iface.getName().toLowerCase();
      String displayName = iface.getDisplayName().toLowerCase();
      if (iface.isLoopback() || iface.isVirtual() || !iface.isUp() || iface.getHardwareAddress() == null) continue;
      if (name.contains("br") || name.contains("bridge") || displayName.contains("bridge")) continue;

      Enumeration<InetAddress> addresses = iface.getInetAddresses();
      while (addresses.hasMoreElements()) {
        InetAddress addr = addresses.nextElement();
        if (addr instanceof Inet4Address && !addr.isLoopbackAddress()) {
          return addr.getHostAddress();
        }
      }
    }
  } catch (SocketException e) {
    e.printStackTrace();
  }
  return "";
}

void settings() {
  size(displayWidth, displayHeight, P3D);
  //fullScreen(P3D);
}

void setup() {
  surface.setResizable(true);
  surface.setLocation(0, 0);
  
  loadData();
    
  oscP5 = new OscP5(this, listenPort);
  forwardAddr = new NetAddress("127.0.0.1", 57120);
  listenIP = getLocalIPAddress();;
  
  cp5 = new ControlP5(this);
}

void loadData() {
  // todo: implement loading and saving device configurations
  //JSONObject data = loadJSONObject("data.json");
  //JSONObject devices = json.getJSONArray("devices");
  //for (JSONObject device : devcices) {
    
  //}
  
  //// Polar H10
  devs.put("7E37D222", new Device("7E37D222", "/7E37D222", outPrefix, new HashMap<SensorType, SensorDisplay>(){{
      put(SensorType.ACC, new AccDisplay(0, 20, width/2, height/2 - 20, GravityMethod.HIGHPASS, 500, 2, 981));
      EulerDisplay euler = new EulerDisplay(width/2, 20, width/2, height - 40, 500);
      put(SensorType.EULER, euler);
      QuatDisplay quat = new QuatDisplay(width/2, 20, width/2, height - 40, 500);
      quat.visible = false;
      put(SensorType.QUAT, quat);
      put(SensorType.HR, new HRDisplay(0, height/2, width/4, height/2 - 20, 0, 50));
      put(SensorType.ECG, new ECGDisplay(width/4, height/2, width/4, height/2 - 20, 500));
  }}));
  
  //devs.put("m5StickC", new Device("m5StickC", "/m5stickc", outPrefix, new HashMap<SensorType, SensorDisplay>(){{
  //    put(SensorType.ACC, new AccDisplay());
  //    //EulerDisplay euler = new EulerDisplay(true);
  //    //euler.visible = false;
  //    //put(SensorType.EULER, euler);
  //    put(SensorType.QUAT, new QuatDisplay());
  //    put(SensorType.GYRO, new GyroDisplay());
  //}}));
  
  //if (devs.size() > 0) {
  //  cur = devs.keySet().iterator().next();
  //}
}

void update() {
  for (Device dev : devs.values()) {
    dev.update();
  }
}

void draw() {
  background(0);

  update();

  if (noDraw) {
    return;
  }
  
  if (devs.size() > 0 && !cur.equals("")) {
    Device dev = devs.get(cur);
    pushStyle();
    textSize(13);
    dev.drawSensors();
    popStyle();
    
    if (dev.isPlaying && dev.playMinMs > -1) {
      long dur = (dev.playMaxMs - dev.playMinMs);
      pushStyle();
      fill(255);
      textSize(14);
      text((dev.playPos % dur) + " / " + dur + (dev.isPaused ? " paused" : ""), width/2 + 20, height - 15);
      popStyle();
    }
    
    int i=0;
    for (Device dev1 : devs.values()) {
      dev1.draw(i, dev1 == dev, cp5);
      i++;
    }
  }
  else {
    pushStyle();
    fill(255);
    textSize(36); 
    textAlign(CENTER);
    text("Waiting for data on " + listenIP + ":" + listenPort, width/2, height/2);
    textSize(14); 
    text("'/deviceId/acc' (x y z)", width/2, height/2+40);
    text("'/deviceId/gyro' (x y z)", width/2, height/2+60);
    text("'/deviceId/mag' (x y z)", width/2, height/2+80);
    text("'/deviceId/altitude' (value)", width/2, height/2+100);
    text("'/deviceId/comp' (heading in radians)", width/2, height/2+120);
    text("'/deviceId/ecg' (value)", width/2, height/2+140);
    text("'/deviceId/hr' (heartrate)", width/2, height/2+160);
    text("'/deviceId/euler' (roll pitch yaw)", width/2, height/2+180);
    text("'/deviceId/quat' (w x y z)", width/2, height/2+200);
    popStyle();
  }
  
  if (showFps) {
    drawFps();
  }
  
  if (showInfo) {
    drawInfo();
  }
}

void drawFps() {
  pushStyle();
  fill(255);
  textSize(12);
  text(round(frameRate)+"fps", width - 50, height - 15);
  popStyle();
}

void drawInfo() {
  pushStyle();
  background(0);
  //fill(0, 127); // does not overlay strokes (lines)
  //rect(0, 0, width, height);
  fill(255);
  List<String> keys = Arrays.asList("1 to 9", "r", "o", "space", "p", "s", "i", "f", "n");
  List<String> infos = Arrays.asList("switch device", "start/stop recording", "open folder for playback", "play/pause", "start playing", "stop playing",  "show/hide info", "show/hide fps", "show/hide gui");
  List<String> keys2 = Arrays.asList("u", "q", "e");
  List<String> infos2 = Arrays.asList("set device fusion type", "show hide quat view", "show/hide euler view");
  List<String> keys3 = Arrays.asList("left click", "f", "t", "m", "v");
  List<String> infos3 = Arrays.asList("select/unselect sensor", "set filter type", "set transform type", "reset min/max", "show/hide sensor");
  pushMatrix();
  translate(0, 0);
  textSize(20);
  text("Global commands", 30, 30);
  drawCommands(keys, infos);
  translate(350, 0);
  textSize(20);
  text("Device commands", 30, 30);
  drawCommands(keys2, infos2);
  translate(350, 0);
  textSize(20);
  text("Sensor commands", 30, 30);
  drawCommands(keys3, infos3);
  popMatrix();
  popStyle();
}

void drawCommands(List<String> keys, List<String> infos) {
  for (int i=0; i<keys.size(); i++) {           
    String key = keys.get(i);
    String info = infos.get(i);
    textSize(18);
    text(key, 30, (i+2)*30);
    text(info, 120, (i+2)*30);
  }
}

void oscEvent(OscMessage msg) {
  String prefix = getOscPrefix(msg.addrPattern());
  String deviceId = prefix.replaceAll("^/", "");
  if (deviceId.equals("")) {
    print("Received an osc message without an address");
    return;
  }
  String ip = msg.address();
  try {
    getOrCreateDevice(deviceId, prefix, ip).oscEvent(msg);
  } catch (Exception e) {
    e.printStackTrace();
  }
}

String getOscPrefix(String addrPattern) {
  int offset = addrPattern.charAt(0) == '/' ? 1 : 0;
  int index = addrPattern.indexOf("/", offset);
  if (index > -1) {
    return addrPattern.substring(0, index);
  }
  return addrPattern;
}

Device getOrCreateDevice(String deviceId, String inPrefix, String ip) {
  if (devs.get(deviceId) != null && devs.get(deviceId).ip != null && !devs.get(deviceId).ip.equals("") && !devs.get(deviceId).ip.equals(ip)) {
    deviceId = deviceId + "-" + ip;
  }
  if (devs.get(deviceId) == null) {
    Device dev = new Device(deviceId, inPrefix, outPrefix, new HashMap<SensorType, SensorDisplay>(){{
      
    }});
    dev.ip = ip;
    devs.put(deviceId, dev);
    if (cur.equals("")) {
      cur = deviceId;
    }
  }
  return devs.get(deviceId);
}

void openFolder(File folder) {
  if (folder != null) {
    for (File file : folder.listFiles()) {
      String fileName = file.getName();
      if (fileName.substring(fileName.length()-3).toLowerCase().equals("csv")) {
        String deviceId = fileName.substring(0, fileName.lastIndexOf('_'));
        Table table = loadTable(file.getPath(), "tsv");
        String addrPattern = table.getString(0, 0);
        getOrCreateDevice(deviceId, getOscPrefix(addrPattern), "").openFile(file);
      }
    }
    syncPlayback();
  }
}

void syncPlayback() {
  long minMs = -1, maxMs = -1;
  for (Device dev : devs.values()) {
    if (dev.isPlaying) {
      long[] minMaxMs = dev.getMinMaxMs();
      if (minMs == -1 || minMaxMs[0] < minMs) {
        minMs = minMaxMs[0];
      }
      if (maxMs == -1 || minMaxMs[1] > maxMs) {
        maxMs = minMaxMs[1];
      }
    }
  }
  for (Device dev : devs.values()) {
    if (dev.isPlaying) {
      dev.playMinMs = minMs;
      dev.playMaxMs = maxMs;
    }
  }
}

void toggleMenu(float val) {
  for (Device dev : devs.values()) {
    if (dev.toggleMenu(val)) {
      break;
    }
  }
}

void mouseClicked() {
  if (devs.size() > 0) {
    devs.get(cur).mouseClicked();
  }
}

void keyPressed() {
  if (key >= '1' && key <= '9' && key - '1' < devs.size()) {
    cur = (new ArrayList<String>(devs.keySet())).get(key - '1');
    return;
  }
  if (key == 'o') {
    selectFolder("Select a folder to process:", "openFolder");
    return;
  }
  if (key == 'i') {
    showInfo = !showInfo;
    return;
  }
  if (key == 'd') {
    showFps = !showFps;
    return;
  }
  if (key == 'n') {
    noDraw = !noDraw;
    return;
  }
  if (keyCode == SHIFT || key == ' ') {
    for (Device dev : devs.values()) {
      dev.keyPressed();
    }
  }
  else if (devs.size() > 0 && !cur.equals("")) {
    devs.get(cur).keyPressed();
  }
}

void buildBoxShape() {
  noStroke();
  beginShape(QUADS);

  //Z+ (to the drawing area)
  fill(#00ff00);
  vertex(-30, -5, 20);
  vertex(30, -5, 20);
  vertex(30, 5, 20);
  vertex(-30, 5, 20);

  //Z-
  fill(#0000ff);
  vertex(-30, -5, -20);
  vertex(30, -5, -20);
  vertex(30, 5, -20);
  vertex(-30, 5, -20);

  //X-
  fill(#ff0000);
  vertex(-30, -5, -20);
  vertex(-30, -5, 20);
  vertex(-30, 5, 20);
  vertex(-30, 5, -20);

  //X+
  fill(#ffff00);
  vertex(30, -5, -20);
  vertex(30, -5, 20);
  vertex(30, 5, 20);
  vertex(30, 5, -20);

  //Y-
  fill(#ff00ff);
  vertex(-30, -5, -20);
  vertex(30, -5, -20);
  vertex(30, -5, 20);
  vertex(-30, -5, 20);

  //Y+
  fill(#00ffff);
  vertex(-30, 5, -20);
  vertex(30, 5, -20);
  vertex(30, 5, 20);
  vertex(-30, 5, 20);

  endShape();
}

float heading3D(PVector v) {
  float rho = sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2));
  return acos(v.z/rho);
}
 
// calculate eurler angles from accelerometer vector
// the conversion is affected by regions of instability, see:
// http://www.cas.mcmaster.ca/~rzheng/course/CAS765fa13/YueSun.pdf
PVector eulerAngles(PVector value, boolean restrictPitch) {
  float roll, pitch;

  // restrict pitch or roll to -90 to 90
  // todo: check EulerDisplay.glPrevent
  if (restrictPitch) {
    roll  = atan2(value.y, value.z);
    pitch = atan(-value.x / sqrt(value.y * value.y + value.z * value.z));
  }
  else {
    roll  = atan(value.y / sqrt(value.x * value.x + value.z * value.z));
    pitch = atan2(-value.x, value.z);
  }
  
  return new PVector(roll, pitch);
}

PVector eulerAngles(PVector value) {
  return eulerAngles(value, false);
}

void plot3D(float size) {
  float half = size / 2.0;
  pushStyle();
  stroke(0, 0, 255);
  line(-half, 0, 0, half, 0, 0);
  stroke(0, 255, 0);
  line(0, -half, 0, 0, half, 0);
  stroke(255, 0, 0);
  line(0, 0, - half, 0, 0, half);
  popStyle();
}

void compass2D(PVector vector, float d, boolean useRect) {
  PVector mult = PVector.mult(vector, d/2);
  pushStyle();
  noFill();
  stroke(255);
  if (useRect) {
    rect(-d/2, -d/2, d, d);
  }
  else {
    ellipse(0, 0, d, d);
  }
  stroke(255, 0, 0);
  line(0, 0, mult.x, mult.y);
  popStyle();
}

void compass2D(PVector vector, float d) {
  compass2D(vector, d, false);
}

PVector squircle(PVector v) {
  float sqx = v.x * v.x;
  float sqy = v.y * v.y;
  float sum = sqx + sqy;
  float sq = sqrt(sum);
  if (sqx >= sqy) {
      float sign = Math.signum(v.x);
      return new PVector(sign * sq, sign * sq * v.y / v.x);
  }
  else {
      float sign = Math.signum(v.y);
      return new PVector(sign * sq * v.x / v.y, sign * sq);
  }
}

<T>void plot2D(T[] hist, float w, float h, int k) {
  float mw = w / hist.length;
  beginShape();
  for (int i=0; i<hist.length; i++) {
    int j = (i+k+1) % hist.length;
    if (hist[j] != null) {
      float value = (float) hist[j];
      vertex(i*mw, value * h);
    }
  }
  endShape();
}

<T>void plotVectors(ArrayList<PVector> hist, float w, float h, int k, PVector maxVal) {
  Float[] x = new Float[hist.size()];
  Float[] y = new Float[hist.size()];
  Float[] z = new Float[hist.size()];
  for (int i=0; i<hist.size(); i++) {
    PVector val = hist.get(i);
    if (val != null) {
      x[i] = -val.x / maxVal.x;
      y[i] = -val.y / maxVal.y;
      z[i] = -val.z / maxVal.z;
    }
  }
  
  // x
  pushStyle();
  noFill();
  stroke(255, 0, 0);
  plot2D(x, w - 40, h/2, k);
  popStyle();
  
  // y
  pushStyle();
  noFill();
  stroke(0, 255, 0);
  plot2D(y, w - 40, h/2, k);
  popStyle();
  
  // z
  pushStyle();
  noFill();
  stroke(0, 0, 255);
  plot2D(z, w - 40, h/2, k);
  popStyle();
}

<T>void plotMagnitude(T[] hist, float w, float h, int k) {
  float mw = w / hist.length;
  pushStyle();
  noFill();
  stroke(255);
  beginShape();
  for (int i=0; i<hist.length; i++) {
    int j = (i+k+1) % hist.length;
    if (hist[j] != null) {
      float mag;
      if (hist[j] instanceof PVector) {
        mag = ((PVector) hist[j]).mag();
      }
      else {
        mag = (float) hist[j];
      }
      vertex(i*mw, mag * h);
    }
  }
  endShape();
  popStyle();
}

<T>void plotMagnitude(T[] hist, float w, float h) {
  plotMagnitude(hist, w, h, 0);
}

void windowResized() {
  resizeSensors();
}

void resizeSensors() {
  for (Device dev : devs.values()) {
    dev.resizeSensors();
  }
}
