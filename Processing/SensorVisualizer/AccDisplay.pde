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
  ArrayList<PVector> velocities;
  boolean showVelocity = false;
  
  AccDisplay(float x, float y, float w, float h, GravityMethod gm, int histLen, int deltaSumWin, float maxMag) {
    super(x, y, w, h, histLen);
    type = SensorType.ACC;
    addr = "/acc";
    supportBatch = true;
    gravityMethod = gm;
    gravity = new PVector(0, 0, 0);
    enableMagnitude(deltaSumWin, maxMag);
    setFilterType(FilterType.KALMAN);
  }
  
  AccDisplay() {
    this(0, 0, width/2, height/2, GravityMethod.HIGHPASS, 500, 2, 9.81);
  }
  
  AccDisplay enableHistory(int histLen) {
    super.enableHistory(histLen);
    if (histLen > 0) {
      velocities = new ArrayList<PVector>(histLen);
      for (int i=0; i<histLen; i++) {
        velocities.add(null);
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
    text("(pps: "+ups+")", w - 70, 20);
    
    drawPlot3D(w, h/2);
    
    pushMatrix();
    translate(0, h/2);
    drawPlot2D(w, h / 4);
    popMatrix();
    
    pushMatrix();
    translate(0, h / 4 * 3);
    drawMag(w, h / 4);
    popMatrix();
    
    if (showVelocity) {
      pushMatrix();
      translate(0, h / 4 * 4);
      drawVelocity(w, h / 4);
      popMatrix();
    }
        
    popStyle();
  }
  
  void drawPlot3D(float w, float h) {
    PVector force = value.normalize().mult(magPerc() * (w / 4));
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
    plotVectors(values, w, h, histCursor, new PVector(3000, 3000, 3000));
    popMatrix();
  }
  
  void drawVelocity(float w, float h) {
    pushMatrix();
    translate(20, h);
    plotVectors(velocities, w, h, histCursor, new PVector(1000, 1000, 1000));
    popMatrix();
  }
  
  void forward(OscMessage msg) {
    if (showVelocity) {
      int numValues = msg != null ? (msg.typetag().length()-1) / numArgs : 1;
      calcVelocity(numValues);
    }
    super.forward(msg);
  }
  
  void calcVelocity(int numValues) {
    int millis = millis();
    if (velocities != null) {
      boolean useRaw = true;
      ArrayList<PVector> vals = useRaw ? rawValues : values; 
      for (int i=(numValues-1); i>=0; i--) {
        int j = i > histCursor ? histLen - (i - histCursor) : histCursor - i;
        PVector val = vals.get(j);
        // when raw - add back gravity
        if (gravityMethod != GravityMethod.NONE && useRaw) val = PVector.add(val, gravity);
        if (useRaw) {
          PVector prevVal = vals.get(j > 0 ? j-1 : histLen-1);
          if (prevVal == null) prevVal = new PVector(0, 0);
          val = PVector.add(prevVal, PVector.mult(PVector.sub(val, prevVal), 0.001));
        }
        PVector dv = PVector.mult(val, (millis - prevMillis) / numValues / 1000F);
        PVector prevVelocity = velocity == null ? new PVector(0, 0) : velocity;
        velocity = PVector.add(prevVelocity, dv);
        velocity.x = abs(velocity.x);
        velocity.y = abs(velocity.y);
        velocity.z = abs(velocity.z);
        velocities.set(j, velocity.copy());          
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
    if (key == 'v') {
      showVelocity = !showVelocity;
      return true;
    }
    return super.keyPressed();
  }
}
