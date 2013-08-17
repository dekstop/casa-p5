float[][] coords;

void setup() {
  size(500, 500, P3D);
  coords = readCoords("twitter.csv");
  //printCoords(coords);
}

void draw() {
  background(0);
  stroke(255);
//  strokeWidth(1);
//  noStroke();
  smooth();
  
  // TODO: pick better camera angle
  camera(
   250*(1+cos(frameCount/100.0)),
   250*(1+sin(frameCount/100.0)),
   500,
   0, 10, -100,
   0, 0, 1
  );
  for (int i=0; i<coords.length; i++) {
    float z = map(coords[i][0], 10*60, 60*24, 0, height);
    float x = map(coords[i][1], 51, 52, 0, width);
    float y = map(coords[i][2], -1, 1, 0, height);
    point(x, y, z);
//    ellipse(x, y, 1, 1);
  }
}

float[][] readCoords(String filename) {
  String[] lines = loadStrings(filename);
  float[][] coords = new float[lines.length][3];
  for (int i=1; i<lines.length; i++) {
    String[] col = split(lines[i], ",");
    String[] ts = split(col[0], ":");
    coords[i][1] = float(ts[0]) * 60 + float(ts[1]);
    coords[i][1] = float(col[1]);
    coords[i][2] = float(col[2]);
  }
  return coords;
}

void printCoords(float[][] coords) {
  for (int i=0; i<coords.length; i++) {
    println(coords[i][0] + " " + coords[i][1]);
  }
}
