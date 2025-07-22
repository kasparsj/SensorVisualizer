import { RotationStats } from './RotationStats.js';
import { SensorType } from './Device.js';
import { Quaternion } from './Quaternion.js';

export class QuatDisplay extends RotationStats {
  constructor(p, device, x, y, w, h, histLen = 500) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.QUAT;
    this.addr = "/quat";
  }

  draw(w, h) {
    let quat = null;
    if (!this.value || this.device.fusion) {
      // To be implemented
    } else {
      quat = this.value.copy();
    }
    if (!quat) {
      // drawHeader(quat, w, h);
      return;
    }

    // drawProjections(w, h/4);
    // drawProjectionHistory(w/3, h/4);
    this.drawCube(quat, w, h/2);
  }
  
  drawCube(quat, w, h) {
    // drawHeader(quat, w, h);

    this.p.push();
    this.p.translate(w/2-20, h/2);
    this.p.scale(4, 4, 4);

    if (quat) {
      // applyMatrix(quat.toMatrix());
    }

    // buildBoxShape();
    this.p.pop();
  }
}
