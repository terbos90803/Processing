PImage img, distImg;
final int numDotStars = 72;
final int bottomOffset = 25;

void setup() {
  size(640, 360);
  // The image file must be in the data folder of the current sketch 
  // to load successfully
  img = loadImage("finallogo72x72_clean.png");  // Load the image into the program
  distImg = distortImage(img);

  exportImage();
}

void draw() {
  // Displays the image at its actual size at point (0,0)
  image(img, 0, 0);

  // draw the polar frame to simulate the sweep of the stick
  pushMatrix();
  translate(width/2, 0);
  drawPolarImage(img);
  popMatrix();

  // draw the distorted image
  pushMatrix();
  translate(0, height/2);
  image(distImg, 0, 0);
  popMatrix();

  // draw the polar display of the distorted image
  pushMatrix();
  translate(width/2, height/2);
  drawPolarImage(distImg);
  popMatrix();
}

void drawPolarImage(PImage polarImg)
{
  for (int x = 0; x < polarImg.width; ++x)
  {
    float theta = HALF_PI + map(x, 0, polarImg.width, -QUARTER_PI, QUARTER_PI);
    for (int y = 0; y < polarImg.height; ++y)
    {
      float r = map(y, 0, polarImg.height, numDotStars+bottomOffset, bottomOffset);

      float x1 = r * cos(theta);
      float y1 = numDotStars+bottomOffset - r * sin(theta);
      stroke(polarImg.get(x, y));
      point(x1, y1);
    }
  }
}

color getPixelColorSafe(PImage pimg, float x, float y)
{
  int x1 = (int)constrain(x, 0, pimg.width-1);
  int y1 = (int)constrain(y, 0, pimg.height-1);
  return pimg.get(x1, y1);
}

color bilerpColor(PImage pimg, float x, float y)
{
  color ul = getPixelColorSafe(pimg, floor(x), floor(y));
  color ur = getPixelColorSafe(pimg, ceil(x), floor(y));
  color ll = getPixelColorSafe(pimg, floor(x), ceil(y));
  color lr = getPixelColorSafe(pimg, ceil(x), ceil(y));

  color high = lerpColor(ul, ur, x - floor(x));
  color low = lerpColor(ll, lr, x - floor(x));
  return lerpColor(high, low, y - floor(y));
}

PImage distortImage(PImage inImg)
{
  PImage dImg = createImage(72, numDotStars, ARGB);

  for (int x = 0; x < dImg.width; ++x)
  {
    float theta = HALF_PI + map(x, 0, dImg.width, -QUARTER_PI, QUARTER_PI);
    for (int y = 0; y < dImg.height; ++y)
    {
      float r = map(y, 0, dImg.height, numDotStars+bottomOffset, bottomOffset);

      float x1 = inImg.width/2 + r * cos(theta);
      float y1 = numDotStars+bottomOffset - r * sin(theta);

      dImg.set(x, y, bilerpColor(inImg, x1, y1));
    }
  }

  return dImg;
}

void exportImage()
{
  // Pick an output filename
  selectOutput("Choose the output file", "doExport");
}

class Colormap {
  IntList map;
  int mask;

  // Build a colormap that fits in 256 entries
  Colormap(PImage image)
  {
    for (mask = 0xff; mask > 0; mask = (mask << 1) & 0xff)
    {
      map = new IntList();
      for (int y = 0; y < image.height; ++y)
      {
        for (int x = 0; x < image.width; ++x)
        {
          color c = flatten(distImg.get(x, y));
          int colIx = lookup(c);
          if (colIx == -1)
          {
            colIx = map.size();
            map.append(c);
          }
        }
      }

      println("Colormap mask=" + hex(mask, 2) + "  size=" + map.size());
      if (map.size() < 256)
      {
        return;
      }
    }

    println("Could not produce workable colormap");
    exit();
  }

  // Flatten alpha channel of color by blending with RGB channels
  color flatten(color c)
  {
    float a = ((c >> 24) & 0xff) / 255.0 / 2.0;  // extra 2.0 is temp hack to dim by 50% to prevent brownouts
    int r = (int)(((c >> 16) & 0xff) * a) & mask;
    int g = (int)(((c >> 8) & 0xff) * a) & mask;
    int b = (int)(((c >> 0) & 0xff) * a) & mask;
    return (r << 16) | (g << 8) | b;
  }

  // Find color in colormap
  int lookup(color c)
  {
    for (int ix = 0; ix < map.size(); ++ix)
    {
      if (map.get(ix) == c)
      {
        return ix;
      }
    }
    return -1;
  }

  // Find index of RGBA color
  int indexOf(color rgba)
  {
    int colIx = lookup(flatten(rgba));
    if (colIx == -1)
    {
      println("Error: failed to lookup color");
      exit();
    }
    return colIx;
  }
}

void doExport(File output)
{
  if (output == null) {
    println("Window was closed or the user hit cancel.");
    return;
  }
  println("User selected " + output.getAbsolutePath());
  PrintWriter file = createWriter(output.getAbsolutePath());
  String[] nameSplit = split(output.getName(), ".");
  String basename = nameSplit[0];

  // scan through the image in column first order, top to bottom, left to right
  // Collect the colormap on the way through the image
  Colormap colormap = new Colormap(distImg);
  // Collect the column start indices
  IntList colStart = new IntList();
  int dataSize = 0;

  file.println("// Raster image");
  file.println("#include \"Raster.h\"");
  file.println();

  file.println("static const uint8_t " + basename + "Image[] PROGMEM = {");
  // Column loop
  for (int x = 0; x < distImg.width; ++x)
  {
    IntList column = new IntList();
    int runLength = 0;
    int col = 0;

    // Row loop
    for (int y = 0; y < distImg.height; ++y)
    {
      // Translate RGB color to colormap index
      int colIx = colormap.indexOf(distImg.get(x, y));

      // Merge this pixel into the run length encoded column
      if (colIx != col)
      {
        // New run
        if (runLength > 0) {
          column.append(runLength);
          column.append(col);
          runLength = 0;
          col = colIx;
        }
      }
      // Extend current run
      ++runLength;
    }
    // Save last run
    if (runLength > 0) {
      column.append(runLength);
      column.append(col);
    }
    // Save index to start of column
    colStart.append(dataSize);
    dataSize += column.size() + 1; // Number of bytes in the encoded data, including the run count.

    // Dump column
    file.print("  0x" + hex(column.size()/2, 2) + ", ");
    for (int ix = 0; ix < column.size(); ix += 2)
    {
      file.print("0x" + hex(column.get(ix), 2) + ", 0x" + hex(column.get(ix+1), 2) + ", ");
    }
    file.println();
  }
  file.println("};");

  // Dump Column start indices
  file.println("static const uint16_t " + basename + "ColStart[] PROGMEM = {");
  file.print("  ");
  for (int i = 0; i < colStart.size(); ++i)
  {
    file.print(colStart.get(i) + ", ");
  }
  file.println();
  file.println("};");

  // Dump Colormap
  file.println("static const uint32_t " + basename + "Colormap[] PROGMEM = {");
  for (int i = 0; i < colormap.map.size(); ++i)
  {
    if (i % 8 == 0)
      file.print("  ");
    file.print("0x" + hex(colormap.map.get(i), 6));
    if (i + 1 < colormap.map.size())
      file.print(", ");
    if (i % 8 == 7 || i + 1 == colormap.map.size())
      file.println();
  }
  file.println("};");

  // Instantiate Raster
  file.println("#define RASTER_" + basename + " Raster " + basename + "Raster(strip,"
    + distImg.width + "," + distImg.height + ","
    + basename + "Image," + basename + "ColStart," + basename + "Colormap);");

  file.flush();
  file.close();

  println("Image dimensions: " + distImg.width + " x " + distImg.height);
  println("Compressed byte size: " + dataSize);
  println("Colormap entries: " + colormap.map.size());

  exit();
}
