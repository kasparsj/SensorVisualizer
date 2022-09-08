public class QuatDisplay extends RotationStats {
  
  QuatDisplay(float x, float y, float w, float h, int histLen) {
    super(x, y, w, h, histLen);
  }
  
  QuatDisplay() {
    this(width / 2, 0, width/2, height, 500);
  }
  
  void draw(float w, float h) {
    if (value == null) return; 
    
    pushMatrix();
    translate(0, 0);
    drawProjections(w, h/4);
    popMatrix();
    
    pushMatrix();
    translate(0, h/4);
    drawProjectionHistory(w, h/4);
    popMatrix();
    
    pushMatrix();
    translate(0, h/2);
    drawCube(w, h/2);
    popMatrix();
  }
  
  private void drawProjections(float w, float h) {
    float d = min(w/3, h);
    
    pushMatrix();
    translate(0, 20);
    pushStyle();
    fill(255);
    text("xzProj", 20, 0);
    text("yxProj", w + 45, 0);
    text("zyProj", 2*w + 70, 0);
    
    // xzProj
    pushMatrix();
    translate(d/2, h/2);
    compass2D(projXZ(), d);
    popMatrix();
    
    // yxProj
    pushMatrix();
    translate(w/3+d/2, h/2);
    compass2D(projYX(), d);
    popMatrix();
    
    // zyProj
    pushMatrix();
    translate(w/3*2+d/2, h/2);
    compass2D(projZY(), d);
    popMatrix();
    
    popStyle();
    popMatrix();
  }
  
  private void drawProjectionHistory(float w, float h) {
    float d = min(w, h);
    
    //noFill();
    //stroke(64);
    //rect(width / 2, height / 4, width / 2, height / 4);
  
    pushMatrix();
    translate(0, h/4 + 20);
    pushStyle();
    fill(255);
    text("xzHist", 20, 0);
    text("yxHist", w + 45, 0);
    text("zyHist", 2*w + 70, 0);
    popStyle();
    
    pushMatrix();
    translate(0, h-20);
    
    Float[] xzheading = new Float[histLen];
    Float[] yxheading = new Float[histLen];
    Float[] zyheading = new Float[histLen];
    for (int i=0; i<histLen; i++) {
      if (xz[i] != null) {
        xzheading[i] = xz[i].heading() / TWO_PI;
        yxheading[i] = yx[i].heading() / TWO_PI;
        zyheading[i] = zy[i].heading() / TWO_PI;
      }
    }
    
    // xzHist
    pushMatrix();
    translate(25, h/2);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(xzheading, w, -h + 40, histCursor);
    popStyle();
    plotMagnitude(xz, w, -h + 40);
    popMatrix();
    
    // yxHist
    pushMatrix();
    translate(w + 50, h/2);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(yxheading, w, -h + 40, histCursor);
    popStyle();
    plotMagnitude(yx, w, -h + 40);
    popMatrix();
    
    // zyHist
    pushMatrix();
    translate(2*w + 75, h/2);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(zyheading, w, -h + 40, histCursor);
    popStyle();
    plotMagnitude(zy, w, -h + 40);
    popMatrix();
    
    popMatrix();
    popMatrix();
  }
  
  private void drawCube(float w, float h) {
    pushMatrix();
    pushStyle();
  
    fill(255);
    text("quats (pps: "+(value != null ? ups : 0)+")", w - 120, 20);
    if (prevVal() != null) {
      Quaternion qd = value.difference(prevVal());
      if (qd != null) {
        float angle = qd.angle();
        float mag = (angle / (PI / 10.0));
        text("mag", 20, 20);
        rect(20, 30, mag * (w - 20), 10);
        text(nf(mag, 0, 2), 20, 55);
      }
    }
    
    
    pushMatrix();
    translate(w/2 - 50, h/2);
    scale(4, 4, 4);
    
    if (value != null) {
      // this works with DMP quats
      PVector angles;
      angles = value.toEuler();
      // the order is important!
      rotateZ(-angles.x); // roll
      rotateX(-angles.y); // pitch
      rotateY(angles.z); // yaw
    }

    buildBoxShape();
    popMatrix();
  
    popStyle();
    popMatrix();
  }
  
  void oscEvent(OscMessage msg) {
    update(new Quaternion(msg.get(1).floatValue(), msg.get(2).floatValue(), msg.get(3).floatValue(), msg.get(4).floatValue()));
    
    OscMessage fw;
    PVector projXZ = projXZ();
    fw = new OscMessage("/quat/projXZ");
    fw.add(device.id);
    fw.add(projXZ.x);
    fw.add(projXZ.y);
    fw.add(projXZ.mag());
    fw.add(projXZ.heading());
    oscP5.send(fw, supercollider);
    
    PVector projYX = projYX();
    fw = new OscMessage("/quat/projYX");
    fw.add(device.id);
    fw.add(projYX.x);
    fw.add(projYX.y);
    fw.add(projYX.mag());
    fw.add(projYX.heading());
    oscP5.send(fw, supercollider);

    PVector projZY = projZY();
    fw = new OscMessage("/quat/projZY");
    fw.add(device.id);
    fw.add(projZY.x);
    fw.add(projZY.y);
    fw.add(projZY.mag());
    fw.add(projZY.heading());
    oscP5.send(fw, supercollider);
  }
}
