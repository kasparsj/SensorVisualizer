import p5 from 'p5';

export const eulerAngles = (p, value, restrictPitch = false) => {
  let roll, pitch;
  if (restrictPitch) {
    roll = p.atan2(value.y, value.z);
    pitch = p.atan(-value.x / p.sqrt(value.y * value.y + value.z * value.z));
  } else {
    roll = p.atan(value.y / p.sqrt(value.x * value.x + value.z * value.z));
    pitch = p.atan2(-value.x, value.z);
  }
  return new p5.Vector(roll, pitch);
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
    return new p5.Vector(sign * sq, sign * sq * v.y / v.x);
  } else {
    const sign = Math.sign(v.y);
    return new p5.Vector(sign * sq * v.x / v.y, sign * sq);
  }
}

export const plot2D = (p, hist, w, h, k) => {
  const mw = w / hist.length;
  p.beginShape();
  for (let i = 0; i < hist.length; i++) {
    const j = (i + k + 1) % hist.length;
    if (hist[j] !== null) {
      const value = hist[j];
      p.vertex(i * mw, value * h);
    }
  }
  p.endShape();
}

export const plotVectors = (p, hist, w, h, k, maxVal) => {
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
  plot2D(p, x, w - 40, h / 2, k);
  p.pop();

  p.push();
  p.noFill();
  p.stroke(0, 255, 0);
  plot2D(p, y, w - 40, h / 2, k);
  p.pop();

  p.push();
  p.noFill();
  p.stroke(0, 0, 255);
  plot2D(p, z, w - 40, h / 2, k);
  p.pop();
}

export const plotMagnitude = (p, hist, w, h, k = 0) => {
  const mw = w / hist.length;
  p.push();
  p.noFill();
  p.stroke(255);
  p.beginShape();
  for (let i = 0; i < hist.length; i++) {
    const j = (i + k + 1) % hist.length;
    if (hist[j] !== null) {
      let mag;
      if (hist[j] instanceof p5.Vector) {
        mag = hist[j].mag();
      } else {
        mag = hist[j];
      }
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
