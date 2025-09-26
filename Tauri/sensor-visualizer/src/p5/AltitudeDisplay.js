import { plotMagnitude } from './utils/drawing.js';

export class AltitudeDisplay {
  constructor(p, sensor, w, h) {
    this.p = p;
    this.sensor = sensor;
    this.w = w || p.width;
    this.h = h || p.height;
  }

  draw(x = 0, y = 0) {
    this.p.push();
    this.p.translate(x, y);

    const {sensor, w, h} = this;
    if (!sensor.normValues || sensor.normValues[sensor.histCursor] == null) return;
    
    this.p.push();
    this.p.fill(255);
    this.p.stroke(255);
    this.p.line(20, 33, 20 + sensor.normValues[sensor.histCursor] * (w - 40), 33);
    this.p.text(sensor.normValues[sensor.histCursor].toFixed(2), 20, 55);
    this.p.pop();

    this.p.push();
    this.p.translate(20, h - 20);
    plotMagnitude(this.p, sensor.normValues, w - 40, -h + 80, sensor.histCursor);
    this.p.pop();

    this.p.pop();
  }
}

export default AltitudeDisplay;