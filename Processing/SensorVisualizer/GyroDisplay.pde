public class GyroDisplay extends VectorDisplay {
  
  GyroDisplay(float x, float y, float w, float h, int histLen, int deltaSumWin) {
    super(x, y, w, h, histLen);
    enableMagnitude(deltaSumWin);
  }
  
  GyroDisplay() {
    this(width/2, 0, width/2, height, 500, 2);
  }

  void draw(float w, float h) {
    if (value == null) return;
    
    pushMatrix();
    pushStyle();
    translate(w, 0);
    noFill();
    stroke(64);
    rect(0, 0, w, h);
  
    float mag = (mag() / maxMag);
    fill(255);
    text("gyroscope (pps: "+ups+")", w - 125, 20);
    text("mag "+filterType, 20, 20);
    rect(20, 30, mag * (w - 40), 10);
    text(nf(magPerc(), 0, 2), 20, 55);
  
    PVector force = val().normalize().mult(mag * (w / 4));
    pushMatrix();
    translate(w/2, h/4, 0);
    plot3D(w / 2);
    stroke(255);
    line(0, 0, 0, force.x, force.y, force.z);
    popMatrix();
    
    pushMatrix();
    translate(20, h - 20, 0);
    plotMagnitude(magPerc, w - 40, -h/2 + 40);
    popMatrix();
  
    popStyle();
    popMatrix();
  }
  
  void oscEvent(OscMessage msg) {
    update(new PVector(msg.get(1).floatValue(), msg.get(2).floatValue(), msg.get(3).floatValue()));

    OscMessage fw = new OscMessage("/gyro/mag");
    fw.add(device.id);
    fw.add(mag());
    fw.add(magPerc());
    fw.add(magDeltaSum);
    fw.add(magDeltaSumPerc());
    oscP5.send(fw, supercollider);
  }
}
