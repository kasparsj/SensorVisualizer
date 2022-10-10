abstract class RotationStats extends SensorDisplay<Quaternion> {
  
  PVector[] xz;
  PVector[] yx;
  PVector[] zy;
  
  RotationStats(float x, float y, float w, float h, int histLen) {
    super(x, y, w, h);
    numArgs = 4;
    enableHistory(histLen);
  }
  
  RotationStats enableHistory(int histLen) {
    if (histLen > 0) {
      xz = new PVector[histLen];
      yx = new PVector[histLen];
      zy = new PVector[histLen];
    }
    return (RotationStats) super.enableHistory(histLen);
  }
  
  void updateHist(Quaternion val, Quaternion rawVal) {
    super.updateHist(val, rawVal);
    xz[histCursor] = val.projXZ();
    yx[histCursor] = val.projYX();
    zy[histCursor] = val.projZY();
  }
  
  PVector projXZ() {
    return xz[histCursor] == null ? prevProjXZ() : xz[histCursor];
  }
  
  PVector projYX() {
    return yx[histCursor] == null ? prevProjYX() : yx[histCursor];
  }
  
  PVector projZY() {
    return zy[histCursor] == null ? prevProjZY() : zy[histCursor];
  }
  
  PVector prevProjXZ() {
    return xz[histCursor > 0 ? histCursor-1 : histLen+histCursor-1];
  }
  
  PVector prevProjYX() {
    return yx[histCursor > 0 ? histCursor-1 : histLen+histCursor-1];
  }
  
  PVector prevProjZY() {
    return zy[histCursor > 0 ? histCursor-1 : histLen+histCursor-1];
  }
  
  
  Quaternion parse(OscMessage msg, int i) {
    return new Quaternion(msg.get(1+i*4).floatValue(), msg.get(2+i*4).floatValue(), msg.get(3+i*4).floatValue(), msg.get(4+i*4).floatValue());
  }
  
  Quaternion parse(TableRow row) {
    return new Quaternion(row.getFloat(1), row.getFloat(2), row.getFloat(3), row.getFloat(4));
  }
  
  void forward(OscMessage msg) {
  if (addr != null && addr.length() > 0) {
      OscMessage fw = new OscMessage(outPrefix + addr);
      fw.add(device.id);
      fw.add(value.x);
      fw.add(value.y);
      fw.add(value.z);
      fw.add(value.w);
      
      PVector projXZ = projXZ();
      fw.add(projXZ.x);
      fw.add(projXZ.y);
      fw.add(projXZ.mag());
      fw.add(projXZ.heading());
      
      PVector projYX = projYX();
      fw.add(projYX.x);
      fw.add(projYX.y);
      fw.add(projYX.mag());
      fw.add(projYX.heading());
      
      PVector projZY = projZY();
      fw.add(projZY.x);
      fw.add(projZY.y);
      fw.add(projZY.mag());
      fw.add(projZY.heading());
      
      oscP5.send(fw, forwardAddr);   
    }
  }
}
