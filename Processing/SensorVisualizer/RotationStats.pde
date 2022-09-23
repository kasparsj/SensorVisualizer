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
    xz[histCursor] = value.projXZ();
    yx[histCursor] = value.projYX();
    zy[histCursor] = value.projZY();
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
}
