import { RotationStats } from './RotationStats.js';
import { buildBoxShape } from './utils/shapes.js';
import { plot2D, plotMagnitude, drawProjectionCompasses } from './utils/drawing.js';

export class QuatDisplay extends RotationStats {
  constructor(p, device, w, h) {
    super(p, device, w, h);
  }

  draw(x = 0, y = 0) {
    this.p.push();
    this.p.translate(x, y);

    const {sensor, w, h} = this;
    const quat = sensor.getQuaternion();
    
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

    this.p.pop();
  }

  drawProjections(w, h) {
    const sensor = this.sensor;
    if (!sensor.value) return;
    
    const projections = [
      sensor.value.projXZ(),
      sensor.value.projYX(),
      sensor.value.projZY()
    ];
    
    const labels = ["xzProj", "yxProj", "zyProj"];
    
    drawProjectionCompasses(this.p, projections, w, h, {
      labels: labels,
      useSquare: sensor.transformType.toString() === 'SQUIRCLE',
      showLabels: true,
      yOffset: 0,
      xOffset: 20
    });
  }

  drawProjectionHistory(w, h) {
    const sensor = this.sensor;

    this.p.push();
    this.p.translate(20, 0);
    this.p.fill(255);
    this.p.textSize(12);
    this.p.text("xzHist", 0, 0);
    this.p.text("yxHist", w, 0);
    this.p.text("zyHist", 2*w, 0);
    this.p.pop();

    const xzheading = new Array(sensor.histLen);
    const yxheading = new Array(sensor.histLen);
    const zyheading = new Array(sensor.histLen);
    
    for (let i = 0; i < sensor.histLen; i++) {
      if (sensor.xz[i]) {
        xzheading[i] = sensor.xz[i].heading() / (this.p.TWO_PI || (2 * Math.PI));
        yxheading[i] = sensor.yx[i].heading() / (this.p.TWO_PI || (2 * Math.PI));
        zyheading[i] = sensor.zy[i].heading() / (this.p.TWO_PI || (2 * Math.PI));
      }
    }

    // xzHist
    this.p.push();
    this.p.translate(0, h/2);
    this.p.noFill();
    this.p.stroke(255, 0, 0);
    plot2D(this.p, xzheading, w - 40, h - 40, sensor.histCursor);
    this.p.translate(0, -h/2);
    plotMagnitude(this.p, sensor.xz, w - 40, h - 40, sensor.histCursor);
    this.p.pop();

    // yxHist
    this.p.push();
    this.p.translate(w, h/2);
    this.p.noFill();
    this.p.stroke(255, 0, 0);
    plot2D(this.p, yxheading, w - 40, h - 40, sensor.histCursor);
    this.p.translate(0, -h/2);
    plotMagnitude(this.p, sensor.yx, w - 40, h - 40, sensor.histCursor);
    this.p.pop();

    // zyHist
    this.p.push();
    this.p.translate(2*w, h/2);
    this.p.noFill();
    this.p.stroke(255, 0, 0);
    plot2D(this.p, zyheading, w - 40, h - 40, sensor.histCursor);
    this.p.translate(0, -h/2);
    plotMagnitude(this.p, sensor.zy, w - 40, h - 40, sensor.histCursor);
    this.p.pop();
  }
  
  drawCube(quat, w, h) {
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

export default QuatDisplay;