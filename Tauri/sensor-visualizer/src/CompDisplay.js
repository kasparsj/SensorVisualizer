import { Sensor } from './Sensor.js';
import { SensorType } from './Device.js';

export class CompDisplay extends Sensor {
  constructor(p, device, x, y, w, h) {
    super(p, device);
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.type = SensorType.COMP;
    this.addr = "/comp";
    this.value = null;
  }

  draw(w, h) {
    if (this.value === null) return;

    // 2D compass
    this.p.push();
    this.p.translate(w/2, h/2);
    const heading = p5.Vector.fromAngle(this.p.radians(this.value));
    heading.normalize();
    // compass2D(heading, w/2);
    this.p.pop();
  }
  
  oscEvent(msg) {
    const val = msg.args[0];
    this.value = val;
  }
}
