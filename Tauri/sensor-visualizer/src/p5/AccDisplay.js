import { VectorDisplay } from './VectorDisplay.js';
import {plot3D, plotVectors, plotMagnitude, drawPlot3DSphere} from './utils/drawing.js';

export class AccDisplay extends VectorDisplay {
  constructor(p, sensor, w, h) {
    super(p, sensor, w, h);
  }

  draw(x = 0, y = 0) {
    this.p.push();
    this.p.translate(x, y);

    const {sensor, w, h} = this;
    if (!sensor.value) return;

    if (w > h) {
      this.drawPlot3D(w/2, h/2);

      this.p.push();
      this.p.translate(0, h/2);
      this.drawPlot2D(w/2, h / 4);
      this.p.pop();

      this.p.push();
      this.p.translate(0, h/2);
      this.drawMag(w/2, h / 4);
      this.p.pop();

      this.p.push();
      this.p.translate(0, h / 4 * 3);
      this.drawVelocity(w/2, h / 4);
      this.p.pop();

      this.p.push();
      this.p.translate(w/2, 0);
      this.drawPosition(w/2, h);
      this.p.pop();
    } else {
      this.drawPlot3D(w, h / 4);
      
      this.p.push();
      this.p.translate(0, h / 4);
      this.drawPlot2D(w, h / 2 / 4);
      this.p.pop();

      this.p.push();
      this.p.translate(0, h / 4);
      this.drawMag(w, h / 2 / 4);
      this.p.pop();

      this.p.push();
      this.p.translate(0, h / 2 / 4 * 3);
      this.drawVelocity(w, h / 2 / 4);
      this.p.pop();

      this.p.push();
      this.p.translate(0, h/2);
      this.drawPosition(w, h/2);
      this.p.pop();
    }

    this.p.pop();
  }
  
  drawPlot3D(w, h) {
    const sensor = this.sensor;
    const val = sensor.val();
    if (!val || !sensor.maxValue) return;
    
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
    // Note: Processing version uses (force.y, force.x, force.z) - different axis order
    this.p.line(0, 0, 0, force.y, force.x, force.z);
    this.p.pop();
  }

  drawVelocity(w, h) {
    const sensor = this.sensor;
    if (!sensor.velocity) return;
    
    this.p.push();
    this.p.fill(255);
    
    // Debug info to see what's happening
    const currentAcc = sensor.value ? sensor.value.mag().toFixed(3) : "null";
    const maxVel = sensor.maxVelocity ? sensor.maxVelocity.mag().toFixed(3) : "null";
    
    this.p.text(`speed ${sensor.velocity.mag().toFixed(2)}`, 20, 20);
    
    if (sensor.velocities && sensor.maxVelocity) {
      this.p.push();
      this.p.translate(20, h/2);
      
      // Calculate maximum absolute value across all axes (matching Processing version)
      const maxX = Math.abs(sensor.maxVelocity.x);
      const maxY = Math.abs(sensor.maxVelocity.y);
      const maxZ = Math.abs(sensor.maxVelocity.z);
      const mv = Math.max(maxX, maxY, maxZ);
      
      // Ensure we have a valid scaling factor
      const scalingFactor = mv > 0 ? mv : 1;
      const maxVal = this.p.createVector(scalingFactor, scalingFactor, scalingFactor);
      
      // Pass correct width (plotVectors will handle the -40 internally)
      plotVectors(this.p, sensor.velocities, w, h, sensor.histCursor, maxVal);
      this.p.translate(0, h/2 - 20);
      if (sensor.speeds) {
        plotMagnitude(this.p, sensor.speeds, w - 40, -h + 20, sensor.histCursor);
      }
      this.p.pop();
    }
    
    this.p.pop();
  }

  drawPosition(w, h) {
    const sensor = this.sensor;
    if (!sensor.position) return;
    
    this.p.push();
    this.p.fill(255);
    this.p.text(`pos ${sensor.position.x.toFixed(2)}, ${sensor.position.y.toFixed(2)}, ${sensor.position.z.toFixed(2)}`, 20, 20);
    this.p.pop();
    
    //drawProjectionPlanes(this.p, sensor.position, sensor.maxPosition, w, h);
    drawPlot3DSphere(this.p, sensor.position, sensor.maxPosition, w, h);
  }
}

export default AccDisplay;