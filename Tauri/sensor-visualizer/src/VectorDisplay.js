import { SensorDisplay } from './SensorDisplay.js';
import {plotMagnitude, plotVectors} from "./utils/drawing.js";

export class VectorDisplay extends SensorDisplay {
  constructor(p, device, x, y, w, h, histLen) {
    super(p, x, y, w, h);
    this.device = device;
    this.numArgs = 3;
    this.enableHistory(histLen);
    this.value = p.createVector(0, 0, 0);
    this.maxValue = p.createVector(0, 0, 0);
    this.minValue = p.createVector(0, 0, 0);
    // Initialize magnitude tracking arrays
    this.magPercentages = new Array(histLen).fill(0);
    this.maxMagnitude = 0;
  }

  update(val) {
    super.update(val);
    this.updateMinMax(this.value);
    this.updateMagnitudeTracking();
  }

  updateMinMax(value) {
    if (!value) return;
    
    this.minValue = this.p.createVector(
      Math.min(value.x, this.minValue ? this.minValue.x : 0),
      Math.min(value.y, this.minValue ? this.minValue.y : 0),
      Math.min(value.z, this.minValue ? this.minValue.z : 0)
    );
    
    this.maxValue = this.p.createVector(
      Math.max(value.x, this.maxValue ? this.maxValue.x : 0),
      Math.max(value.y, this.maxValue ? this.maxValue.y : 0),
      Math.max(value.z, this.maxValue ? this.maxValue.z : 0)
    );
  }

  updateMagnitudeTracking() {
    if (!this.value) return;
    
    const currentMag = this.value.mag();
    if (isFinite(currentMag)) {
      // Update max magnitude
      if (currentMag > this.maxMagnitude) {
        this.maxMagnitude = currentMag;
      }
      
      // Calculate and store magnitude percentage
      const magPerc = this.maxMagnitude > 0 ? currentMag / this.maxMagnitude : 0;
      this.magPercentages[this.histCursor] = magPerc;
    }
  }

  val() {
    return this.value ? this.value.copy() : null;
  }

  mag() {
    return this.perc && this.perc[this.histCursor] !== null ? this.perc[this.histCursor] : this.prevMag();
  }

  prevMag() {
    if (!this.perc) return 0;
    const prevIndex = this.histCursor > 0 ? this.histCursor - 1 : this.histLen + this.histCursor - 1;
    return this.perc[prevIndex] || 0;
  }

  magPerc() {
    if (!this.magPercentages || this.histCursor < 0) return 0;
    return this.magPercentages[this.histCursor] || 0;
  }

  prevMagPerc() {
    if (!this.perc) return 0;
    const prevIndex = this.histCursor > 0 ? this.histCursor - 1 : this.histLen + this.histCursor - 1;
    const prevMag = this.perc[prevIndex];
    if (prevMag !== null && prevMag !== undefined && this.maxValue) {
      const maxMag = Math.max(Math.abs(this.maxValue.x), Math.abs(this.maxValue.y), Math.abs(this.maxValue.z));
      return maxMag > 0 ? prevMag / maxMag : 0;
    }
    return 0;
  }

  parse(msg, batchIndex) {
    const baseIndex = this.firstArg + (batchIndex * this.numArgs);
    // Handle both direct values and .value properties
    const getValue = (arg) => {
      return typeof arg === 'object' && arg.value !== undefined ? arg.value : arg;
    };
    
    return this.p.createVector(
      getValue(msg.args[baseIndex]),
      getValue(msg.args[baseIndex + 1]),
      getValue(msg.args[baseIndex + 2])
    );
  }

  parseFromRow(row) {
    // Implementation for parsing from CSV row data
    return this.p.createVector(
      parseFloat(row[0]),
      parseFloat(row[1]),
      parseFloat(row[2])
    );
  }

  forward(values) {
    // Base implementation - can be overridden by subclasses
    // This is called after batch processing is complete
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
}
