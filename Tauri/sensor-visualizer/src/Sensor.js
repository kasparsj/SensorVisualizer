export class Sensor {
  constructor(p, device) {
    this.p = p;
    this.device = device;
    this.visible = true;
  }

  draw() {
    // To be implemented by subclasses
  }

  mouseClicked() {
    // To be implemented by subclasses
  }

  keyPressed() {
    // To be implemented by subclasses
  }
  
  resize() {
    // To be implemented by subclasses
  }
}
