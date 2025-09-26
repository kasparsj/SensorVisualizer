import { VectorDisplay } from './VectorDisplay.js';
import {compass2D} from "./utils/drawing.js";

export class MagDisplay extends VectorDisplay {
  constructor(p, sensor, w, h) {
    super(p, sensor, w, h);
  }

  draw(x = 0, y = 0) {
    this.p.push();
    this.p.translate(x, y);

    const {sensor, w, h} = this;
    if (!sensor.value) return;

    // 2D compass
    this.p.push();
    this.p.translate(w/2, h/4);
    const heading = this.p.constructor.Vector.fromAngle(sensor.computeCompassHeading(sensor.val()));
    heading.normalize();
    compass2D(heading, w/2);
    this.p.pop();

    // 3D compass
    // PVector force3 = val().normalize().mult(w / 8);
    // pushMatrix();
    // translate(w/2, h/4 * 3);
    // plot3D(w/2);
    // stroke(255);
    // line(0, 0, 0, force3.x, force3.y, force3.z);
    // popMatrix();

    this.p.pop();
  }
}

export default MagDisplay;