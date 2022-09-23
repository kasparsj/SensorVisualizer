import jkalman.*;
import jama.*;

abstract class VectorDisplay extends SensorDisplay<PVector> {
  
  Float[] mag;
  Float[] magPerc;
  Float[] magDelta;
  float maxMag;
  float magDeltaSum = 0;
  int deltaSumWin;
  float magDeltaSumCoeff;
  JKalman kalman;
  
  VectorDisplay(float x, float y, float w, float h, int histLen) {
    super(x, y, w, h);
    numArgs = 3;
    enableHistory(histLen);
  }
  
  VectorDisplay enableMagnitude(int deltaSumWin, float magDeltaSumCoeff, float maxMag) {
    mag = new Float[histLen];
    magPerc = new Float[histLen];
    magDelta = new Float[histLen];
    for (int i=0; i<histLen; i++) {
      mag[i] = 0F;
      magPerc[i] = 0F;
      magDelta[i] = 0F;
    }
    this.deltaSumWin = deltaSumWin;
    this.magDeltaSumCoeff = magDeltaSumCoeff;
    this.maxMag = maxMag;
    return this;
  }
  
  VectorDisplay enableMagnitude(int deltaSumWin, float maxMag) {
    enableMagnitude(deltaSumWin, 0.18, maxMag);
    return this;
  }
  
  VectorDisplay enableMagnitude(int deltaSumWin) {
    enableMagnitude(deltaSumWin, 0);
    return this;
  }
  
  VectorDisplay setFilterType(FilterType ft) {
    if (ft == FilterType.KALMAN && kalman == null) {
      try {
        kalman = new JKalman(6, 3);
        
        // transitions for x, y, z, dx, dy, dz (velocity transitions)
        double[][] tr = {
            {1, 0, 0, 1, 0, 0},
            {0, 1, 0, 0, 1, 0},
            {0, 0, 1, 0, 0, 1},
            {0, 0, 0, 1, 0, 0},
            {0, 0, 0, 0, 1, 0},
            {0, 0, 0, 0, 0, 1}};
            
        kalman.setTransition_matrix(new Matrix(tr));
        kalman.setError_cov_post(kalman.getError_cov_post().identity());
      }
      catch (Exception e) {
        e.printStackTrace();
      }
    }
    return (VectorDisplay) super.setFilterType(ft);
  }
  
  void update(PVector val) {
    super.update(val.copy());
    if (mag != null) {
      mag[histCursor] = value.mag();
      if (mag[histCursor] > maxMag) {
        maxMag = mag[histCursor];
      }
      magPerc[histCursor] = mag[histCursor] / maxMag; 
      magDelta[histCursor] = mag[histCursor] - prevMag();
      magDeltaSum = sumFloats(magDelta, histCursor, deltaSumWin);
    }
  }
  
  PVector val() {
    return value == null ? null : value.copy();
  }
  
  float mag() {
    return mag[histCursor] == null ? prevMag() : mag[histCursor];
  }
  
  float prevMag() {
    return mag[histCursor > 0 ? histCursor-1 : histLen+histCursor-1];
  }
  
  float magPerc() {
    return magPerc[histCursor] == null ? prevMagPerc() : magPerc[histCursor];
  }
  
  float prevMagPerc() {
    return magPerc[histCursor > 0 ? histCursor-1 : histLen+histCursor-1];
  }
  
  float magDeltaSumPerc(float coeff) {
    return magDeltaSum / (maxMag * deltaSumWin * coeff);
  }
  
  float magDeltaSumPerc() {
    return magDeltaSumPerc(magDeltaSumCoeff);
  }
  
  PVector kalman(PVector val) {
    // measurement [x, y, z]
    Matrix m = new Matrix(3, 1);
    m.set(0, 0, val.x);
    m.set(1, 0, val.y);
    m.set(2, 0, val.z);

    // state [x, y, z, dx, dy, dz]
    Matrix s = kalman.Predict();

    // corrected state [x, y,z, dx, dy, dz, dxyz]
    Matrix c = kalman.Correct(m);

    val.x = (float) c.get(0, 0);
    val.y = (float) c.get(1, 0);
    val.z = (float) c.get(2, 0);
    
    return val;
  }
  
  PVector lowpass(PVector val, float coef, PVector prevVal) {
    if (prevVal != null) {
      val.x = val.x * coef + (1.0 - coef) * prevVal.x;
      val.y = val.y * coef + (1.0 - coef) * prevVal.y;
      val.z = val.z * coef + (1.0 - coef) * prevVal.z;
    }
    return val;
  }
  
  float sumFloats(Float[] arr, int cursor, int window) {
    float sum = 0;
    for (int i=0; i<window; i++) {
      int offset = (cursor - i + histLen) % histLen;
      if (arr[offset] != null) {
        sum += arr[offset];
      }
    }
    return sum;
  }
}
