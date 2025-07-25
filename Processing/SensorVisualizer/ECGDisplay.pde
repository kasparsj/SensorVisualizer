import jkalman.*;

public class ECGDisplay extends SensorDisplay<Float> {

  float w;
  float h;
  JKalman kalman;

  ECGDisplay(float x, float y, float w, float h, int histLen) {
    super(x, y, w, h);
    type = SensorType.ECG;
    addr = "/ecg";
    supportBatch = true;
    enableHistory(histLen);
    minMaxLen = histLen;
  }

  ECGDisplay() {
    this(width/4, height/2, width/4, height/2 - 20, 500);
  }

  ECGDisplay setFilterType(FilterType ft) {
    if (ft == FilterType.KALMAN && kalman == null) {
      try {
        kalman = new JKalman(2, 1);

        // transitions for x, dx
        double[][] tr = {
            {1, 0},
            {0, 1}};
        kalman.setTransition_matrix(new jama.Matrix(tr));
        kalman.setError_cov_post(kalman.getError_cov_post().identity());
      }
      catch (Exception e) {
        e.printStackTrace();
      }
    }
    return (ECGDisplay) super.setFilterType(ft);
  }

  void draw(float w, float h) {
    drawHeader(w, h);
    
    if (value == null) return;

    pushMatrix();
    translate(20, h - 20);
    plotMagnitude(perc, w - 40, -h + 80, histCursor);
    popMatrix();
  }
  
  void drawHeader(float w, float h) {
    pushStyle();
    fill(255);
    if (value != null) {
      text("ECG " + filterType + " " + nf(value, 0, 2), 20, 20);
      text("min, max "+nf(minValue, 0, 2)+", "+nf(maxValue, 0, 2), 20, 40);
      text(ups+ "hz", w - 50, 20);
    }
    else {
      text("ECG " + filterType, 20, 20);
      text("no data", w - 50, 20);
    }
    popStyle();
  }

  Float kalman(Float val) {
    jama.Matrix measurement = new jama.Matrix(1, 1);
    measurement.set(0, 0, val);

    // todo: do we need to call Predict even if we are not using it?
    jama.Matrix predicted_state = kalman.Predict();
    jama.Matrix corrected_state = kalman.Correct(measurement);
    val = (float) corrected_state.get(0, 0);

    return val;
  }

  Float lowpass(Float val, float coef, Float prevVal) {
    if (prevVal != null) {
      return val * coef + (1.0 - coef) * prevVal;
    }
    return val;
  }

  Float parse(OscMessage msg, int i) {
    float val;
    if (msg.typetag().charAt(i) == 'i') {
      val = (float) msg.get(i).intValue();
    }
    else {
      val = msg.get(i).floatValue();
    }
    return val;
  }

  Float parse(TableRow row) {
    return row.getFloat(2);
  }

  void forwardBatch(ArrayList<Float> values) {
    OscMessage fw = new OscMessage(device.outPrefix + addr + "/batch");
    fw.add(device.id);
    fw.add(2);
    for (int i=0; i<values.size(); i++) {
      Float val = values.get(i);
      fw.add((float) val);
      fw.add(perc((float) val));
    }
    oscP5.send(fw, forwardAddr);
  }
}
