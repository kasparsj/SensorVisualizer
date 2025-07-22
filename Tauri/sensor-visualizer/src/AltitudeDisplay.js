import { Sensor } from './Sensor.js';
import { SensorType } from './Device.js';

export class AltitudeDisplay extends Sensor {
  constructor(p, device, x, y, w, h, avgLen = 2, histLen = 50) {
    super(p, device);
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.type = SensorType.ALTITUDE;
    this.addr = "/altitude";
    this.avgLen = avgLen;
    this.histLen = histLen;
    this.values = [];
    this.avgValue = 0;
    this.value = null;
  }

  updateAvg() {
    // To be implemented
  }

  draw(w, h) {
    // To be implemented
  }
  
  oscEvent(msg) {
    const val = msg.args[0];
    this.value = val;
  }
}
