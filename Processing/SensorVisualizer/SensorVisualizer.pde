//import controlP5.*;
import netP5.*;
import oscP5.*;

import hypermedia.net.*;

import java.util.Map;
import java.util.HashMap;
import java.util.stream.*;

// objects etc.
//ControlP5 cp5;
Map<String, Device> devs = new HashMap<String, Device>();
String cur = "";

// osc
OscP5 oscP5; 
int listenPort = 57121;
String outPrefix = "/out";
NetAddress forwardAddr;

void setup() {
  //size(1000, 600, P3D);
  fullScreen(P3D);

  oscP5 = new OscP5(this, listenPort);
  forwardAddr = new NetAddress("127.0.0.1", 57120);
  
  // Polar H10
  devs.put("7E37D222", new Device("7E37D222", "/polar", outPrefix, 1, new HashMap<SensorType, SensorDisplay>(){{
      put(SensorType.ACC, new AccDisplay(1, 0, 0, width/2, height/2, GravityMethod.HIGHPASS, 500, 2, 981));
      put(SensorType.EULER, new EulerDisplay(1, width/2, 0, width/2, height, 500));
      put(SensorType.HR, new HRDisplay(1, 0, height/2, width/4, height/2, 0, 50));
      put(SensorType.ECG, new ECGDisplay(1, width/4, height/2, width/4, height/2, 500));
  }}));
  devs.put("GyrOSC", new Device("GyrOSC", "/gyrosc", outPrefix, 0, new HashMap<SensorType, SensorDisplay>(){{
      put(SensorType.ACC, new AccDisplay(0));
      put(SensorType.GYRO, new AccDisplay(0));
      put(SensorType.QUAT, new QuatDisplay(0));
      put(SensorType.MAG, new MagDisplay(0));
      put(SensorType.COMP, new CompDisplay(0));
      put(SensorType.ALTITUDE, new AltitudeDisplay(0, false));
  }}));
  cur = devs.keySet().iterator().next();
  
  //setupGui();
}

void setupGui() {
  //cp5 = new ControlP5(this);
}

void update() {
  for (Device dev : devs.values()) {
    dev.update();
  }
}

void draw() {
  background(0);

  update();

  Device dev = devs.get(cur);
  dev.drawSensors();
  
  if (dev.isPlaying && dev.playMinMs > -1) {
    long dur = (dev.playMaxMs - dev.playMinMs);
    pushStyle();
    fill(255);
    textSize(12);
    text((dev.playPos % dur) + " / " + dur + (dev.isPaused ? " paused" : ""), width/2 + 20, height - 15);
    popStyle();
  }
  
  int i=0;
  for (Device dev1 : devs.values()) {
    dev1.drawTab(i, dev1 == dev);
    i++;
  }

  pushStyle();
  fill(255);
  textSize(12);
  text(round(frameRate)+"fps", width - 50, height - 15);
  popStyle();
}

void oscEvent(OscMessage msg) {
  if (isGyrOsc(msg.addrPattern())) {
    String deviceId = "GyrOSC";
    getOrCreateDevice(deviceId, "/gyrosc", 0).oscEvent(msg);
    
  }
  else if (msg.typetag().charAt(0) == 's') {
    String deviceId = msg.get(0).stringValue();
    getOrCreateDevice(deviceId, getOscPrefix(msg.addrPattern()), 1).oscEvent(msg);
  }
}

String getOscPrefix(String addrPattern) {
  return addrPattern.substring(0, addrPattern.indexOf("/", 1));
}

boolean isGyrOsc(String addrPattern) {
  return addrPattern.substring(0, 7).equals("/gyrosc");
}

Device getOrCreateDevice(String deviceId, String inPrefix, int firstArg) {
  if (devs.get(deviceId) == null) {
    devs.put(deviceId, new Device(deviceId, inPrefix, outPrefix, firstArg, new HashMap<SensorType, SensorDisplay>(){{
      
    }}));
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
        getOrCreateDevice(deviceId, getOscPrefix(addrPattern), isGyrOsc(addrPattern) ? 0 : 1).openFile(file);
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

void mouseClicked() {
  devs.get(cur).mouseClicked();
}

void keyPressed() {
  if (key >= '1' && key <= '3' && key - '1' < devs.size()) {
    cur = (new ArrayList<String>(devs.keySet())).get(key - '1');
    return;
  }
  if (key == 'o') {
    selectFolder("Select a folder to process:", "openFolder");
    return;
  }
  if (keyCode == SHIFT || key == ' ') {
    for (Device dev : devs.values()) {
      dev.keyPressed();
    }
  }
  else {
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

void compass2D(PVector vector, float d) {
  PVector mult = PVector.mult(vector, d/2);
  pushStyle();
  noFill();
  stroke(255);
  ellipse(0, 0, d, d);
  stroke(255, 0, 0);
  line(0, 0, mult.x, mult.y);
  popStyle();
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
  plot2D(x, w - 40, h, k);
  popStyle();
  
  // y
  pushStyle();
  noFill();
  stroke(0, 255, 0);
  plot2D(y, w - 40, h, k);
  popStyle();
  
  // z
  pushStyle();
  noFill();
  stroke(0, 0, 255);
  plot2D(z, w - 40, h, k);
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
