public class EulerDisplay extends VectorDisplay {

  int glAngle = 65;
  boolean glPrevent = false;

  EulerDisplay(float x, float y, float w, float h, int histLen, boolean _glPrevent) {
    super(x, y, w, h, histLen);
    type = SensorType.EULER;
    addr = "/euler";
    supportBatch = true;
    glPrevent = _glPrevent;
  }

  EulerDisplay(float x, float y, float w, float h, int histLen) {
    this(x, y, w, h, histLen, false);
  }

  EulerDisplay(boolean _glPrevent) {
    this(width/4 * 3, 20, width/4, height - 40, 500, _glPrevent);
  }

  EulerDisplay() {
    this(false);
  }

  void preventGimbalLock(PVector val) {
    if (glPrevent) {
      PVector prev;
      if (Math.abs(val.y) > radians(glAngle)) {
        prev = values.get(histCursor >= 0 ? histCursor : histLen+histCursor);
        if (prev != null) {
          val.y = prev.y;
        }
      }
      if (Math.abs(val.x) > radians(glAngle)) {
        prev = values.get(histCursor >= 0 ? histCursor : histLen+histCursor);
        if (prev != null) {
          val.x = prev.x;
        }
      }
    }
  }

  void update(PVector val) {
    preventGimbalLock(val);
    super.update(val);
  }

  void draw(float w, float h) {
    PVector angles;
    if (value == null || device.fusion != null) {
      angles = device.getEulerAngles();
      if (angles != null) {
        preventGimbalLock(angles);
        if (histLen > 0) {
          if (!(device.isPlaying && device.isPaused)) {
            updateHist(angles, null);
          }
        }
      }
    }
    else {
      angles = value.copy();
    }
    if (angles == null) {
      drawHeader(angles, w, h);
      return;
    }

    text("GL prevent:" + (glPrevent ? " " + glAngle : " OFF"), 20, 20);

    drawAngles(angles, w/3, h/4);

    pushMatrix();
    translate(0, h/4);
    drawHist(angles, w / 3, h/4);
    popMatrix();

    pushMatrix();
    translate(0, h/2);
    drawCube(angles, w, h/2);
    popMatrix();
  }

  void drawAngles(PVector angles, float w, float h) {
    float d = min(w, h)-20;

    pushStyle();
    fill(255);
    text("roll "+nf(angles.x, 0, 2) + " / " + nf(degrees(angles.x), 0, 1) + "°", 20, h);
    text("pitch "+nf(angles.y, 0, 2) + " / " + nf(degrees(angles.y), 0, 1) + "°", w+20, h);
    text("yaw "+nf(angles.z, 0, 2) + " / " + nf(degrees(angles.z), 0, 1) + "°", 2*w+20, h);

    // roll
    pushMatrix();
    translate(w/2, h/2);
    pushStyle();
    noFill();
    stroke(255);
    ellipse(0, 0, d, d);
    stroke(255, 0, 0);
    rotate(angles.x);
    line(-d/2, 0, d/2, 0);
    popStyle();
    popMatrix();

    // pitch
    pushMatrix();
    translate(w + w/2, h/2);
    pushStyle();
    noFill();
    stroke(255);
    ellipse(0, 0, d, d);
    stroke(255, 0, 0);
    rotate(angles.y);
    line(-d/2, 0, d/2, 0);
    popStyle();
    popMatrix();

    // yaw
    pushMatrix();
    translate(w + w + w/2, h/2);
    pushStyle();
    noFill();
    stroke(255);
    ellipse(0, 0, d, d);
    stroke(255, 0, 0);
    rotate(angles.z);
    line(-d/2, 0, d/2, 0);
    popStyle();
    popMatrix();

    popStyle();
  }

  private void drawHist(PVector angles, float w, float h) {
    Float rolls[] = new Float[histLen];
    Float pitches[] = new Float[histLen];
    Float yaws[] = new Float[histLen];
    for (int i=0; i<values.size(); i++) {
      PVector val = values.get(i);
      if (val != null) {
        rolls[i] = values.get(i).x / PI;
        pitches[i] = values.get(i).y / PI;
        yaws[i] = values.get(i).z / PI;
      }
      else {
        rolls[i] = 0F;
        pitches[i] = 0F;
        yaws[i] = 0F;
      }
    }

    // roll hist
    pushMatrix();
    translate(20, h/2, 0);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(rolls, w - 40, h/2 - 20, histCursor);
    popStyle();
    popMatrix();

    // pitch hist
    pushMatrix();
    translate(w + 20, h/2, 0);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(pitches, w - 40, h/2 - 20, histCursor);
    popStyle();
    popMatrix();

    // yaw hist
    pushMatrix();
    translate(2*w + 20, h/2, 0);
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    plot2D(yaws, w - 40, h/2 - 20, histCursor);
    popStyle();
    popMatrix();
  }

  private void drawCube(PVector angles, float w, float h) {
    drawHeader(angles, w, h);

    pushMatrix();
    translate(w/2 - 50, h/2);
    scale(4, 4, 4);

    // the order is important!
    rotateX(angles.y); // pitch
    rotateZ(-angles.x); // roll
    rotateY(angles.z); // yaw

    buildBoxShape();

    popMatrix();
  }
  
  void drawHeader(PVector angles, float w, float h) {
    pushStyle();
    fill(255);
    text("euler " + filterType + (device.fusion != null ? " fusion: " + device.fusion.type : ""), 20, 20);
    if (angles != null) {
      text(ups+" hz", w - 50, 20);
    }
    else {
      text("no data", w - 50, 20);
    }
    popStyle();
  }
}
