import { VectorDisplay } from './VectorDisplay.js';
import { plot3D } from './utils/drawing.js';

export class GyroDisplay extends VectorDisplay {
  constructor(p, sensor, w, h) {
    super(p, sensor, w, h);
  }

  draw(x = 0, y = 0) {
    this.p.push();
    this.p.translate(x, y);

    const {sensor, w, h} = this;
    if (!sensor.value) return;

    // Draw 3D plot
    this.drawPlot3D(w, h/2);

    // Draw 2D vector plot
    this.p.push();
    this.p.translate(0, h/2);
    this.drawPlot2D(w, h / 4);
    this.p.pop();

    // Draw magnitude plot
    this.p.push();
    this.p.translate(0, h / 4 * 3);
    this.drawMag(w, h / 4);
    this.p.pop();

    this.p.pop();
  }


  drawPlot3D(w, h) {
    const sensor = this.sensor;
    const val = sensor.val();
    if (!val) return;
    
    // Validate value vector
    if (!isFinite(val.x) || !isFinite(val.y) || !isFinite(val.z)) return;
    
    let normMag = sensor.normMag();
    if (!isFinite(normMag)) normMag = 0;
    
    const magnitude = val.mag();
    if (!isFinite(magnitude) || magnitude === 0) return;
    
    // Ensure minimum visibility - if normMag is too small, use a minimum value
    const scaleFactor = Math.max(normMag, 0.1) * (w / 4);
    const force = val.normalize().mult(scaleFactor);
    
    // Validate force vector
    if (!isFinite(force.x) || !isFinite(force.y) || !isFinite(force.z)) return;
    
    this.p.push();
    this.p.translate(w/2, h/2, 0);
    this.p.rotateX(-Math.PI / 10);
    this.p.rotateY(-Math.PI / 10);
    plot3D(this.p, Math.min(w / 2, h - 40));
    this.p.stroke(255);
    this.p.strokeWeight(2); // Make line thicker for visibility
    this.p.line(0, 0, 0, force.x, force.y, force.z);
    this.p.pop();
  }
}

export default GyroDisplay;