import {plotMagnitude, plotVectors} from "./utils/drawing.js";

export class VectorDisplay {
  constructor(p, sensor, w, h) {
    this.p = p;
    this.sensor = sensor;
    this.w = w;
    this.h = h;
  }

  drawPlot2D(w, h) {
    const sensor = this.sensor;
    if (!sensor.values || !sensor.maxValue || !sensor.minValue) return;

    this.p.push();
    this.p.translate(20, h/2);

    // Calculate maximum absolute value across all axes (matching Processing version exactly)
    const maxX = Math.max(Math.abs(sensor.maxValue.x), Math.abs(sensor.minValue.x));
    const maxY = Math.max(Math.abs(sensor.maxValue.y), Math.abs(sensor.minValue.y));
    const maxZ = Math.max(Math.abs(sensor.maxValue.z), Math.abs(sensor.minValue.z));
    const mv = Math.max(maxX, maxY, maxZ);

    // Ensure we have a valid scaling factor
    const scalingFactor = mv > 0 ? mv : 1;
    const maxVal = this.p.createVector(scalingFactor, scalingFactor, scalingFactor);

    // Pass correct width (plotVectors will handle the -40 internally)
    plotVectors(this.p, sensor.values, w, h, sensor.histCursor, maxVal);
    this.p.pop();
  }

  drawMag(w, h) {
    const sensor = this.sensor;
    if (!sensor.value) return;

    this.p.push();

    const normMag = sensor.normMag();

    this.p.fill(255);
    this.p.text(`mag % ${normMag.toFixed(2)}`, 20, 20);
    this.p.stroke(255);
    this.p.line(20, 5, 20 + normMag * (w - 40), 5);

    // Draw magnitude history using normMags array (like Processing version)
    if (sensor.normMags) {
      this.p.push();
      this.p.translate(20, h - 20);
      plotMagnitude(this.p, sensor.normMags, w - 40, -h + 20, sensor.histCursor);
      this.p.pop();
    }

    this.p.pop();
  }
}

export default VectorDisplay;