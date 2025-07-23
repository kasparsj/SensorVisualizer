import { SensorDisplay } from './SensorDisplay.js';
import { SensorType } from './Device.js';
import { compass2D } from './utils/drawing.js';

export class CompDisplay extends SensorDisplay {
  constructor(p, device, x, y, w, h) {
    super(p, x, y, w, h);
    this.device = device;
    this.type = SensorType.COMP;
    this.addr = "/comp";
    this.value = null;
  }

  drawContent(w, h) {
    this.drawHeader(w, h);
    
    if (this.value === null || this.value === undefined) return;

    // 2D compass
    this.p.push();
    this.p.translate(w/2, h/2);
    const heading = this.p.constructor.Vector.fromAngle(this.p.radians(this.value));
    heading.normalize();
    compass2D(this.p, heading, w/2);
    this.p.pop();
  }
  
  drawHeader(w, h) {
    this.p.push();
    this.p.fill(255);
    this.p.textSize(16);
    
    if (this.value !== null && this.value !== undefined) {
      this.p.text(`compass ${this.value.toFixed(2)} ${this.filterType.toString()}`, 20, 20);
    } else {
      this.p.text("compass", 20, 20);
    }
    this.p.text(`${this.ups} hz`, w - 50, 20);
    
    this.p.pop();
  }
  
  parse(msg, i) {
    return msg.args[this.firstArg + i].value;
  }

  parseFromRow(row) {
    // For CSV/table data - assuming compass heading is in column 2
    return parseFloat(row[2]);
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
