export const buildBoxShape = (p) => {
  p.noStroke();
  p.beginShape(p.QUADS);

  // Z+
  p.fill(0, 255, 0);
  p.vertex(-30, -5, 20);
  p.vertex(30, -5, 20);
  p.vertex(30, 5, 20);
  p.vertex(-30, 5, 20);

  // Z-
  p.fill(0, 0, 255);
  p.vertex(-30, -5, -20);
  p.vertex(30, -5, -20);
  p.vertex(30, 5, -20);
  p.vertex(-30, 5, -20);

  // X-
  p.fill(255, 0, 0);
  p.vertex(-30, -5, -20);
  p.vertex(-30, -5, 20);
  p.vertex(-30, 5, 20);
  p.vertex(-30, 5, -20);

  // X+
  p.fill(255, 255, 0);
  p.vertex(30, -5, -20);
  p.vertex(30, -5, 20);
  p.vertex(30, 5, 20);
  p.vertex(30, 5, -20);

  // Y-
  p.fill(255, 0, 255);
  p.vertex(-30, -5, -20);
  p.vertex(30, -5, -20);
  p.vertex(30, -5, 20);
  p.vertex(-30, -5, 20);

  // Y+
  p.fill(0, 255, 255);
  p.vertex(-30, 5, -20);
  p.vertex(30, 5, -20);
  p.vertex(30, 5, 20);
  p.vertex(-30, 5, 20);

  p.endShape();
}
