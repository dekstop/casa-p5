import processing.video.*;

MovieMaker mm;

void setup() {
  size(500, 500);
  mm = new MovieMaker(this, width, height, 
          "movies/test.mov",
          30, MovieMaker.MOTION_JPEG_B, MovieMaker.BEST);
}

void stop() {
  mm.finish();
}

void draw() {
  float a = frameCount / 100.0;
  float x = width * (0.5 + cos(a)/2.0);
  float y = height * (0.5 + sin(a)/2.0);
  
  smooth();
  background(0);
  fill(255);
  noStroke();
  ellipse(x, y, 10, 10);
  
  mm.addFrame();
}

void keyPressed() {
  if (key==' ') {
    saveFrame();
  }
}
