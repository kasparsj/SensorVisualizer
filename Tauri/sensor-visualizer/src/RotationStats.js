import { Sensor } from './Sensor.js';

export class RotationStats extends Sensor {
  constructor(p, device, x, y, w, h, histLen) {
    super(p, device);
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.histLen = histLen;
    this.values = [];
    this.histCursor = 0;
    this.value = null;
    
    this.xz = [];
    this.yx = [];
    this.zy = [];
  }

  updateHist(val, rawVal) {
    super.updateHist(val, rawVal);
    this.xz[this.histCursor] = val.projXZ();
    this.yx[this.histCursor] = val.projYX();
    this.zy[this.histCursor] = val.projZY();
  }

  oscEvent(msg) {
    const val = new Quaternion(msg.args[0], msg.args[1], msg.args[2], msg.args[3]);
    this.updateHist(val, null);
    this.value = val;
  }
}
