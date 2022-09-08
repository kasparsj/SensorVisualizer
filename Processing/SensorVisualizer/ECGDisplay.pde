public class ECGDisplay extends SensorDisplay<Float> {
  
  float w;
  float h;
  float minEcg = 20000;
  float maxEcg = -20000;
  Float percEcg[];
  JKalman kalman;
  
  ECGDisplay(float x, float y, float w, float h, int histLen) {
    super(x, y, w, h);
    enableHistory(histLen);
  }
  
  ECGDisplay() {
    this(width/4, height/2, width/4, height/2, 500);
  }
  
  ECGDisplay enableHistory(int histLen) {
    percEcg = new Float[histLen];
    return (ECGDisplay) super.enableHistory(histLen);
  }
  
  ECGDisplay setFilterType(FilterType ft) {
    if (ft == FilterType.KALMAN && kalman == null) {
      try {
        kalman = new JKalman(2, 1);
        
        // transitions for x, dx
        double[][] tr = {
            {1, 0},
            {0, 1}};
        kalman.setTransition_matrix(new Matrix(tr));
        kalman.setError_cov_post(kalman.getError_cov_post().identity());
      }
      catch (Exception e) {
        e.printStackTrace();
      }
    }
    return (ECGDisplay) super.setFilterType(ft);
  }
  
  void update(Float val) {
    super.update(val);
    if (value < minEcg) {
      minEcg = value;
    }
    if (value > maxEcg) {
      maxEcg = value;
    }
    percEcg[histCursor] = (value - minEcg) / (maxEcg - minEcg);
  }
  
  void draw(float w, float h) {
    if (value == null) return;
    
    pushStyle();  
    fill(255);
    text("ECG " + filterType + " " + nf(value, 0, 2)+(ups > 0 ? " ("+nf(minEcg, 0, 2)+", "+nf(maxEcg, 0, 2)+")" : ""), 20, 20);
    text("(pps: "+ups+")", w - 70, 20);
    popStyle();
    
    pushMatrix();
    translate(20, h - 20);
    plotMagnitude(percEcg, w - 40, -h + 80, histCursor);
    popMatrix();
  }
  
  Float kalman(Float val) {
    // measurement [x, y, z]
    Matrix m = new Matrix(1, 1);
    m.set(0, 0, val);

    // state [x, y, z, dx, dy, dz]
    Matrix s = kalman.Predict();

    // corrected state [x, y,z, dx, dy, dz, dxyz]
    Matrix c = kalman.Correct(m);

    val = (float) c.get(0, 0);
    
    return val;
  }
  
  Float lowpass(Float val, float coef, Float prevVal) {
    if (prevVal != null) {
      return val * coef + (1.0 - coef) * prevVal;
    }
    return val;
  }
  
  void oscEvent(OscMessage msg) {
    int numArgs = msg.typetag().length();
    for (int i=0; i<numArgs-1; i++) {
      float val;
      if (msg.typetag().charAt(1+i) == 'i') {
        val = (float) msg.get(1+i).intValue();
      }
      else {
        val = msg.get(1+i).floatValue();
      }
      
      update(val);

      OscMessage fw = new OscMessage("/ecg/avg");
      fw.add(device.id);
      fw.add(value);
      fw.add(percEcg[histCursor]);
      fw.add(minEcg);
      fw.add(maxEcg);
      oscP5.send(fw, supercollider);

    }
  }
}
