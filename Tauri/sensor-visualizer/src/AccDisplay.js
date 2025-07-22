import { VectorDisplay } from './VectorDisplay.js';
import { SensorType } from './Device.js';

export const GravityMethod = {
  NONE: 'NONE',
  HIGHPASS: 'HIGHPASS',
  ORIENT: 'ORIENT',
  
  next: (current) => {
    const values = Object.values(GravityMethod);
    const currentIndex = values.indexOf(current);
    return values[(currentIndex + 1) % (values.length -1)];
  }
};

export class AccDisplay extends VectorDisplay {
  constructor(p, device, x, y, w, h, gm = GravityMethod.HIGHPASS, histLen = 500, deltaSumWin = 2, maxMag = 9.81) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.ACC;
    this.addr = "/acc";
    this.supportBatch = true;
    this.gravityMethod = gm;
    this.gravity = p.createVector(0, 0, 0);
    // enableMagnitude(deltaSumWin, maxMag);
    // setFilterType(FilterType.KALMAN);
    
    this.prevMillis = 0;
    this.velocity = p.createVector(0, 0, 0);
    this.maxVelocity = p.createVector(0, 0, 0);
    this.velocities = [];
    this.speeds = [];
    this.position = p.createVector(0, 0, 0);
  }
  
  update(val) {
    switch (this.gravityMethod) {
      case GravityMethod.ORIENT:
        // To be implemented
        break;
      case GravityMethod.HIGHPASS:
        const alpha = 0.05;
        // gravity = lowpass(val.copy(), alpha, gravity);
        // val = p5.Vector.sub(val, gravity);
        break;
      case GravityMethod.NONE:
      default:
        break;
    }
    super.update(val);
  }
  
  draw(w, h) {
    // To be implemented
  }
}
