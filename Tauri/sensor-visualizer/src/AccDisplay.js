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
  }
  
  update(val) {
    const processedVal = val.copy();
    switch (this.gravityMethod) {
      case GravityMethod.ORIENT:
        // To be implemented
        break;
      case GravityMethod.HIGHPASS:
        const alpha = 0.05;
        // this.gravity = lowpass(val.copy(), alpha, this.gravity);
        // processedVal.sub(this.gravity);
        break;
      case GravityMethod.NONE:
      default:
        break;
    }
    super.update(processedVal);
  }

  updateUps() {
    this.ups = this.numUpdates;
    this.numUpdates = 0;
  }
  
  drawContent(w, h) {
    this.p.push();
    this.p.translate(20, 20);
    
    // Draw header
    this.p.fill(255);
    this.p.textSize(16);
    this.p.text(`ACC (${this.ups} upd/s)`, 0, 0);
    if (this.value) {
      this.p.text(`x: ${this.value.x.toFixed(2)} y: ${this.value.y.toFixed(2)} z: ${this.value.z.toFixed(2)}`, 0, 20);
    }

    // Draw plots
    this.p.translate(0, 40);
    // plotVectors(this.values, w - 40, h / 2, this.histCursor, this.maxValue);
    // plotMagnitude(this.values, w - 40, h / 2, this.histCursor);

    this.p.pop();
  }
}
