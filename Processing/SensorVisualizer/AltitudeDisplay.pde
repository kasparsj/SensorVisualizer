public class AltitudeDisplay extends SensorDisplay<Float> {
  
  float minAlt = 20000;
  float maxAlt = -20000;
  Float percAlt[];
  
  AltitudeDisplay(float x, float y, float w, float h, int avgLen, int histLen) {
    super(x, y, w, h);
    enableHistory(histLen);
    enableAverage(avgLen);
  }
  
  AltitudeDisplay() {
    this(0, height/2, width/4, height/2, 0, 50);
  }
  
  AltitudeDisplay enableHistory(int histLen) {
    super.enableHistory(histLen);
    if (histLen > 0) {
      percAlt = new Float[histLen];
    }
    return this;
  }
  
  void update(Float val) {
    super.update(val);
    if (value < minAlt) {
      minAlt = value;
    }
    if (value > maxAlt) {
      maxAlt = value;
    }
    percAlt[histCursor] = (value - minAlt) / (maxAlt - minAlt);
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
    if (percAlt[histCursor] == null) return;

    pushMatrix();
    pushStyle();
    translate(0, h);
    noFill();
    stroke(64);
    rect(0, 0, w, h);
  
    fill(255);
    text("avg/"+avgLen+" "+nf(avgValue, 0, 2)+(ups > 0 ? " ("+nf(minAlt, 0, 2)+", "+nf(maxAlt, 0, 2)+")" : ""), 20, 20);
    text("altitude (pps: "+ups+")", w - 120, 20);
    rect(20, 30, percAlt[histCursor] * (w - 20), 10);
    text(nf(percAlt[histCursor], 0, 2), 20, 55);
    
    pushMatrix();
    translate(20, h - 20);
    plotMagnitude(percAlt, w - 40, -h + 80);
    popMatrix();
  
    popStyle();
    popMatrix();
  }
  
  void oscEvent(OscMessage msg) {
    if (msg.checkTypetag("if")) {
      float val = msg.get(1).floatValue();
      update(val);

      OscMessage fw = new OscMessage("/altitude/avg");
      fw.add(device.id);
      fw.add(avgValue);
      fw.add(percAlt[histCursor]);
      fw.add(minAlt);
      fw.add(maxAlt);
      oscP5.send(fw, supercollider);
    }
  }
}
