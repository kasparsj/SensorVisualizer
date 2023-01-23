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
  int firstArg = 0;
  float x = 0, y = 0, w, h;
  T value;
  T minValue = null;
  T maxValue = null;
  ArrayList<T> values = null;
  ArrayList<T> rawValues = null;
  Float[] perc = null;
  int ups = 0;
  int numUpdates = 0;
  int avgLen = 0;
  T avgValue;
  int histLen = 0;
  int histCursor = -1;
  FilterType filterType = FilterType.NONE;
  int numArgs = 1;
  boolean supportBatch; 
  boolean makePlayRegular = true;
  boolean visible = true;
  String addr;
  
  SensorDisplay(int firstArg, float x, float y, float w, float h) {
    this.firstArg = firstArg;
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
      perc = new Float[histLen];
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
  
  void updateUps() {
    ups = numUpdates;
    numUpdates = 0;
  }
  
  abstract T parse(OscMessage msg, int batchIndex);
  
  abstract T parse(TableRow row);
  
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
    if (value instanceof Number) {
      if (minValue == null || (float) value < (float) minValue) {
        minValue = value;
      }
      if (maxValue == null || (float) value > (float) maxValue) {
        maxValue = value;
      }
    }
    if (histLen > 0) {
      updateHist(value, val);
    }
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
    if (value instanceof Number && perc != null) {
      perc[nextCursor] = ((float) value - (float) minValue) / ((float) maxValue - (float) minValue);
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
  
  final void oscEvent(OscMessage msg) {
    int numValues = 1;
    if (supportBatch) {
      int msgArgs = msg.typetag().length();
      if ((msgArgs-firstArg) % numArgs == 0) {
        numValues = (msgArgs-firstArg) / numArgs;
      }
    }
    ArrayList<T> values = new ArrayList<T>();
    for (int i=0; i<numValues; i++) {
      update(parse(msg, i));
      values.add(value);
    }
    forward(values);
  }
  
  final void playEvent(TableRow row) {
    update(parse(row));
    forward();
  }
  
  void forward(ArrayList<T> values) {
    if (addr != null && addr.length() > 0) {
      if (values.size() == 1) {
        forwardOne(values.get(0));
      }
      else {
        forwardBatch(values);
      }
    }
  }
  
  void forward() {
    ArrayList<T> values = new ArrayList<T>();
    values.add(value);
    forward(values);
  }
  
  void forwardOne(T value) {
    OscMessage fw = new OscMessage(device.outPrefix + addr);
        fw.add(device.id);
        if (value instanceof Number) {
          fw.add((float) value);
          fw.add((float) minValue);
          fw.add((float) maxValue);
          if (histLen > 0) {
            fw.add(perc[histCursor]);
          }
          if (avgLen > 0) {
            fw.add((float) avgValue);
          }
        }
        else if (value instanceof String) {
          fw.add((String) value);
        }
        else if (value instanceof PVector) {
          PVector val = (PVector) value;
          fw.add((float) val.x);
          fw.add((float) val.y);
          fw.add((float) val.z);
        }
        oscP5.send(fw, forwardAddr);
  }
  
  void forwardBatch(ArrayList<T> values) {
    OscMessage fw = new OscMessage(device.outPrefix + addr + "/batch");
    fw.add(device.id);
    if (values.get(0) instanceof Number) {
      fw.add(1);
      for (int i=0; i<values.size(); i++) {
        fw.add((float) values.get(i));
      }
    }
    else if (values.get(0) instanceof String) {
      fw.add(1);
      for (int i=0; i<values.size(); i++) {
        fw.add((String) values.get(i));
      }
    }
    else if (values.get(0) instanceof PVector) {
      fw.add(3);
      for (int i=0; i<values.size(); i++) {
        PVector val = (PVector) values.get(i);
        fw.add(val.x);
        fw.add(val.y);
        fw.add(val.z);
      }
    }
    oscP5.send(fw, forwardAddr);
  }
    
  final void record(OscMessage msg) {
    String typetag = msg.typetag();
    int totalArgs = typetag.length()-1;
    if (totalArgs % numArgs == 0) {
      PrintWriter recorder = device.getOrCreateRecorder(type);
      int numLines = supportBatch ? totalArgs / numArgs : 1;
      for (int i=0; i<numLines; i++) {
        //long time = msg.timetag();
        long time = millis();
        String line = msg.addrPattern() + "\t" + time;
        // todo: would be better to use "parse" method
        for (int j=0; j<numArgs; j++) {
          var idx = 1+i*numArgs+j;
          OscArgument arg = msg.get(idx);
          switch (typetag.charAt(idx)) {
            case 'f':
              line += "\t" + arg.floatValue();
              break;
            case 'i':
              line += "\t" + arg.intValue();
              break;
            case 's':
              line += "\t" + arg.stringValue();
              break;
          }
        }
        recorder.println(line);
      }
    }
  }
  
  Table loadFile(File file) {
    Table table = loadTable(file.getPath(), "tsv");
    if (table.getColumnCount() < (numArgs+2)) {
      println("Invalid file " + file + "! " + type + " requires " + (numArgs+2) + " columns, only " + table.getColumnCount() + " found.");      
      return null;
    }
    if (makePlayRegular) {
      makeIntervalsRegular(table);
    }
    return table;
  }
  
  void makeIntervalsRegular(Table table) {
    int minMs = table.getRow(0).getInt(1);
    int maxMs = table.getRow(table.getRowCount()-1).getInt(1);
    float diff = maxMs - minMs;
    for (int i=1; i<table.getRowCount(); i++) {
      table.getRow(i).setInt(1, round(minMs + i * (diff / (float)(table.getRowCount()-1))));
    }
  }
  
  boolean mouseClicked() {
    if (visible && mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
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
    if (key == 'v') {
      device.toggleVisible(type);
      return true;
    }
    return false;
  }
}
