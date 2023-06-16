public class QuatDisplay extends RotationStats {
  
  QuatDisplay(int firstArg, float x, float y, float w, float h, int histLen) {
    super(firstArg, x, y, w, h, histLen);
    type = SensorType.QUAT;
    addr = "/quat";
  }
  
  QuatDisplay(int firstArg) {
    this(firstArg, width/4 * 3, 0, width/4, height, 500);
  }
  
  QuatDisplay() {
    this(1);
  }
  
  void update(Quaternion val) {
    if (value != null) {
      val.preventFlip(value);
    }
    super.update(val);
  }
  
  void draw(float w, float h) {
    Quaternion quat = null;
    if (value == null || device.fusion != null) {
      PVector euler = device.getEulerAngles();
      if (euler != null) {
        quat = (new Quaternion()).fromEuler(euler);
        if (histLen > 0) {
          if (prevVal() != null) {
            quat.preventFlip(prevVal());
          }
          if (!(device.isPlaying && device.isPaused)) {
            updateHist(quat, null);
          }
        }
      }
    }
    else {
      quat = value.copy();
    }
    if (quat == null) {
      return;
    }
    
    pushMatrix();
    translate(0, 0);
    drawProjections(w, h/4);
    popMatrix();
    
    pushMatrix();
    translate(0, h/4);
    drawProjectionHistory(w/3, h/4);
    popMatrix();
    
    pushMatrix();
    translate(0, h/2);
    drawCube(quat, w, h/2);
    popMatrix();
  }
  
  private void drawProjections(float w, float h) {
    float d = min(w/3, h)-20;
    
    pushMatrix();
    translate(20, 0);
    pushStyle();
    fill(255);
    text("xzProj", 0, 20);
    text("yxProj", w/3, 20);
    text("zyProj", 2*w/3, 20);
    
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
    pushMatrix();
    translate(20, 0);
    pushStyle();
    fill(255);
    text("xzHist", 0, 0);
    text("yxHist", w, 0);
    text("zyHist", 2*w, 0);
    popStyle();
    popMatrix();
    
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
    translate(0, h/2);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(xzheading, w - 40, h - 40, histCursor);
    popStyle();
    translate(0, -h/2);
    plotMagnitude(xz, w - 40, h - 40, histCursor);
    popMatrix();
    
    // yxHist
    pushMatrix();
    translate(w, h/2);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(yxheading, w - 40, h - 40, histCursor);
    popStyle();
    translate(0, -h/2);
    plotMagnitude(yx, w - 40, h - 40, histCursor);
    popMatrix();
    
    // zyHist
    pushMatrix();
    translate(2*w, h/2);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(zyheading, w - 40, h - 40, histCursor);
    popStyle();
    translate(0, -h/2);
    plotMagnitude(zy, w - 40, h - 40, histCursor);
    popMatrix();
  }
  
  private void drawCube(Quaternion quat, float w, float h) {
    pushStyle();
    fill(255);
    text("quats " + filterType + (device.fusion != null ? " fusion: " + device.fusion.type : ""), 20, 20);
    text("(pps: "+ups+")", w - 70, 20);
    popStyle();
    
    pushMatrix();
    translate(w/2 - 50, h/2);
    scale(4, 4, 4);
    
    if (quat != null) {
      Matrix4x4 m = quat.toMatrix();
      applyMatrix(m.val(0, 0), m.val(0, 1), m.val(0, 2), m.val(0, 3),
        m.val(1, 0), m.val(1, 1), m.val(1, 2), m.val(1, 3),
        m.val(2, 0), m.val(2, 1), m.val(2, 2), m.val(2, 3),
        m.val(3, 0), m.val(3, 1), m.val(3, 2), m.val(3, 3));
    }

    buildBoxShape();
    popMatrix();
  }
  
  PVector getOrigEulerAngles() {
    if (value == null) {
      return null;
    }
    return value.toEuler();
  }
}
