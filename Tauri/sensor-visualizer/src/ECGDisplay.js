import { SensorDisplay } from './SensorDisplay.js';
import { SensorType } from './Device.js';
import KalmanFilter from 'kalmanjs';

export class ECGDisplay extends SensorDisplay {
  constructor(p, device, x, y, w, h, histLen = 500) {
    super(p, x, y, w, h);
    this.device = device;
    this.type = SensorType.ECG;
    this.addr = "/ecg";
    this.supportBatch = true;
    this.enableHistory(histLen);
    this.kalman = null;
  }

  setFilterType(ft) {
    super.setFilterType(ft);
    if (ft === 'KALMAN' && !this.kalman) {
      this.kalman = new KalmanFilter({R: 0.01, Q: 3});
    }
  }

  drawContent(w, h) {
    // To be implemented
  }

  kalman(val) {
    if (this.kalman) {
      return this.kalman.filter(val);
    }
    return val;
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
