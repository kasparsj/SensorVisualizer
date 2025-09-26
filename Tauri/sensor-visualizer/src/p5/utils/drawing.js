import { Vector } from '../../ds';

export const eulerAngles = (p, value, restrictPitch = false) => {
  let roll, pitch;
  if (restrictPitch) {
    roll = p.atan2(value.y, value.z);
    pitch = p.atan(-value.x / p.sqrt(value.y * value.y + value.z * value.z));
  } else {
    roll = p.atan(value.y / p.sqrt(value.x * value.x + value.z * value.z));
    pitch = p.atan2(-value.x, value.z);
  }
  return new Vector(roll, pitch);
}

export const plot3D = (p, size) => {
  const half = size / 2.0;
  p.push();
  p.stroke(0, 0, 255);
  p.line(-half, 0, 0, half, 0, 0);
  p.stroke(0, 255, 0);
  p.line(0, -half, 0, 0, half, 0);
  p.stroke(255, 0, 0);
  p.line(0, 0, -half, 0, 0, half);
  p.pop();
}

export const compass2D = (p, vector, d, useRect = false) => {
  if (!vector || !isFinite(vector.x) || !isFinite(vector.y) || !isFinite(d)) return;
  const mult = p.constructor.Vector.mult(vector, d / 2);
  p.push();
  p.noFill();
  p.stroke(255);
  if (useRect) {
    p.rect(-d / 2, -d / 2, d, d);
  } else {
    p.ellipse(0, 0, d, d);
  }
  p.stroke(255, 0, 0);
  p.line(0, 0, mult.x, mult.y);
  p.pop();
}

export const squircle = (p, v) => {
  const sqx = v.x * v.x;
  const sqy = v.y * v.y;
  const sum = sqx + sqy;
  const sq = p.sqrt(sum);
  if (sqx >= sqy) {
    const sign = Math.sign(v.x);
    return new Vector(sign * sq, sign * sq * v.y / v.x);
  } else {
    const sign = Math.sign(v.y);
    return new Vector(sign * sq * v.x / v.y, sign * sq);
  }
}

export const plot2D = (p, hist, w, h, k, constrain = true) => {
  const mw = w / hist.length;
  p.beginShape();
  for (let i = 0; i < hist.length; i++) {
    const j = (i + k + 1) % hist.length;
    if (hist[j] !== null) {
      let value = hist[j] || 0;
      value = constrain ? p.constrain(value, 0, 1) : value;
      p.vertex(i * mw, value * h);
    }
  }
  p.endShape();
}

export const plotVectors = (p, hist, w, h, k, maxVal, constrain = true) => {
  const x = new Array(hist.length);
  const y = new Array(hist.length);
  const z = new Array(hist.length);
  for (let i = 0; i < hist.length; i++) {
    const val = hist[i];
    if (val) {
      x[i] = -val.x / maxVal.x;
      y[i] = -val.y / maxVal.y;
      z[i] = -val.z / maxVal.z;
    }
  }

  p.push();
  p.noFill();
  p.stroke(255, 0, 0);
  plot2D(p, x, w - 40, h / 2, k, constrain);
  p.pop();

  p.push();
  p.noFill();
  p.stroke(0, 255, 0);
  plot2D(p, y, w - 40, h / 2, k, constrain);
  p.pop();

  p.push();
  p.noFill();
  p.stroke(0, 0, 255);
  plot2D(p, z, w - 40, h / 2, k, constrain);
  p.pop();
}

export const plotMagnitude = (p, hist, w, h, k = 0, constrain = true) => {
  const mw = w / hist.length;
  p.push();
  p.noFill();
  p.stroke(255);
  p.beginShape();
  for (let i = 0; i < hist.length; i++) {
    const j = (i + k + 1) % hist.length;
    if (hist[j] !== null) {
      let mag;
      if (hist[j] instanceof Vector) {
        mag = hist[j].mag();
      } else {
        mag = hist[j];
      }
      mag = constrain ? p.constrain(mag, 0, 1) : mag;
      p.vertex(i * mw, mag * h);
    }
  }
  p.endShape();
  p.pop();
}

export const drawCommands = (p, keys, infos) => {
    for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const info = infos[i];
        p.textSize(18);
        p.text(key, 30, (i+2)*30);
        p.text(info, 120, (i+2)*30);
    }
}

export const drawProjectionCompasses = (p, projections, w, h, options = {}) => {
  const {
    labels = null,
    useSquare = false,
    showLabels = false,
    yOffset = 50,
    xOffset = 20
  } = options;
  
  if (!projections || projections.length !== 3) return;
  
  p.push();
  p.translate(xOffset, yOffset);
  
  const d = Math.min(w/3, h) - 20;
  
  // Draw labels if provided
  if (showLabels && labels && labels.length === 3) {
    p.fill(255);
    p.textSize(12);
    p.text(labels[0], 0, 20);
    p.text(labels[1], w/3, 20);
    p.text(labels[2], 2*w/3, 20);
  }
  
  // Draw first projection (XZ)
  p.push();
  p.translate(d/2, showLabels ? h/2 : d/2);
  compass2D(p, projections[0], d, useSquare);
  p.pop();
  
  // Draw second projection (YX)
  p.push();
  p.translate(w/3 + d/2, showLabels ? h/2 : d/2);
  compass2D(p, projections[1], d, useSquare);
  p.pop();
  
  // Draw third projection (ZY)
  p.push();
  p.translate(w/3*2 + d/2, showLabels ? h/2 : d/2);
  compass2D(p, projections[2], d, useSquare);
  p.pop();
  
  p.pop();
}

// Helper function to draw dashed line
export const drawDashedLine = (p, x1, y1, z1, x2, y2, z2, r, g, b) => {
  const dashLength = 5;
  const gapLength = 3;

  const distance = p.dist(x1, y1, z1, x2, y2, z2);
  const steps = Math.floor(distance / (dashLength + gapLength));

  p.stroke(r, g, b, 150);
  for (let i = 0; i < steps; i++) {
    const t1 = (i * (dashLength + gapLength)) / distance;
    const t2 = ((i * (dashLength + gapLength)) + dashLength) / distance;

    if (t2 <= 1) {
      const px1 = p.lerp(x1, x2, t1);
      const py1 = p.lerp(y1, y2, t1);
      const pz1 = p.lerp(z1, z2, t1);
      const px2 = p.lerp(x1, x2, t2);
      const py2 = p.lerp(y1, y2, t2);
      const pz2 = p.lerp(z1, z2, t2);

      p.line(px1, py1, pz1, px2, py2, pz2);
    }
  }
};

export const drawPlot3DSphere = (p, position, maxPosition, w, h) => {
  if (!position) return;
  
  const plotSize = Math.min(w - 40, h - 80);
  
  if (maxPosition) {
    const maxPos = Math.max(maxPosition.x, maxPosition.y, maxPosition.z);
    const scale = maxPos > 0 ? (plotSize / 2) / maxPos : 1;
    
    p.push();
    p.translate(w/2, 60 + (h - 80)/2, 0);
    p.rotateX(-Math.PI / 10);
    p.rotateY(-Math.PI / 10);

    // Draw 3D coordinate system (similar to plot3D)
    plot3D(p, plotSize);
    
    // Calculate 3D position
    const scaledPos = p.createVector(
      position.x * scale,
      position.y * scale, 
      position.z * scale
    );
    
    // Draw rectangular projections onto each plane
    p.strokeWeight(1);
    
    // XY plane rectangle (Blue for Z-axis) - from origin (0,0) to (x,y) projection
    p.fill(0, 0, 255, 50);
    p.stroke(0, 0, 255, 150);
    p.beginShape();
    p.vertex(0, 0, 0);
    p.vertex(scaledPos.x, 0, 0);
    p.vertex(scaledPos.x, scaledPos.y, 0);
    p.vertex(0, scaledPos.y, 0);
    p.endShape(p.CLOSE);
    
    // XZ plane rectangle (Green for Y-axis) - from origin (0,0) to (x,z) projection
    p.fill(0, 255, 0, 50);
    p.stroke(0, 255, 0, 150);
    p.push();
    p.rotateX(p.HALF_PI);
    p.beginShape();
    p.vertex(0, 0, 0);
    p.vertex(scaledPos.x, 0, 0);
    p.vertex(scaledPos.x, scaledPos.z, 0);
    p.vertex(0, scaledPos.z, 0);
    p.endShape(p.CLOSE);
    p.pop();
    
    // YZ plane rectangle (Red for X-axis) - from origin (0,0) to (y,z) projection
    p.fill(255, 0, 0, 50);
    p.stroke(255, 0, 0, 150);
    p.beginShape();
    p.vertex(0, 0, 0);
    p.vertex(0, scaledPos.y, 0);
    p.vertex(0, scaledPos.y, scaledPos.z);
    p.vertex(0, 0, scaledPos.z);
    p.endShape(p.CLOSE);
    
    // Draw dashed lines from sphere to each projection
    p.strokeWeight(1);
    
    // Dashed line to XY plane projection (Blue)
    drawDashedLine(p, scaledPos.x, scaledPos.y, scaledPos.z, scaledPos.x, scaledPos.y, 0, 0, 0, 255);
    
    // Dashed line to XZ plane projection (Green)
    drawDashedLine(p, scaledPos.x, scaledPos.y, scaledPos.z, scaledPos.x, 0, scaledPos.z, 0, 255, 0);
    
    // Dashed line to YZ plane projection (Red)
    drawDashedLine(p, scaledPos.x, scaledPos.y, scaledPos.z, 0, scaledPos.y, scaledPos.z, 255, 0, 0);
    
    // Draw the main position sphere
    p.fill(255, 255, 0); // Yellow sphere for visibility
    p.noStroke();
    p.push();
    p.translate(scaledPos.x, scaledPos.y, scaledPos.z);
    p.sphere(6);
    p.pop();
    
    p.pop();
  }
}

export const drawProjectionPlanes = (p, position, maxPosition, w, h) => {
  if (!position) return;
  
  p.push();
  p.fill(255);
  p.text(`pos ${position.x.toFixed(2)}, ${position.y.toFixed(2)}, ${position.z.toFixed(2)}`, 20, 20);
  
  if (maxPosition) {
    p.text(`max pos ${maxPosition.x.toFixed(2)}, ${maxPosition.y.toFixed(2)}, ${maxPosition.z.toFixed(2)}`, 20, 40);
  }
  
  // Draw 3D position as three 2D projections (XY, XZ, YZ planes)
  const panelW = w / 3 - 10;
  const panelH = h - 80;
  
  if (maxPosition) {
    const maxPos = Math.max(maxPosition.x, maxPosition.y, maxPosition.z);
    const scale = maxPos > 0 ? Math.min(panelW/3, panelH/3) / maxPos : 1;
    
    // XY plane (front view)
    p.push();
    p.translate(panelW/2, 60 + panelH/2);
    p.stroke(100);
    p.noFill();
    p.rect(-panelW/2, -panelH/2, panelW, panelH);
    p.stroke(255, 0, 0);
    p.line(-panelW/2, 0, panelW/2, 0); // X axis
    p.stroke(0, 255, 0);
    p.line(0, -panelH/2, 0, panelH/2); // Y axis
    p.fill(255);
    p.noStroke();
    p.circle(position.x * scale, position.y * scale, 8);
    p.fill(255);
    p.textAlign(p.CENTER);
    p.text("XY", 0, -panelH/2 - 10);
    p.pop();
    
    // XZ plane (top view)
    p.push();
    p.translate(panelW + 10 + panelW/2, 60 + panelH/2);
    p.stroke(100);
    p.noFill();
    p.rect(-panelW/2, -panelH/2, panelW, panelH);
    p.stroke(255, 0, 0);
    p.line(-panelW/2, 0, panelW/2, 0); // X axis
    p.stroke(0, 0, 255);
    p.line(0, -panelH/2, 0, panelH/2); // Z axis
    p.fill(255);
    p.noStroke();
    p.circle(position.x * scale, position.z * scale, 8);
    p.fill(255);
    p.textAlign(p.CENTER);
    p.text("XZ", 0, -panelH/2 - 10);
    p.pop();
    
    // YZ plane (side view)
    p.push();
    p.translate(2 * (panelW + 10) + panelW/2, 60 + panelH/2);
    p.stroke(100);
    p.noFill();
    p.rect(-panelW/2, -panelH/2, panelW, panelH);
    p.stroke(0, 255, 0);
    p.line(-panelW/2, 0, panelW/2, 0); // Y axis
    p.stroke(0, 0, 255);
    p.line(0, -panelH/2, 0, panelH/2); // Z axis
    p.fill(255);
    p.noStroke();
    p.circle(position.y * scale, position.z * scale, 8);
    p.fill(255);
    p.textAlign(p.CENTER);
    p.text("YZ", 0, -panelH/2 - 10);
    p.pop();
  }
  
  p.pop();
};

export const drawInfo = (p) => {
  p.push();
  p.background(0);
  p.fill(255);
  const keys = ["1 to 9", "r", "o", "space", "p", "s", "i", "f", "n"];
  const infos = ["switch device", "start/stop recording", "open folder for playback", "play/pause", "start playing", "stop playing",  "show/hide info", "show/hide fps", "show/hide gui"];
  const keys2 = ["u", "q", "e"];
  const infos2 = ["set device fusion type", "show hide quat view", "show/hide euler view"];
  const keys3 = ["left click", "f", "t", "m", "v"];
  const infos3 = ["select/unselect sensor", "set filter type", "set transform type", "reset min/max", "show/hide sensor"];
  p.push();
  p.translate(0, 0);
  p.textSize(20);
  p.text("Global commands", 30, 30);
  drawCommands(p, keys, infos);
  p.translate(350, 0);
  p.textSize(20);
  p.text("Device commands", 30, 30);
  drawCommands(p, keys2, infos2);
  p.translate(350, 0);
  p.textSize(20);
  p.text("Sensor commands", 30, 30);
  drawCommands(p, keys3, infos3);
  p.pop();
  p.pop();
};
