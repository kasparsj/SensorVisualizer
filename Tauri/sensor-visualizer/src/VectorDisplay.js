import { Sensor } from './Sensor.js';

export class VectorDisplay extends Sensor {
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
    this.maxValue = null;
    this.minValue = null;
  }

  update(val) {
    this.value = val;
    if (this.values.length < this.histLen) {
      this.values.push(val);
    } else {
      this.values[this.histCursor] = val;
      this.histCursor = (this.histCursor + 1) % this.histLen;
    }
    
    if (!this.maxValue) {
      this.maxValue = val.copy();
    } else {
      this.maxValue.x = Math.max(this.maxValue.x, val.x);
      this.maxValue.y = Math.max(this.maxValue.y, val.y);
      this.maxValue.z = Math.max(this.maxValue.z, val.z);
    }
    
    if (!this.minValue) {
      this.minValue = val.copy();
    } else {
      this.minValue.x = Math.min(this.minValue.x, val.x);
      this.minValue.y = Math.min(this.minValue.y, val.y);
      this.minValue.z = Math.min(this.minValue.z, val.z);
    }
  }

  oscEvent(msg) {
    const val = this.p.createVector(msg.args[0], msg.args[1], msg.args[2]);
    this.update(val);
  }
}
