import { VectorDisplay } from './VectorDisplay.js';
import { SensorType } from './Device.js';

export class GyroDisplay extends VectorDisplay {
  constructor(p, device, x, y, w, h, histLen = 500, deltaSumWin = 2) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.GYRO;
    this.supportBatch = true;
    // enableMagnitude(deltaSumWin);
    // setFilterType(FilterType.LOWPASS);
  }

  draw(w, h) {
    if (!this.value) return;

    this.p.push();
    this.p.fill(255);
    this.p.text("gyroscope " + " " + this.value.x.toFixed(2) + ", " + this.value.y.toFixed(2) + ", " + this.value.z.toFixed(2) + ", mag: " + this.value.mag().toFixed(2), 20, 20);
    // text(ups+" hz", w - 50, 20);
    this.p.pop();

    // drawPlot3D(w, h/2);

    // pushMatrix();
    // translate(0, h/2);
    // drawPlot2D(w, h / 4);
    // popMatrix();

    // pushMatrix();
    // translate(0, h/2);
    // drawMag(w, h / 4);
    // popMatrix();
  }
}
