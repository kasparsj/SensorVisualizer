import { buildBoxShape } from './utils/shapes.js';
import { VectorDisplay } from './VectorDisplay.js';

export class EulerDisplay extends VectorDisplay {
  constructor(p, sensor, w, h) {
    super(p, sensor, w, h);
  }

  draw(x = 0, y = 0) {
    this.p.push();
    this.p.translate(x, y);

    const {sensor, w, h} = this;

    let angles;
    if (!sensor.value || sensor.device.fusion) {
      // angles = sensor.device.getEulerAngles();
      if (angles) {
        sensor.preventGimbalLock(angles);
        if (sensor.histLen > 0) {
          // if (!(sensor.device.isPlaying && sensor.device.isPaused)) {
          //   sensor.updateHist(angles, null);
          // }
        }
      }
    } else {
      angles = sensor.value.copy();
    }
    if (!angles) {
      // this.drawHeader(angles, w, h);
      return;
    }

    // text("GL prevent:" + (glPrevent ? " " + glAngle : " OFF"), 20, 20);

    // this.drawAngles(angles, w/3, h/4);
    // this.drawHist(angles, w / 3, h/4);
    this.drawCube(angles, w, h/2);

    this.p.pop();
  }
  
  drawCube(angles, w, h) {
    // this.drawHeader(angles, w, h);

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

export default EulerDisplay;