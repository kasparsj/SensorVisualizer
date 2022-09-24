public class HRDisplay extends SensorDisplay<Float> {
  
  HRDisplay(float x, float y, float w, float h, int avgLen, int histLen) {
    super(x, y, w, h);
    type = SensorType.HR;
    enableHistory(histLen);
    enableAverage(avgLen);
  }
  
  HRDisplay() {
    this(0, height/2, width/4, height/2, 0, 50);
  }
  
  void updateAvg() {
    float sum = 0;
    int count = 0;
    for (int i=(avgLen-1); i>=0; i--) {
      Float val = values.get(i > histCursor ? histLen + (histCursor-i): histCursor-i);
      if (val != null) {
        sum += val;
        count++;
      }
    }
    avgValue = sum / count;
  }

  //float w = width / 4;
  //float h = height / 2;
  void draw(float w, float h) {
    if (value == null) return;

    pushStyle();  
    fill(255);
    text("hr (pps: "+ups+")", w - 70, 20);
    if (avgLen > 0) {
      text("avg/"+avgLen+" "+nf(avgValue, 0, 2), 20, 20);
      textSize(72);
      textMode(SHAPE);
      text(nf(avgValue, 0, 2), w/2-100, 70);
    }    
    else {
      textSize(72);
      textMode(SHAPE);
      text(nf(value, 0, 2), w/2-100, 70);
    }
    
    Float[] hrs = new Float[values.size()];
    for (int i=0; i<hrs.length; i++) {
      hrs[i] = values.get(i) != null ? values.get(i) / 220F : null; 
    }
    pushMatrix();
    translate(20, h - 20);
    noFill();
    stroke(255);
    plot2D(hrs, w - 40, -h + 80, histCursor);
    popMatrix();
    popStyle();
  }
  
  void oscEvent(OscMessage msg) {
    float val;
    if (msg.typetag().charAt(1) == 'i') {
      val = (float) msg.get(1).intValue();
    }
    else {
      val = msg.get(1).floatValue();
    }
    update(val);

    if (avgLen > 0) {
      OscMessage fw = new OscMessage("/hr/avg");
      fw.add(device.id);
      fw.add(avgValue);
      oscP5.send(fw, supercollider);
    }
  }
}
