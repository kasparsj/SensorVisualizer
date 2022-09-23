enum FilterType {
  NONE,
  LOWPASS {
    String toString() { return "LP"; }
  },
  KALMAN;
  
  private static FilterType[] vals = values();
  public FilterType next()
  {
      return vals[(this.ordinal()+1) % vals.length];
  }
}

abstract class SensorDisplay<T> {
  
  SensorType type;
  Device device;
  float x = 0, y = 0, w, h;
  T value;
  ArrayList<T> values = null;
  ArrayList<T> rawValues = null;
  int ups = 0;
  int numUpdates = 0;
  int avgLen = 0;
  T avgValue;
  int histLen = 0;
  int histCursor = -1;
  FilterType filterType = FilterType.NONE;
  boolean visible = true;
  
  SensorDisplay(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  SensorDisplay<T> enableHistory(int histLen) {
    if (histLen > 0) {
      this.histLen = histLen;
      values = new ArrayList<T>(histLen);
      rawValues = new ArrayList<T>(histLen);
      for (int i=0; i<histLen; i++) {
        values.add(null);
        rawValues.add(null);
      }
    }
    return this;
  }
  
  SensorDisplay<T> enableAverage(int avgLen) {
    if (avgLen > 0) {
      this.avgLen = avgLen;
      if (avgLen > histLen) {
        enableHistory(avgLen);
      } 
    }
    return this;
  }
  
  SensorDisplay<T> setFilterType(FilterType ft) {
    filterType = ft;
    return this;
  }
  
  void tick() {
    ups = numUpdates;
    numUpdates = 0;
  }
  
  void update(T val) {
    switch (filterType) {
      case KALMAN:
        value = kalman(val);
        break;
      case LOWPASS:
        value = lowpass(val);
        break;
      case NONE:
      default:
        value = val;
        break;
    }
    updateHist(value, val);
    if (avgLen > 0) {
      updateAvg(value);
    }
    numUpdates++;
  }
  
  void updateHist(T value, T rawVal) {
    int nextCursor = (histCursor+1) % histLen;
    if (rawValues != null) {
      rawValues.set(nextCursor, rawVal);
    }
    if (values != null) {
      values.set(nextCursor, value);
    }
    histCursor = nextCursor;
  }
  
  void updateAvg(T value) {
    println("updateAvg not implemented");
  }
  
  T prevVal() {
    return values.get(histCursor > 0 ? histCursor-1 : histLen+histCursor-1);
  }
  
  T kalman(T value) {
    println("kalman filter not implemented");
    return value;
  }
  
  T lowpass(T val, float coef, T prevVal) {
    println("lowpass filter not implemented");
    return value;
  }
  T lowpass(T val, float coef) {
    return lowpass(val, coef, value);
  }
  T lowpass(T val) {
    return lowpass(val, 0.2);
  }
  
  void draw() {
    pushMatrix();
    translate(x, y);
    pushStyle();
    noFill();
    if (device.curSensor == this) {
      stroke(127, 0, 0);
    }
    else {
      stroke(64);
    }
    rect(0, 0, w-1, h-1);
    popStyle();
    draw(w, h);
    popMatrix();
  }
  abstract void draw(float w, float h);
  
  abstract void oscEvent(OscMessage msg);
  
  boolean mouseClicked() {
    if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
      device.curSensor = device.curSensor != this ? this : null;
      return true;
    }
    return false;
  }
  boolean keyPressed() {
    if (key == 'f') {
      setFilterType(filterType.next());
      return true;
    }
    return false;
  }
}
