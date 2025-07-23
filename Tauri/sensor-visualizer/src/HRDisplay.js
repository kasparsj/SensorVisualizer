import { SensorDisplay } from './SensorDisplay.js';
import { SensorType } from './Device.js';

export class HRDisplay extends SensorDisplay {
  constructor(p, device, x, y, w, h, avgLen = 0, histLen = 50) {
    super(p, x, y, w, h);
    this.device = device;
    this.type = SensorType.HR;
    this.addr = "/hr";
    this.supportBatch = false;
    this.enableHistory(histLen);
    this.enableAverage(avgLen);
  }

  drawContent(w, h) {
    if (this.value === null) return;

    this.p.push();
    this.p.fill(255);
    this.p.text("hr", 20, 20);
    // text(ups+" hz", w - 50, 20);
    if (this.avgLen > 0) {
      this.p.text("avg/"+this.avgLen+" "+this.avgValue.toFixed(2), 20, 20);
      this.p.textSize(72);
      this.p.text(this.avgValue.toFixed(2), w/2-100, 70);
    }
    else {
      this.p.textSize(72);
      this.p.text(this.value.toFixed(2), w/2-100, 70);
    }

    // To be implemented: plot
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
