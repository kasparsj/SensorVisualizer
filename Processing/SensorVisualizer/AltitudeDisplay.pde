public class AltitudeDisplay extends SensorDisplay<Float> {

  AltitudeDisplay(float x, float y, float w, float h, int avgLen, int histLen) {
    super(x, y, w, h);
    type = SensorType.ALTITUDE;
    addr = "/altitude";
    enableHistory(histLen);
    enableAverage(avgLen);
  }

  AltitudeDisplay(boolean visible) {
    this(width/2, height/2, width/4, height/2 - 20, 2, 50);
    this.visible = visible;
  }

  AltitudeDisplay() {
    this(true);
  }

  void updateAvg(Float value) {
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

  void draw(float w, float h) {
    drawHeader(w, h);
    
    if (perc[histCursor] == null) return;
    
    pushMatrix();
    pushStyle();
    fill(255);
    line(20, 33, perc[histCursor] * (w - 40), 33);
    text(nf(perc[histCursor], 0, 2), 20, 55);
    popStyle();
    popMatrix();

    pushMatrix();
    translate(20, h - 20);
    plotMagnitude(perc, w - 40, -h + 80, histCursor);
    popMatrix();
  }
  
  void drawHeader(float w, float h) {
    pushMatrix();
    pushStyle();
    fill(255);
    
    if (perc[histCursor] != null) {
      String avgMinMax = "";
      if (avgLen > 0) {
        avgMinMax += "avg/"+avgLen+" "+nf(avgValue, 0, 2);
      }
      avgMinMax += (ups > 0 ? " ("+nf(minValue, 0, 2)+", "+nf(maxValue, 0, 2)+")" : "");
      text("altitude " + avgMinMax, 20, 20);
      text(ups+" hz", w - 50, 20);
    }
    else {
      text("altitude", 20, 20);
      text("no data", w - 50, 20);
    }
    
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
