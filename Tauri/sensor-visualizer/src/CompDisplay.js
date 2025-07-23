import { SensorDisplay } from './SensorDisplay.js';
import { SensorType } from './Device.js';

export class CompDisplay extends SensorDisplay {
  constructor(p, device, x, y, w, h) {
    super(p, x, y, w, h);
    this.device = device;
    this.type = SensorType.COMP;
    this.addr = "/comp";
    this.value = null;
  }

  drawContent(w, h) {
    if (this.value === null) return;

    // 2D compass
    this.p.push();
    this.p.translate(w/2, h/2);
    const heading = this.p.constructor.Vector.fromAngle(this.p.radians(this.value));
    heading.normalize();
    // compass2D(heading, w/2);
    this.p.pop();
  }
  
  oscEvent(msg) {
    const val = msg.args[0].value;
    this.update(val);
  }

  updateUps() {
    this.ups = this.numUpdates;
    this.numUpdates = 0;
  }
}
