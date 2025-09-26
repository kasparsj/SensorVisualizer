export class HRDisplay {
  constructor(p, sensor, w, h) {
    this.p = p;
    this.sensor = sensor;
    this.w = w;
    this.h = h;
  }

  draw(x = 0, y = 0) {
    this.p.push();
    this.p.translate(x, y);

    const {sensor, w, h} = this;
    if (sensor.value === null) return;

    this.p.push();
    this.p.fill(255);
    if (sensor.avgLen > 0) {
      this.p.textSize(72);
      this.p.text(sensor.avgValue.toFixed(2), w/2-100, 70);
    }
    else {
      this.p.textSize(72);
      this.p.text(sensor.value.toFixed(2), w/2-100, 70);
    }
    this.p.pop();

    this.p.pop();
  }
}

export default HRDisplay;