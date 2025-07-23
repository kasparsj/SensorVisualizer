import { SensorDisplay } from './SensorDisplay.js';
import { SensorType } from './Device.js';

export class AltitudeDisplay extends SensorDisplay {
  constructor(p, device, x, y, w, h, avgLen = 2, histLen = 50) {
    super(p, x, y, w, h);
    this.device = device;
    this.type = SensorType.ALTITUDE;
    this.addr = "/altitude";
    this.enableHistory(histLen);
    this.enableAverage(avgLen);
  }

  drawContent(w, h) {
    // To be implemented
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
