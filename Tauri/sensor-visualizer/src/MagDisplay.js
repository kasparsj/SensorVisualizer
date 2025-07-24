import { VectorDisplay } from './VectorDisplay.js';
import { SensorType } from './Device.js';

export class MagDisplay extends VectorDisplay {
  constructor(p, device, x, y, w, h, histLen = 500, deltaSumWin = 2) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.MAG;
    this.addr = "/mag";
    // enableMagnitude(deltaSumWin);
  }

  draw(w, h) {
    if (!this.value) return;

    this.p.push();
    this.p.fill(255);
    this.p.text("magnetic", 20, 20);
    // text(ups+" hz", w - 50, 20);
    this.p.pop();

    // 2D compass
    // pushMatrix();
    // translate(w/2, h/4);
    // PVector heading = PVector.fromAngle(computeCompassHeading(val()));
    // heading.normalize();
    // compass2D(heading, w/2);
    // popMatrix();

    // 3D compass
    // PVector force3 = val().normalize().mult(w / 8);
    // pushMatrix();
    // translate(w/2, h/4 * 3);
    // plot3D(w/2);
    // stroke(255);
    // line(0, 0, 0, force3.x, force3.y, force3.z);
    // popMatrix();
  }

  computeCompassHeading(mag) {
    let heading;
    if (mag.y === 0) {
      heading = (mag.x < 0) ? this.p.PI : 0;
    } else {
      heading = this.p.atan2(mag.x, mag.y);
    }

    if (heading > this.p.PI) heading -= (2 * this.p.PI);
    else if (heading < -this.p.PI) heading += (2 * this.p.PI);
    else if (heading < 0) heading += 2 * this.p.PI;

    return heading;
  }
}
