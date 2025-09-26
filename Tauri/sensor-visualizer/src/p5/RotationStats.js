import { drawProjectionCompasses } from './utils/drawing.js';

export class RotationStats {
  constructor(p, sensor, w, h) {
    this.p = p;
    this.sensor = sensor;
    this.w = w || p.width;
    this.h = h || p.height;
  }

  drawProjections(w, h) {
    const sensor = this.sensor;
    const projections = sensor.getProjections();
    
    drawProjectionCompasses(this.p, projections, w, h, {
      useSquare: true,
      yOffset: 50,
      xOffset: 0
    });
  }

  // drawProjectionHistory(w, h) {
  //   this.p.push();
  //   this.p.translate(w, 50);
  //
  //   const d = Math.min(w/3, h);
  //
  //   this.p.push();
  //   this.p.translate(d/2, d/2);
  //   this.drawProjectionHistory(this.xz, d);
  //   this.p.pop();
  //
  //   this.p.push();
  //   this.p.translate(d*1.5, d/2);
  //   this.drawProjectionHistory(this.yx, d);
  //   this.p.pop();
  //
  //   this.p.push();
  //   this.p.translate(d*2.5, d/2);
  //   this.drawProjectionHistory(this.zy, d);
  //   this.p.pop();
  //
  //   this.p.pop();
  // }
  //
  // drawProjectionHistory(hist, d) {
  //   if (!isFinite(d) || d <= 0) return;
  //
  //   this.p.push();
  //   this.p.noFill();
  //   this.p.stroke(255);
  //   this.p.rect(-d/2, -d/2, d, d);
  //   this.p.stroke(255, 0, 0);
  //   this.p.beginShape();
  //   for (let i = 0; i < hist.length; i++) {
  //     const j = (i + this.histCursor + 1) % hist.length;
  //     if (hist[j] && isFinite(hist[j].x) && isFinite(hist[j].y)) {
  //       const v = hist[j].copy();
  //       v.mult(d/2);
  //       if (isFinite(v.x) && isFinite(v.y)) {
  //         this.p.vertex(v.x, v.y);
  //       }
  //     }
  //   }
  //   this.p.endShape();
  //   this.p.pop();
  // }
}

export default RotationStats;