/**
 * Preview the lightbox animations
 */

int frame = 0;

Blob[] blobs = new Blob[5];

void setup() {
  size(100,100);
  frameRate(10);
  colorMode(HSB,100);
  blendMode(ADD);
  
  blobs[0] = new Blob(5, 5);
  blobs[1] = new Blob(25, 12);
  blobs[2] = new Blob(50, 10);
  blobs[3] = new Blob(75, 15);
  blobs[4] = new Blob(90, 8);
}

void draw() {
  background(0);
  for (int y = 0; y < height; y += 5) {
    for (int x = 0; x < width; x += 5) {
      for (int b = 0; b < blobs.length; ++b) {
        stroke(blobs[b].getPixel(x, y));
        point(x, y);
      }
    }
  }
  ++frame;
  for (int b = 0; b < blobs.length; ++b) {
    blobs[b].move();
  }
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

class Blob {
  private final static float tempTop = 0;
  private final static float tempBottom = 100;
  private final static float kBuoy = 0.005;
  private final static float kA = 0.01;

  private final float blobRadius;
  private final float blobRadius2;
  private final float kT; // = 0.05;
  private final color blobColor = color(0 * 100 / 360, 100, 100);
  private final color bkgColor = color(0,0,0);
  
  private float blobx;
  private float blobxv;
  private float bloby = height;
  private float blobyv = 0;
  private float blobTemp = 50;

  public Blob(int x, int r) {
    blobx = x;
    blobRadius = r;
    
    blobRadius2 = blobRadius * blobRadius;
    kT = 5.0 / blobRadius2;
    blobxv = (float)x / (20 * width);
  }
  
  public void move()
  {
    // float blob
    float ytemp = bloby; // Need to interpolate for anything other than height=100
    float tempDiff = ytemp - blobTemp; // positive=blob is colder than surround
    float buoyancy = kBuoy * (tempDiff + 50 - bloby); // negative=accelerate up
    float blobya = kA * buoyancy / (1 + blobyv*blobyv);
    blobTemp += kT * tempDiff;
    blobyv += blobya;
    bloby += blobyv;
    blobx += blobxv * Math.abs(blobyv);
    
    if (bloby < 0) {
      bloby = 0;
      blobyv = 0;
    }
    else if (bloby > height) {
      bloby = height;
      blobyv = 0;
    }
    
    if (blobx < 0 || blobx > width) {
      blobxv = -blobxv;
    }
  }

  public color getPixel(int x, int y)
  {
    // calc the distance from the pixel to the blob center
    float dx = x - blobx;
    float dy = y - bloby;
    float dsq = dx*dx + dy*dy; // work in squared space to avoid a sqrt.
    
    // calc the distance from the pixel to the blob
    return dsq <= blobRadius2 ? blobColor : bkgColor;
  }
}
