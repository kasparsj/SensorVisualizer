import { SensorDisplay } from './SensorDisplay.js';
import { Quaternion } from './Quaternion.js';
import { compass2D } from './utils/drawing.js';

export class RotationStats extends SensorDisplay {
  constructor(p, device, x, y, w, h, histLen) {
    super(p, x, y, w, h);
    this.device = device;
    this.enableHistory(histLen);
    
    this.xz = new Array(histLen).fill(null);
    this.yx = new Array(histLen).fill(null);
    this.zy = new Array(histLen).fill(null);
  }

  updateHist(val, rawVal) {
    super.updateHist(val, rawVal);
    this.xz[this.histCursor] = val.projXZ();
    this.yx[this.histCursor] = val.projYX();
    this.zy[this.histCursor] = val.projZY();
  }

  oscEvent(msg) {
    const val = new Quaternion(msg.args[0].value, msg.args[1].value, msg.args[2].value, msg.args[3].value);
    this.update(val);
  }

  update(val) {
    this.updateHist(val, null);
    this.value = val;
  }

  updateUps() {
    this.ups = this.numUpdates;
    this.numUpdates = 0;
  }

  drawHeader(value, w, h) {
    this.p.push();
    this.p.fill(255);
    this.p.textSize(16);
    this.p.text(`${this.type} (${this.ups} upd/s)`, 20, 20);
    if (value) {
      this.p.text(value.toString(), 20, 40);
    }
    this.p.pop();
  }

  drawProjections(w, h) {
    this.p.push();
    this.p.translate(0, 50);
    
    const d = Math.min(w/3, h);
    
    this.p.push();
    this.p.translate(d/2, d/2);
    compass2D(this.p, this.xz[this.histCursor], d, true);
    this.p.pop();
    
    this.p.push();
    this.p.translate(d*1.5, d/2);
    compass2D(this.p, this.yx[this.histCursor], d, true);
    this.p.pop();
    
    this.p.push();
    this.p.translate(d*2.5, d/2);
    compass2D(this.p, this.zy[this.histCursor], d, true);
    this.p.pop();
    
    this.p.pop();
  }

  drawProjectionHistory(w, h) {
    this.p.push();
    this.p.translate(w, 50);
    
    const d = Math.min(w/3, h);
    
    this.p.push();
    this.p.translate(d/2, d/2);
    this.drawProjectionHistory(this.xz, d);
    this.p.pop();
    
    this.p.push();
    this.p.translate(d*1.5, d/2);
    this.drawProjectionHistory(this.yx, d);
    this.p.pop();
    
    this.p.push();
    this.p.translate(d*2.5, d/2);
    this.drawProjectionHistory(this.zy, d);
    this.p.pop();
    
    this.p.pop();
  }

  drawProjectionHistory(hist, d) {
    if (!isFinite(d) || d <= 0) return;
    
    this.p.push();
    this.p.noFill();
    this.p.stroke(255);
    this.p.rect(-d/2, -d/2, d, d);
    this.p.stroke(255, 0, 0);
    this.p.beginShape();
    for (let i = 0; i < hist.length; i++) {
      const j = (i + this.histCursor + 1) % hist.length;
      if (hist[j] && isFinite(hist[j].x) && isFinite(hist[j].y)) {
        const v = hist[j].copy();
        v.mult(d/2);
        if (isFinite(v.x) && isFinite(v.y)) {
          this.p.vertex(v.x, v.y);
        }
      }
    }
    this.p.endShape();
    this.p.pop();
  }
}
