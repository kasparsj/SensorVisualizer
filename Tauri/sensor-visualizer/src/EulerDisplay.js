import { buildBoxShape } from './utils/shapes.js';
import { VectorDisplay } from './VectorDisplay.js';
import { SensorType } from './Device.js';

export class EulerDisplay extends VectorDisplay {
  constructor(p, device, x, y, w, h, histLen = 500, glPrevent = false) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.EULER;
    this.addr = "/euler";
    this.supportBatch = true;
    this.glPrevent = glPrevent;
    this.glAngle = 65;
  }

  preventGimbalLock(val) {
    if (this.glPrevent) {
      // To be implemented
    }
  }

  update(val) {
    this.preventGimbalLock(val);
    super.update(val);
  }

  updateUps() {
    this.ups = this.numUpdates;
    this.numUpdates = 0;
  }

  draw(w, h) {
    let angles;
    if (!this.value || this.device.fusion) {
      // angles = device.getEulerAngles();
      if (angles) {
        this.preventGimbalLock(angles);
        if (this.histLen > 0) {
          // if (!(device.isPlaying && device.isPaused)) {
          //   updateHist(angles, null);
          // }
        }
      }
    } else {
      angles = this.value.copy();
    }
    if (!angles) {
      // drawHeader(angles, w, h);
      return;
    }

    // text("GL prevent:" + (glPrevent ? " " + glAngle : " OFF"), 20, 20);

    // drawAngles(angles, w/3, h/4);
    // drawHist(angles, w / 3, h/4);
    this.drawCube(angles, w, h/2);
  }
  
  drawCube(angles, w, h) {
    // drawHeader(angles, w, h);

    this.p.push();
    this.p.translate(w/2 - 50, h/2);
    this.p.scale(4, 4, 4);

    // the order is important!
    this.p.rotateX(angles.y); // pitch
    this.p.rotateZ(-angles.x); // roll
    this.p.rotateY(angles.z); // yaw

    buildBoxShape(this.p);

    this.p.pop();
  }
}
