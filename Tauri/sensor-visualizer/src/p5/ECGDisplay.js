import {plotMagnitude} from "./utils/drawing.js";

export class ECGDisplay {
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
    if (sensor.value == null) return;

    this.p.push();
    this.p.translate(20, h - 20);
    plotMagnitude(sensor.normMags, w - 40, -h + 80, sensor.histCursor);
    this.p.pop();

    this.p.pop();
  }
}

export default ECGDisplay;