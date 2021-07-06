class Star {
  public float x, y;
  public float vx, vy;
  public float ax, ay;
  
  static final float source_radius = 10.0;
  static final float accel = 0.5;
  
  public Star() {
    float cx = width / 2.0;
    float cy = height / 2.0;
    
    float r = random(0, source_radius);
    float a = random(0, 2*PI);
    
    ax = accel * cos(a);
    ay = accel * sin(a);
    
    vx = vy = 0;
    
    x = cx + r * cos(a);
    y = cy + r * sin(a);
  }
  
  public void update() {
    x += vx;
    y += vy;
    vx += ax;
    vy += ay;
  }
  
  public void draw() {
    point(x, y);
  }
  
  public boolean isGone() {
    return x < 0 || y < 0 || x > width || y > height;
  }
}

void setup() {
  size(100, 100);
  frameRate(10);
  //colorMode(HSB, 100);
  //  blendMode(ADD);
}

float step = PI/360;
color c = #ffffff;

Star stars[] = new Star[50];

void draw() {
  background(0);
  
  stroke(c);
  
  int makeNew = 2;
  
  for (int i = 0; i < stars.length; ++i) {
    if (makeNew > 0 && (stars[i] == null || stars[i].isGone())) {
      stars[i] = new Star();
      --makeNew;
    }
    
    if (stars[i] != null) {
      if (stars[i].isGone())
        stars[i] = null;
      else {
        stars[i].draw();
        stars[i].update();
      }
    }
  }
}
