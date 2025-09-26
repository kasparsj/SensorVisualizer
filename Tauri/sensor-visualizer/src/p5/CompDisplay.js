import { compass2D } from './utils/drawing.js';

export class CompDisplay {
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
    if (sensor.value === null || sensor.value === undefined) return;

    // 2D compass
    this.p.push();
    this.p.translate(w/2, h/2);
    const heading = this.p.constructor.Vector.fromAngle(this.p.radians(sensor.value));
    heading.normalize();
    compass2D(this.p, heading, w/2);
    this.p.pop();

    this.p.pop();
  }
}

export default CompDisplay;