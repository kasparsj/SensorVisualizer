import { Sensor } from './Sensor.js';
import { SensorType } from './Device.js';
import KalmanFilter from 'kalmanjs';

export class ECGDisplay extends Sensor {
  constructor(p, device, x, y, w, h, histLen = 500) {
    super(p, device);
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.type = SensorType.ECG;
    this.addr = "/ecg";
    this.supportBatch = true;
    this.histLen = histLen;
    this.values = [];
    this.value = null;
    this.kalman = null;
    this.filterType = null;
  }

  setFilterType(ft) {
    this.filterType = ft;
    if (ft === 'KALMAN' && !this.kalman) {
      this.kalman = new KalmanFilter({R: 0.01, Q: 3});
    }
  }

  draw(w, h) {
    // To be implemented
  }

  kalmanFilter(val) {
    if (this.kalman) {
      return this.kalman.filter(val);
    }
    return val;
  }
  
  oscEvent(msg) {
    let val = msg.args[0];
    if (this.filterType === 'KALMAN') {
      val = this.kalmanFilter(val);
    }
    this.value = val;
  }
}
