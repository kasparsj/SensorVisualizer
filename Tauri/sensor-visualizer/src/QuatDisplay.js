import { RotationStats } from './RotationStats.js';
import { SensorType } from './Device.js';
import { Quaternion } from './Quaternion.js';
import { buildBoxShape } from './utils/shapes.js';
import { compass2D, plot2D, plotMagnitude } from './utils/drawing.js';

export class QuatDisplay extends RotationStats {
  constructor(p, device, x, y, w, h, histLen = 500) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.QUAT;
    this.addr = "/quat";
  }

  drawContent(w, h) {
    let quat = null;
    if (!this.value || this.device.fusion) {
      const euler = this.device.getEulerAngles();
      if (euler) {
        quat = new Quaternion().fromEuler(euler);
        this.value = quat; // Update this.value so other methods can use it
        if (this.histLen > 0) {
          if (!(this.device.isPlaying && this.device.isPaused)) {
            this.updateHist(quat, null);
          }
        }
        // this will be lower fps but forward anyway for compatibility
        const values = [quat];
        this.forward(values);
      }
    } else {
      quat = this.value.copy();
    }
    
    if (!quat) {
      this.drawHeader(quat, w, h);
      return;
    }

    this.p.push();
    this.p.translate(0, 0);
    this.drawProjections(w, h/4);
    this.p.pop();

    this.p.push();
    this.p.translate(0, h/4);
    this.drawProjectionHistory(w/3, h/4);
    this.p.pop();

    this.p.push();
    this.p.translate(0, h/2);
    this.drawCube(quat, w, h/2);
    this.p.pop();
  }

  drawProjections(w, h) {
    if (!this.value) return;
    
    const d = Math.min(w/3, h) - 20;

    this.p.push();
    this.p.translate(20, 0);
    this.p.fill(255);
    this.p.textSize(12);
    this.p.text("xzProj", 0, 20);
    this.p.text("yxProj", w/3, 20);
    this.p.text("zyProj", 2*w/3, 20);

    this.p.push();
    this.p.translate(d/2, h/2);
    compass2D(this.p, this.value.projXZ(), d, this.transformType.toString() === 'SQUIRCLE');
    this.p.pop();

    this.p.push();
    this.p.translate(w/3 + d/2, h/2);
    compass2D(this.p, this.value.projYX(), d, this.transformType.toString() === 'SQUIRCLE');
    this.p.pop();

    this.p.push();
    this.p.translate(w/3*2 + d/2, h/2);
    compass2D(this.p, this.value.projZY(), d, this.transformType.toString() === 'SQUIRCLE');
    this.p.pop();

    this.p.pop();
  }

  drawProjectionHistory(w, h) {
    this.p.push();
    this.p.translate(20, 0);
    this.p.fill(255);
    this.p.textSize(12);
    this.p.text("xzHist", 0, 0);
    this.p.text("yxHist", w, 0);
    this.p.text("zyHist", 2*w, 0);
    this.p.pop();

    const xzheading = new Array(this.histLen);
    const yxheading = new Array(this.histLen);
    const zyheading = new Array(this.histLen);
    
    for (let i = 0; i < this.histLen; i++) {
      if (this.xz[i]) {
        xzheading[i] = this.xz[i].heading() / (this.p.TWO_PI || (2 * Math.PI));
        yxheading[i] = this.yx[i].heading() / (this.p.TWO_PI || (2 * Math.PI));
        zyheading[i] = this.zy[i].heading() / (this.p.TWO_PI || (2 * Math.PI));
      }
    }

    // xzHist
    this.p.push();
    this.p.translate(0, h/2);
    this.p.noFill();
    this.p.stroke(255, 0, 0);
    plot2D(this.p, xzheading, w - 40, h - 40, this.histCursor);
    this.p.translate(0, -h/2);
    plotMagnitude(this.p, this.xz, w - 40, h - 40, this.histCursor);
    this.p.pop();

    // yxHist
    this.p.push();
    this.p.translate(w, h/2);
    this.p.noFill();
    this.p.stroke(255, 0, 0);
    plot2D(this.p, yxheading, w - 40, h - 40, this.histCursor);
    this.p.translate(0, -h/2);
    plotMagnitude(this.p, this.yx, w - 40, h - 40, this.histCursor);
    this.p.pop();

    // zyHist
    this.p.push();
    this.p.translate(2*w, h/2);
    this.p.noFill();
    this.p.stroke(255, 0, 0);
    plot2D(this.p, zyheading, w - 40, h - 40, this.histCursor);
    this.p.translate(0, -h/2);
    plotMagnitude(this.p, this.zy, w - 40, h - 40, this.histCursor);
    this.p.pop();
  }
  
  drawCube(quat, w, h) {
    this.drawHeader(quat, w, h);
    
    this.p.push();
    this.p.translate(w/2-20, h/2);
    this.p.scale(4, 4, 4);
    
    if (quat) {
      this.p.applyMatrix(...quat.toMatrix());
    }
    
    buildBoxShape(this.p);
    this.p.pop();
  }

  drawHeader(quat, w, h) {
    this.p.push();
    this.p.fill(255);
    this.p.textSize(12);
    const fusionText = this.device.fusion ? ` fusion: ${this.device.fusion.type}` : "";
    this.p.text(`quats ${this.filterType}${fusionText}`, 20, 20);
    
    if (quat) {
      this.p.text(`${this.ups} hz`, w - 50, 20);
    } else {
      this.p.text("no data", w - 50, 20);
    }
    this.p.pop();
  }

  getOrigEulerAngles() {
    if (!this.value) {
      return null;
    }
    return this.value.toEuler();
  }
}
