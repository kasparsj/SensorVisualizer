public class GyroDisplay extends VectorDisplay {
  
  GyroDisplay(float x, float y, float w, float h, int histLen, int deltaSumWin) {
    super(x, y, w, h, histLen);
    type = SensorType.GYRO;
    supportBatch = true;
    enableMagnitude(deltaSumWin);
    setFilterType(FilterType.LOWPASS);
  }
  
  GyroDisplay() {
    this(0, height/2, width/2, height/2, 500, 2);
  }

  void draw(float w, float h) {
    if (value == null) return;
    
    pushMatrix();
    pushStyle();
  
    fill(255);
    text("gyroscope " + filterType + " " + nf(value.x, 0, 2) + ", " + nf(value.y, 0, 2) + ", " + nf(value.z, 0, 2) + ", mag: " + nf(mag(), 0, 2), 20, 20);
    text("(pps: "+ups+")", w - 70, 20);

    drawPlot3D(w, h/2);
    
    pushMatrix();
    translate(0, h / 4 * 3);
    drawMag(w, h / 4);
    popMatrix();
    
    popStyle();
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
  
  void forward(OscMessage msg) {
    forwardMagnitude("/gyro/mag", 0);
  }
}
