public class CompDisplay extends SensorDisplay<Float> {

  CompDisplay(float x, float y, float w, float h) {
    super(x, y, w, h);
    type = SensorType.COMP;
    addr = "/comp";
  }

  CompDisplay() {
    this(width/4, height/2, width/4, height/2 - 20);
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
    text("compass " + nf(value, 0, 2) + " " + filterType.toString(), 20, 20);
    text(ups+" hz", w - 50, 20);

    // 2D compass
    pushMatrix();
    translate(w/2, h/2);
    PVector heading = PVector.fromAngle(radians(value));
    heading.normalize();
    compass2D(heading, w/2);
    popMatrix();

    popStyle();
    popMatrix();
  }

  Float parse(OscMessage msg, int i) {
    return msg.get(firstArg+i).floatValue();
  }

  Float parse(TableRow row) {
    return row.getFloat(2);
  }
}
