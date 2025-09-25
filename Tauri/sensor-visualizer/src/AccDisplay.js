import { VectorDisplay } from './VectorDisplay.js';
import { SensorType } from './Device.js';
import {plot3D, plotVectors, plotMagnitude, drawProjectionPlanes, drawPlot3DSphere} from './utils/drawing.js';
import { eulerAngles } from './utils/drawing.js';
import {FilterType} from "./SensorDisplay.js";

export const GravityMethod = {
  NONE: 'NONE',
  HIGHPASS: 'HP',
  ORIENT: 'ORIENT',
  
  next: (current) => {
    const values = Object.values(GravityMethod).filter(v => typeof v !== 'function');
    const currentIndex = values.indexOf(current);
    return values[(currentIndex + 1) % values.length];
  }
};

export class AccDisplay extends VectorDisplay {
  constructor(p, device, x, y, w, h, gm = GravityMethod.HIGHPASS, histLen = 500, deltaSumWin = 2, maxMag = 9.81) {
    super(p, device, x, y, w, h, histLen);
    this.type = SensorType.ACC;
    this.addr = "/acc";
    this.supportBatch = true;
    this.gravityMethod = gm;
    this.gravity = p.createVector(0, 0, 0);
    this.prevMillis = 0;
    this.velocity = p.createVector(0, 0, 0);
    this.maxVelocity = p.createVector(0, 0, 0);
    this.velocities = null;
    this.speeds = null;
    this.position = p.createVector(0, 0, 0);
    this.maxPosition = p.createVector(0, 0, 0);
    
    // Initialize velocity tracking
    this.enableHistory(histLen);
    
    // enableMagnitude(deltaSumWin, maxMag);
    // setFilterType(FilterType.KALMAN);
  }
  
  enableHistory(histLen) {
    super.enableHistory(histLen);
    if (histLen > 0) {
      this.velocities = new Array(histLen).fill(null);
      this.speeds = new Array(histLen).fill(0);
      this.position = this.p.createVector(0, 0, 0);
    } else {
      this.velocities = null;
      this.speeds = null;
      this.maxPosition = this.p.createVector(0, 0, 0);
    }
    return this;
  }
  
  lowpass(val, alpha, prev) {
    return this.p.createVector(
      prev.x + alpha * (val.x - prev.x),
      prev.y + alpha * (val.y - prev.y),
      prev.z + alpha * (val.z - prev.z)
    );
  }

  update(val) {
    const processedVal = val.copy();
    switch (this.gravityMethod) {
      case GravityMethod.ORIENT:
        // gravity removal is more precise when restricting pitch rather than roll
        const angles = eulerAngles(this.p, val, true);
        // For now, simplified - full quaternion implementation would be needed
        // const orientation = new Quaternion().fromEuler(angles);
        // const conjugate = orientation.conjugate();
        // this.gravity = conjugate.normalize().mult(this.p.createVector(0, 0, 9.81));
        // processedVal.sub(this.gravity);
        break;
      case GravityMethod.HIGHPASS:
        const alpha = 0.05;
        this.gravity = this.lowpass(val.copy(), alpha, this.gravity);
        processedVal.sub(this.gravity);
        break;
      case GravityMethod.NONE:
      default:
        break;
    }
    super.update(processedVal);
  }

  drawContent(w, h) {
    this.drawHeader(w, h);
    
    if (!this.value) return;

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
  }
  
  drawHeader(w, h) {
    this.p.push();
    this.p.fill(255);
    this.p.textSize(12);
    
    if (this.value) {
      this.p.text(`acceleration ${this.filterType} ${this.value.x.toFixed(2)}, ${this.value.y.toFixed(2)}, ${this.value.z.toFixed(2)}, mag: ${this.value.mag().toFixed(2)}`, 20, 20);
      this.p.text(`gravity ${this.gravityMethod} ${this.gravity.x.toFixed(2)}, ${this.gravity.y.toFixed(2)}, ${this.gravity.z.toFixed(2)}`, 20, 40);
      this.p.text(`max ${this.maxValue.x.toFixed(2)}, ${this.maxValue.y.toFixed(2)}, ${this.maxValue.z.toFixed(2)}`, 20, 60);
      this.p.text(`min ${this.minValue.x.toFixed(2)}, ${this.minValue.y.toFixed(2)}, ${this.minValue.z.toFixed(2)}`, 20, 80);
      this.p.text(`${this.ups} hz`, w - 100, 20);
    } else {
      this.p.text(`acceleration ${this.filterType}`, 20, 20);
      this.p.text(`gravity ${this.gravityMethod} ${this.gravity.x.toFixed(2)}, ${this.gravity.y.toFixed(2)}, ${this.gravity.z.toFixed(2)}`, 20, 40);
      this.p.text("no data", w - 100, 20);
    }
    
    this.p.pop();
  }
    }
    
    this.p.pop();
  }

  drawPlot3D(w, h) {
    const val = this.val();
    if (!val || !this.maxValue) return;
    
    // Validate value vector
    if (!isFinite(val.x) || !isFinite(val.y) || !isFinite(val.z)) return;
    
    let normMag = this.normMag();
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
    if (!this.velocity) return;
    
    this.p.push();
    this.p.fill(255);
    
    // Debug info to see what's happening
    const currentAcc = this.value ? this.value.mag().toFixed(3) : "null";
    const maxVel = this.maxVelocity ? this.maxVelocity.mag().toFixed(3) : "null";
    
    this.p.text(`speed ${this.velocity.mag().toFixed(2)}`, 20, 20);
    
    if (this.velocities && this.maxVelocity) {
      this.p.push();
      this.p.translate(20, h/2);
      
      // Calculate maximum absolute value across all axes (matching Processing version)
      const maxX = Math.abs(this.maxVelocity.x);
      const maxY = Math.abs(this.maxVelocity.y);
      const maxZ = Math.abs(this.maxVelocity.z);
      const mv = Math.max(maxX, maxY, maxZ);
      
      // Ensure we have a valid scaling factor
      const scalingFactor = mv > 0 ? mv : 1;
      const maxVal = this.p.createVector(scalingFactor, scalingFactor, scalingFactor);
      
      // Pass correct width (plotVectors will handle the -40 internally)
      plotVectors(this.p, this.velocities, w, h, this.histCursor, maxVal);
      this.p.translate(0, h/2 - 20);
      if (this.speeds) {
        plotMagnitude(this.p, this.speeds, w - 40, -h + 20, this.histCursor);
      }
      this.p.pop();
    }
    
    this.p.pop();
  }

  drawPosition(w, h) {
    if (!this.position) return;
    
    this.p.push();
    this.p.fill(255);
    this.p.text(`pos ${this.position.x.toFixed(2)}, ${this.position.y.toFixed(2)}, ${this.position.z.toFixed(2)}`, 20, 20);
    this.p.pop();
    
    //drawProjectionPlanes(this.p, this.position, this.maxPosition, w, h);
    drawPlot3DSphere(this.p, this.position, this.maxPosition, w, h);
  }

  forward(values) {
    this.calcVelocity(values.length);
    super.forward(values);
  }

  calcVelocity(numValues) {
    const millis = Date.now();
    if (this.velocities) {
      const useRaw = false;
      const vals = useRaw ? this.rawValues : this.values;
      
      for (let i = numValues - 1; i >= 0; i--) {
        const j = i > this.histCursor ? this.histLen - (i - this.histCursor) : this.histCursor - i;
        let val = vals[j];
        if (!val) val = this.p.createVector(0, 0, 0);
        
        const interval = (millis - this.prevMillis) / numValues / 1000.0;
        const dv = this.p.createVector(val.x * interval, val.y * interval, val.z * interval);
        
        const prevVelocity = this.velocities[j > 0 ? j - 1 : this.histLen - 1];
        if (!prevVelocity) {
          this.velocity = this.p.createVector(0, 0, 0);
        } else {
          this.velocity = this.p.createVector(
            prevVelocity.x + dv.x,
            prevVelocity.y + dv.y,
            prevVelocity.z + dv.z
          );
        }
        
        this.velocity.mult(0.9);
        
        const speed = this.velocity.mag();
        if (speed < 0.01) {
          this.velocity = this.p.createVector(0, 0, 0);
        }
        
        if (!this.maxVelocity) {
          this.maxVelocity = this.p.createVector(0, 0, 0);
        }
        this.maxVelocity = this.p.createVector(
          Math.max(this.velocity.x, this.maxVelocity.x),
          Math.max(this.velocity.y, this.maxVelocity.y),
          Math.max(this.velocity.z, this.maxVelocity.z)
        );
        
        const maxVelMag = this.maxVelocity.mag();
        const speedPerc = maxVelMag > 0 ? speed / maxVelMag : 0;
        this.velocities[j] = this.velocity.copy();
        if (this.speeds) this.speeds[j] = speedPerc;
        
        this.position.add(this.p.createVector(
          this.velocity.x * interval,
          this.velocity.y * interval,
          this.velocity.z * interval
        ));
        this.position.mult(0.9999);
        
        // Update maxPosition
        if (!this.maxPosition) {
          this.maxPosition = this.p.createVector(0, 0, 0);
        }
        this.maxPosition = this.p.createVector(
          Math.max(Math.abs(this.position.x), Math.abs(this.maxPosition.x)),
          Math.max(Math.abs(this.position.y), Math.abs(this.maxPosition.y)),
          Math.max(Math.abs(this.position.z), Math.abs(this.maxPosition.z))
        );
      }
    }
    this.prevMillis = millis;
  }

  getOrigEulerAngles() {
    if (!this.value) return null;
    
    let value = this.value.copy();
    if (this.gravityMethod !== GravityMethod.NONE) {
      value.add(this.gravity);
    }
    return eulerAngles(this.p, value);
  }

  setGravityMethod(gm) {
    this.gravityMethod = gm;
    if (gm === GravityMethod.NONE) {
      this.gravity = this.p.createVector(0, 0, 0);
    }
    return this;
  }

  nextGravityMethod() {
    this.setGravityMethod(GravityMethod.next(this.gravityMethod));
  }

  keyPressed() {
    if (this.p.key === 'g') {
      this.nextGravityMethod();
      return true;
    }
    return super.keyPressed();
  }
}
