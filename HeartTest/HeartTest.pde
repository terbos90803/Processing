void setup() {
  size(100, 100);
  frameRate(10);
  //colorMode(HSB, 100);
  //  blendMode(ADD);
}

float step = PI/360;
color c = #ff9afe;

void draw() {
  background(0);
  
  stroke(c);

  for (float t = -PI; t <= PI; t += step) {
    float x1 = cos(t);
    float y1 = -sin(t);
    float r = (sin(t)*sqrt(abs(cos(t))) / (sin(t) + 7.0/5.0)) - 2.0*sin(t) + 2.0;
    //float r = 1 - cos(t);
    r *= 20;
    for (float ri = 0; ri <= r; ri += 1.0) {
      float x = x1 * ri + 50;
      float y = y1 * ri + 17;
      point(x, y);
    }
  }

}
