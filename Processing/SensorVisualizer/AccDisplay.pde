enum GravityMethod {
  NONE,
  HIGHPASS {
    String toString() { return "HP"; }
  },
  ORIENT;
  
  private static GravityMethod[] vals = values();
  public GravityMethod next()
  {
      return vals[(this.ordinal()+1) % vals.length];
  }
};

public class AccDisplay extends VectorDisplay {

  color accMagDeltaSumColor = color(255, 0, 0);
  PVector gravity;
  GravityMethod gravityMethod;
  int prevMillis = 0;
  PVector velocity;
  PVector maxVelocity;
  ArrayList<PVector> velocities;
  Float[] speeds;
  PVector position;
  
  AccDisplay(int firstArg, float x, float y, float w, float h, GravityMethod gm, int histLen, int deltaSumWin, float maxMag) {
    super(firstArg, x, y, w, h, histLen);
    type = SensorType.ACC;
    addr = "/acc";
    supportBatch = true;
    gravityMethod = gm;
    gravity = new PVector(0, 0, 0);
    enableMagnitude(deltaSumWin, maxMag);
    setFilterType(FilterType.KALMAN);
  }
  
  AccDisplay(int firstArg) {
    this(firstArg, 0, 0, width/2, height/2, GravityMethod.HIGHPASS, 500, 2, 9.81);
  }
  
  AccDisplay() {
    this(1);
  }
  
  AccDisplay enableHistory(int histLen) {
    super.enableHistory(histLen);
    if (histLen > 0) {
      velocities = new ArrayList<PVector>(histLen);
      speeds = new Float[histLen];
      position = new PVector();
      for (int i=0; i<histLen; i++) {
        velocities.add(null);
        speeds[i] = 0F;
      }
    }
    else {
      velocities = null;
    }
    return this;
  }
  
  void update(PVector val) {
    switch (gravityMethod) {
      case ORIENT:
        // gravity removal is more precise when restricting pitch rather than roll
        Quaternion orientation = (new Quaternion()).fromEuler(eulerAngles(val, true));
        Quaternion conjugate = orientation.conjugate();
        gravity = conjugate.normalize().mult(new PVector(0, 0, 981));
        val = PVector.sub(val, gravity);
        break;
      case HIGHPASS:
        float alpha = 0.05;
        gravity = lowpass(val.copy(), alpha, gravity);
        val = PVector.sub(val, gravity);
        break;
      case NONE:
      default:
        break;
    }
    super.update(val);
  }
  
  void draw(float w, float h) {
    if (value == null) return;
    
    pushStyle();  
    fill(255); 
    
    text("acceleration " + filterType + " " + nf(value.x, 0, 2) + ", " + nf(value.y, 0, 2) + ", " + nf(value.z, 0, 2) + ", mag: " + nf(mag(), 0, 2), 20, 20);
    text("gravity " + gravityMethod + " " + nf(gravity.x, 0, 2) + ", " + nf(gravity.y, 0, 2) + ", " + nf(gravity.z, 0, 2), 20, 40);
    text("max " + nf(maxValue.x, 0, 2) + ", " + nf(maxValue.y, 0, 2) + ", " + nf(maxValue.z, 0, 2), 20, 60);
    text("min " + nf(minValue.x, 0, 2) + ", " + nf(minValue.y, 0, 2) + ", " + nf(minValue.z, 0, 2), 20, 80);
    text("(pps: "+ups+")", w - 70, 20);
    
    drawPlot3D(w/2, h/2);
    
    pushMatrix();
    translate(0, h/2);
    drawPlot2D(w/2, h / 4);
    popMatrix();
    
    pushMatrix();
    translate(0, h/2);
    drawMag(w/2, h / 4);
    popMatrix();
    
    pushMatrix();
    translate(0, h / 4 * 3);
    drawVelocity(w/2, h / 4);
    popMatrix();
    
    pushMatrix();
    translate(w/2, 0);
    drawPosition(w/2, h);
    popMatrix();
        
    popStyle();
  }
  
  void drawPlot3D(float w, float h) {
    PVector force = val().normalize().mult(magPerc() * (w / 4));
    pushMatrix();
    translate(w/2, h/2, 0);
    plot3D(min(w / 2, h-40));
    stroke(255);
    line(0, 0, 0, force.y, force.x, force.z);
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
  
  void drawPlot2D(float w, float h) {
    pushMatrix();
    translate(20, h/2);
    float mv = max(abs(max(maxValue.x, maxValue.y, maxValue.z)), abs(min(minValue.x, minValue.y, minValue.z)));
    plotVectors(values, w, h, histCursor, new PVector(mv, mv, mv));
    popMatrix();
  }
  
  void drawVelocity(float w, float h) {
    fill(255);
    text("speed " + nf(velocity.mag(), 0, 2), 20, 20);
    pushMatrix();
    translate(20, h/2);
    float mv = max(maxVelocity.x, maxVelocity.y, maxVelocity.z);
    plotVectors(velocities, w, h, histCursor, new PVector(mv, mv, mv));
    translate(0, h/2-20);
    plotMagnitude(speeds, w - 40, -h+20, histCursor);
    popMatrix();
  }
  
  void drawPosition(float w, float h) {
    text("pos " + nf(position.x, 0, 2) + ", " + nf(position.y, 0, 2) + ", " + nf(position.z, 0, 2), 20, 20);
    pushMatrix();
    translate(w/2, h/2);
    //translate(position.x*3000F, position.y*3000F);
    translate(position.x, position.y);
    fill(255);
    circle(0, 0, 10);
    popMatrix();
  }
  
  void forward(ArrayList<PVector> values) {
    calcVelocity(values.size());
    
    super.forward(values);
  }
  
  void calcVelocity(int numValues) {
    int millis = millis();
    if (velocities != null) {
      boolean useRaw = false;
      ArrayList<PVector> vals = useRaw ? rawValues : values; 
      for (int i=(numValues-1); i>=0; i--) {
        int j = i > histCursor ? histLen - (i - histCursor) : histCursor - i;
        PVector val = vals.get(j);
        // when raw - add back gravity
        //if (gravityMethod != GravityMethod.NONE && useRaw) val = PVector.add(val, gravity);
        //if (useRaw) {
        //  PVector prevVal = vals.get(j > 0 ? j-1 : histLen-1);
        //  if (prevVal == null) prevVal = new PVector(0, 0);
        //  val = PVector.add(prevVal, PVector.mult(PVector.sub(val, prevVal), 0.001));
        //}
        float interval = (millis - prevMillis) / numValues / 1000F;
        PVector dv = PVector.mult(val, interval);
        PVector prevVelocity = velocities.get(j > 0 ? j-1 : histLen-1);
        if (prevVelocity == null) prevVelocity = new PVector(0, 0);
        velocity = PVector.add(prevVelocity, dv);
        velocity.mult(0.9);
        float speed = velocity.mag();
        if (speed < 0.01) {
          velocity = new PVector(0, 0, 0);
          speed = 0;
        }
        maxVelocity = new PVector(max(velocity.x, (maxVelocity != null ? maxVelocity.x : 0)), max(velocity.y, (maxVelocity != null ? maxVelocity.y : 0)), max(velocity.z, (maxVelocity != null ? maxVelocity.z : 0)));
        float speedPerc = speed / maxVelocity.mag();
        velocities.set(j, velocity.copy());
        speeds[j] = speedPerc;
        position.add(PVector.mult(velocity, interval));
        position.mult(0.999);
      }
    }
    prevMillis = millis;
  }
  
  PVector getOrigEulerAngles() {
    PVector value = val();
    if (value == null) {
      return null;
    }
    if (gravityMethod != GravityMethod.NONE) {
      value = value.add(gravity);
    }
    return eulerAngles(value);
  }
  
  Quaternion getOrientation() {
    PVector angles = getOrigEulerAngles();
    if (angles == null) {
      return null;
    }
    return (new Quaternion()).fromEuler(angles);
  }
  
  AccDisplay setGravityMethod(GravityMethod gm) {
    gravityMethod = gm;
    if (gm == GravityMethod.NONE) {
      gravity = new PVector();
    }
    return this;
  }
  
  void nextGravityMethod() {
    setGravityMethod(gravityMethod.next());
  }
  
  boolean keyPressed() {
    if (key == 'g') {
      nextGravityMethod();
      return true;
    }
    return super.keyPressed();
  }
}
