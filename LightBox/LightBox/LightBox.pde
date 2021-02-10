/**
 * Preview the lightbox animations
 */

int frame = 0;

void setup() {
  size(100,100);
  //frameRate(10);
  colorMode(HSB,100);
}

void draw() {
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      stroke(getColorRing(x, y, frame));
      point(x, y);
    }
  }
  ++frame;
}

color getColorHSB(int x, int y) {
  int h = 0 * 100 / 360;
  int s = 100;
  int b = 100;
  return color(h, s, b);
}

color getColorRGB(int x, int y) {
  int r = 100;
  int g = 0;
  int b = 0;
  return color(r, g, b);
}

color getColorHues(int x, int y, int frame) {
  int h = (x + y + frame) % 360 * 100 / 360;
  int s = 100;
  int b = 100;
  return color(h, s, b);
}

color getColorRing(int x, int y, int frame) {
  // calc the distance from the pixel to the ring center
  float dx = x - 50;
  float dy = y - 50;
  float dsq = dx*dx + dy*dy; // work in squared space to avoid a sqrt.  Also gives a nice fade effect.
  
  // calc the size of the ring based on the frame number (gives animation)
  float rad = (frame % 100);
  float radsq = rad*rad;
  
  // calc the distance from the pixel to the ring
  float diff = Math.abs(dsq - radsq); // difference in radii squared
  float val = 100 - diff; // The ring is full brightness.  brightness falls off further from the ring.
  float b = val > 0 ? val : 0; // clip to avoid negative values
  
  return color(240 * 100 / 360, 100, b); // 240=blue
}
