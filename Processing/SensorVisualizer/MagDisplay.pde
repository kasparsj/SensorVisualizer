public class MagDisplay extends VectorDisplay {

  float magDeclination = 0;

  MagDisplay(float x, float y, float w, float h, int histLen, int deltaSumWin) {
    super(x, y, w, h, histLen);
    type = SensorType.MAG;
    addr = "/mag";
    enableMagnitude(deltaSumWin);
  }

  MagDisplay() {
    this(0, height/2, width/4, height/2 - 20, 500, 2);
  }

  void draw(float w, float h) {
    if (value == null) return;

    pushMatrix();
    pushStyle();
    //translate();
    //noFill();
    //stroke(64);
    //rect(0, 0, w / 2, h);

    fill(255);
    text("magnetic " + filterType, 20, 20);
    text(ups+" hz", w - 50, 20);

    // 2D compass
    pushMatrix();
    translate(w/2, h/4);
    PVector heading = PVector.fromAngle(computeCompassHeading(val()));
    heading.normalize();
    compass2D(heading, w/2);
    popMatrix();

    // 3D compass
    PVector force3 = val().normalize().mult(w / 8);
    pushMatrix();
    translate(w/2, h/4 * 3);
    plot3D(w/2);
    stroke(255);
    line(0, 0, 0, force3.x, force3.y, force3.z);
    popMatrix();

    popStyle();
    popMatrix();
  }

  float computeCompassHeading(PVector mag)
  {
    float heading;
    if (mag.y == 0)
      heading = (mag.x < 0) ? PI : 0;
    else
      heading = atan2(mag.x, mag.y);

    if (heading > PI) heading -= (2 * PI);
    else if (heading < -PI) heading += (2 * PI);
    else if (heading < 0) heading += 2 * PI;

    return heading;
  }
}
