import { VectorDisplay } from './VectorDisplay.js';
import { SensorType } from './Device.js';
import { plot3D, plotVectors, plotMagnitude } from './utils/drawing.js';

export class GyroDisplay extends VectorDisplay {
  constructor(p, device, x, y, w, h, histLen = 500, deltaSumWin = 2) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.GYRO;
    this.supportBatch = true;
    // enableMagnitude(deltaSumWin);
    // setFilterType(FilterType.LOWPASS);
  }

  drawContent(w, h) {
    if (!this.value) return;

    // Draw header with sensor info (matching Processing format)
    this.p.push();
    this.p.fill(255);
    this.p.textSize(12);
    this.p.text(`gyroscope ${this.filterType} ${this.value.x.toFixed(2)}, ${this.value.y.toFixed(2)}, ${this.value.z.toFixed(2)}, mag: ${this.value.mag().toFixed(2)}`, 20, 20);
    this.p.text(`${this.ups} hz`, w - 50, 20);
    this.p.pop();

    // Draw 3D plot
    this.drawPlot3D(w, h/2);

    // Draw 2D vector plot
    this.p.push();
    this.p.translate(0, h/2);
    this.drawPlot2D(w, h / 4);
    this.p.pop();

    // Draw magnitude plot
    this.p.push();
    this.p.translate(0, h/2);
    this.drawMag(w, h / 4);
    this.p.pop();
  }


  drawPlot3D(w, h) {
    const val = this.val();
    if (!val) return;
    
    // Validate value vector
    if (!isFinite(val.x) || !isFinite(val.y) || !isFinite(val.z)) return;
    
    let magPercValue = this.magPerc();
    if (!isFinite(magPercValue)) magPercValue = 0;
    
    const magnitude = val.mag();
    if (!isFinite(magnitude) || magnitude === 0) return;
    
    // Ensure minimum visibility - if magPerc is too small, use a minimum value
    const scaleFactor = Math.max(magPercValue, 0.1) * (w / 4);
    const force = val.normalize().mult(scaleFactor);
    
    // Validate force vector
    if (!isFinite(force.x) || !isFinite(force.y) || !isFinite(force.z)) return;
    
    this.p.push();
    this.p.translate(w/2, h/2, 0);
    plot3D(this.p, Math.min(w / 2, h - 40));
    this.p.stroke(255);
    this.p.strokeWeight(2); // Make line thicker for visibility
    this.p.line(0, 0, 0, force.x, force.y, force.z);
    this.p.pop();
  }

  drawPlot2D(w, h) {
    if (!this.values || !this.maxValue || !this.minValue) return;
    
    this.p.push();
    this.p.translate(20, h/2);
    
    // Calculate maximum absolute value across all axes (matching Processing version exactly)
    const maxX = Math.max(Math.abs(this.maxValue.x), Math.abs(this.minValue.x));
    const maxY = Math.max(Math.abs(this.maxValue.y), Math.abs(this.minValue.y));
    const maxZ = Math.max(Math.abs(this.maxValue.z), Math.abs(this.minValue.z));
    const mv = Math.max(maxX, maxY, maxZ);
    
    // Ensure we have a valid scaling factor
    const scalingFactor = mv > 0 ? mv : 1;
    const maxVal = this.p.createVector(scalingFactor, scalingFactor, scalingFactor);
    
    // Pass correct width (plotVectors will handle the -40 internally)
    plotVectors(this.p, this.values, w, h, this.histCursor, maxVal);
    this.p.pop();
  }

  drawMag(w, h) {
    if (!this.value) return;
    
    this.p.push();
    
    const magPercValue = this.magPerc();
    
    this.p.fill(255);
    this.p.text(`mag % ${magPercValue.toFixed(2)}`, 20, 20);
    this.p.stroke(255);
    this.p.line(20, 5, 20 + magPercValue * (w - 40), 5);

    // Draw magnitude history using magPercentages array (like Processing version)
    if (this.magPercentages) {
      this.p.push();
      this.p.translate(20, h - 20);
      plotMagnitude(this.p, this.magPercentages, w - 40, -h + 20, this.histCursor);
      this.p.pop();
    }
    
    this.p.pop();
  }

  updateUps() {
    this.ups = this.numUpdates;
    this.numUpdates = 0;
  }
}
