public class EulerDisplay extends SensorDisplay<PVector> {
  
  EulerDisplay(float x, float y, float w, float h, int histLen) {
    super(x, y, w, h);
    type = SensorType.EULER;
    enableHistory(histLen);
  }
  
  EulerDisplay() {
    this(width/2, 0, width/2, height, 500);
  }
  
  void draw(float w, float h) {
    PVector angles;
    if (value == null) {
      angles = device.getEulerAngles();
      updateHist(angles, null);
    }
    else {
      angles = value.copy();
    }
    if (angles == null) {
      return;
    }
    
    pushStyle();
    fill(255);
    text("euler", 20, 20);
    text("(pps: "+ups+")", w - 70, 20);
    popStyle();
    
    drawAngles(angles, w/3, h/4);
    
    pushMatrix();
    translate(0, h/4);
    drawHist(angles, w / 3, h/4);
    popMatrix();
    
    pushMatrix();
    translate(0, h/2);
    drawCube(angles, w, h/2);
    popMatrix();
  }
  
  void drawAngles(PVector angles, float w, float h) {
    float d = min(w, h)-20;
    
    pushStyle();
    fill(255);
    text("roll "+nf(angles.x, 0, 2), 20, height / 4-20);
    text("pitch "+nf(angles.y, 0, 2), w+20, height / 4-20);
    text("yaw "+nf(angles.z, 0, 2), 2*w+20, height / 4-20);
  
    // roll
    pushMatrix();
    translate(w/2, h/2);
    pushStyle();
    noFill();
    stroke(255);
    ellipse(0, 0, d, d);
    stroke(255, 0, 0);
    rotate(angles.x);
    line(-d/2, 0, d/2, 0);
    popStyle();
    popMatrix();
      
    // picth
    pushMatrix();
    translate(w + w/2, h/2);
    pushStyle();
    noFill();
    stroke(255);
    ellipse(0, 0, d, d);
    stroke(255, 0, 0);
    rotate(angles.y);
    line(-d/2, 0, d/2, 0);
    popStyle();
    popMatrix();
  
    // yaw
    pushMatrix();
    translate(w + w + w/2, h/2);
    pushStyle();
    noFill();
    stroke(255);
    ellipse(0, 0, d, d);
    stroke(255, 0, 0);
    rotate(angles.z);
    line(-d/2, 0, d/2, 0);
    popStyle();
    popMatrix();
    
    popStyle();
  }
  
  private void drawHist(PVector angles, float w, float h) {
    Float rolls[] = new Float[histLen];
    Float pitches[] = new Float[histLen];
    Float yaws[] = new Float[histLen];
    for (int i=0; i<values.size(); i++) {
      PVector val = values.get(i);
      if (val != null) {
        rolls[i] = values.get(i).x / TWO_PI;
        pitches[i] = values.get(i).y / TWO_PI;
        yaws[i] = values.get(i).z / TWO_PI;
      }
      else {
        rolls[i] = 0F;
        pitches[i] = 0F;
        yaws[i] = 0F;
      }
    }
    
    // roll hist
    pushMatrix();
    translate(20, h/2, 0);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(rolls, w - 40, h, histCursor);
    popStyle();
    popMatrix();
    
    // pitch hist
    pushMatrix();
    translate(w + 20, h/2, 0);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(pitches, w - 40, h, histCursor);
    popStyle();
    popMatrix();
    
    // yaw hist
    pushMatrix();
    translate(2*w + 20, h/2, 0);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(yaws, w - 40, h, histCursor);
    popStyle();
    popMatrix();
  }
  
  private void drawCube(PVector angles, float w, float h) {    
    pushStyle();
    fill(255);
    text("euler (pps: "+(angles != null ? ups : 0)+")", w - 120, 20);
    
    
    pushMatrix();
    translate(w/2 - 50, h/2);
    scale(4, 4, 4);
    
    // the order is important!
    rotateX(angles.y); // pitch
    rotateZ(-angles.x); // roll
    rotateY(angles.z); // yaw
    
    buildBoxShape();
    
    popMatrix();
  
    popStyle();
  }
  
  void oscEvent(OscMessage msg) {
    int numArgs = msg.typetag().length();
    if ((numArgs-1) % 3 == 0) {
      for (int i=0; i<(numArgs-1) / 3; i++) {
        PVector val = new PVector(msg.get(1+i*3).floatValue(), msg.get(2+i*3).floatValue(), msg.get(3+i*3).floatValue());
        if (msg.addrPattern().substring(oscPrefix.length()).equals("/euler_deg")) { //<>// //<>//
          val.x = radians(val.x);
          val.y = radians(val.y);
          val.z = radians(val.z);
        }
        update(val);
        
        OscMessage fw = new OscMessage("/euler");
        fw.add(device.id);
        fw.add(value.x);
        fw.add(value.y);
        fw.add(value.z);
        oscP5.send(fw, supercollider);
      }
    }
  }
}
