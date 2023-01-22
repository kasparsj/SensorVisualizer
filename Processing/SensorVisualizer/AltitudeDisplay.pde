public class AltitudeDisplay extends SensorDisplay<Float> {
  
  AltitudeDisplay(int firstArg, float x, float y, float w, float h, int avgLen, int histLen) {
    super(firstArg, x, y, w, h);
    type = SensorType.ALTITUDE;
    addr = "/altitude";
    enableHistory(histLen);
    enableAverage(avgLen);
  }
  
  AltitudeDisplay(int firstArg) {
    this(firstArg, 0, height/2, width/4, height/2, 0, 50);
  }
  
  AltitudeDisplay() {
    this(1);
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
    if (perc[histCursor] == null) return;

    pushMatrix();
    pushStyle();
    translate(0, h);
    noFill();
    stroke(64);
    rect(0, 0, w, h);
  
    fill(255);
    text("avg/"+avgLen+" "+nf(avgValue, 0, 2)+(ups > 0 ? " ("+nf(minValue, 0, 2)+", "+nf(maxValue, 0, 2)+")" : ""), 20, 20);
    text("altitude (pps: "+ups+")", w - 120, 20);
    rect(20, 30, perc[histCursor] * (w - 20), 10);
    text(nf(perc[histCursor], 0, 2), 20, 55);
    
    pushMatrix();
    translate(20, h - 20);
    plotMagnitude(perc, w - 40, -h + 80);
    popMatrix();
  
    popStyle();
    popMatrix();
  }
  
  Float parse(OscMessage msg, int i) {
    return msg.get(firstArg+i).floatValue();
  }
  
  Float parse(TableRow row) {
    return row.getFloat(2);
  }
}
