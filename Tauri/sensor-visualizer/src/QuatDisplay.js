import { RotationStats } from './RotationStats.js';
import { SensorType } from './Device.js';
import { Quaternion } from './Quaternion.js';
import { buildBoxShape } from './utils/shapes.js';

export class QuatDisplay extends RotationStats {
  constructor(p, device, x, y, w, h, histLen = 500) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.QUAT;
    this.addr = "/quat";
  }

  drawContent(w, h) {
    let quat = null;
    if (!this.value || this.device.fusion) {
      const angles = this.device.getEulerAngles();
      if (angles) {
        quat = new Quaternion();
        quat.fromEuler(angles);
      }
    } else {
      quat = this.value;
    }
    if (!quat) {
      this.drawHeader(quat, w, h);
      return;
    }
    
    this.drawProjections(w, h/4);
    this.drawProjectionHistory(w/3, h/4);
    this.drawCube(quat, w, h/2);
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
}
