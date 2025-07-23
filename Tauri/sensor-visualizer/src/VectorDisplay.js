import { SensorDisplay } from './SensorDisplay.js';

export class VectorDisplay extends SensorDisplay {
  constructor(p, device, x, y, w, h, histLen) {
    super(p, x, y, w, h);
    this.device = device;
    this.enableHistory(histLen);
    this.value = p.createVector(0, 0, 0);
    this.maxValue = p.createVector(0, 0, 0);
    this.minValue = p.createVector(0, 0, 0);
  }

  update(val) {
    super.update(val);
  }

  updateUps() {
    this.ups = this.numUpdates;
    this.numUpdates = 0;
  }

  oscEvent(msg) {
    const val = this.p.createVector(msg.args[0].value, msg.args[1].value, msg.args[2].value);
    this.update(val);
  }
}
