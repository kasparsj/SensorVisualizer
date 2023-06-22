public class GyroDisplay extends VectorDisplay {

  GyroDisplay(float x, float y, float w, float h, int histLen, int deltaSumWin) {
    super(x, y, w, h, histLen);
    type = SensorType.GYRO;
    supportBatch = true;
    enableMagnitude(deltaSumWin);
    setFilterType(FilterType.LOWPASS);
  }

  GyroDisplay() {
    this(width/2, 0, width/4, height/2, 500, 2);
  }

  void draw(float w, float h) {
    if (value == null) return;

    pushStyle();
    fill(255);
    text("gyroscope " + filterType + " " + nf(value.x, 0, 2) + ", " + nf(value.y, 0, 2) + ", " + nf(value.z, 0, 2) + ", mag: " + nf(mag(), 0, 2), 20, 20);
    text(ups+" hz", w - 50, 20);
    popStyle();

    drawPlot3D(w, h/2);

    pushMatrix();
    translate(0, h/2);
    drawPlot2D(w, h / 4);
    popMatrix();

    pushMatrix();
    translate(0, h/2);
    drawMag(w, h / 4);
    popMatrix();
  }

  void drawPlot2D(float w, float h) {
    pushMatrix();
    translate(20, h/2);
    float mv = max(abs(max(maxValue.x, maxValue.y, maxValue.z)), abs(min(minValue.x, minValue.y, minValue.z)));
    plotVectors(values, w, h, histCursor, new PVector(mv, mv, mv));
    popMatrix();
  }

  void drawPlot3D(float w, float h) {
    PVector force = val().normalize().mult(magPerc() * (w / 4));
    pushMatrix();
    translate(w/2, h/2, 0);
    plot3D(min(w / 2, h-40));
    stroke(255);
    line(0, 0, 0, force.x, force.y, force.z);
    popMatrix();
  }

  void drawMag(float w, float h) {
    pushMatrix();

    fill(255);
    text("mag % " + nf(magPerc(), 0, 2), 20, 20);
    line(20, 5, 20 + magPerc() * (w - 40), 5);

    //float magDeltaSumPerc = magDeltaSumPerc();
    //fill(255);
    //text("delta sum % " + deltaSumWin, 20, 120);
    //if (magDeltaSumPerc > accMagDeltaSumThresh) accMagDeltaSumColor = color(255, 0, 0);
    //else if (magDeltaSumPerc < 0) accMagDeltaSumColor = lerpColor(accMagDeltaSumColor, color(0, 0, 255), 0.1);
    //else accMagDeltaSumColor = lerpColor(accMagDeltaSumColor, color(255), 0.1);
    //fill(accMagDeltaSumColor);
    //rect(w/2, 130, magDeltaSumPerc * (w/2 - 40), 10);
    //fill(255);
    //text(nf(magDeltaSumPerc, 0, 2), magDeltaSumPerc >= 0 ? 27 : 20, 150);

    translate(20, h-20);
    plotMagnitude(magPerc, w - 40, -h+20, histCursor);

    popMatrix();
  }
}
