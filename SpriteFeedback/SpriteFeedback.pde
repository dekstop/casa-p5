// Sprites & Feedback Zoom
// Martin Dittus 2011-10-03
//
// Requires the GLGraphics library, http://glgraphics.sourceforge.net/
// Coefficients (36, 35, 32, 24) from La Monte Young's "The Second Dream of the High-Tension Line Stepdown Transformer"


import processing.opengl.*;
import processing.video.*;
import codeanticode.glgraphics.*;

class Blob {
  public float c1 = 0;
  public float d1 = 36.0;
  public float c2 = 0;
  public float d2 = 35.0f;
  public float c3 = 0;
  public float d3 = 32.0;
  public float c4 = 0;
  public float d4 = 24.0f;
  public float scale = 0.001f;

  Blob(float d1, float d2, float d3, float d4, float scale) {
    this.d1 = d1;
    this.d2 = d2;
    this.d3 = d3;
    this.d4 = d4;
    this.scale = scale;
  }
  
  void move(float speed) {
    c1 += d1 * speed;
    c2 += d2 * speed;
    c3 += d3 * speed;
    c4 += d4 * speed;
  }
  
  void move() {
    move(1.0f);
  }
  
  void draw(GLGraphicsOffScreen g, int alpha) {
    g.fill(
      360 * getHue(), 
      100, 
      100, 
      alpha);
    float d = getSize();
    g.ellipse(
      getX() * g.width/2 + g.width/4, 
      getY() * g.height/2 + g.height/4, 
      d, d);
  }
  
  float getOsc1() {
    return sin(c1 * scale);
  }
  
  float getOsc2() {
    return sin(c2 * scale);
  }
  
  float getOsc3() {
    return sin(c3 * scale);
  }
  
  float getOsc4() {
    return sin(c4 * scale);
  }
  
  // Returns [0..1]
  float getX() {
    return (getOsc1() + getOsc2()) / 4.0f + 0.5f;
  }

  // Returns [0..1]
  float getY() {
    return (getOsc3() + getOsc4()) / 4 + 0.5f;
  }
  
  float getSize() {
    return abs(170 * getOsc1() * getOsc4() + 170);
  }
  
  float getHue() {
    return getOsc2() / 2.0f + 0.5f;
  }
}

GLGraphicsOffScreen glg1;
MovieMaker mm;
float speed = 1.0f;
boolean isRecording = false;
int clipCounter = 0;
String clipNamePrefix = "clip-" + System.currentTimeMillis() + "-";

void setup() {
//  size(1200, 700, GLConstants.GLGRAPHICS);
  size(500, 500, GLConstants.GLGRAPHICS);
  
  glg1 = new GLGraphicsOffScreen(this, width, height, true, 0);
  glg1.beginDraw();
  glg1.noStroke();
  glg1.fill(0, 0, 0);
  glg1.rect(0, 0, width, height);
  glg1.endDraw();
  
  smooth();
  noStroke();
  fill(0, 0, 0);
  rect(0, 0, width, height);
}

float scale_factor = 1f;
Blob blob1 = new Blob(36.0f, 35.0f, 32.0f, 24.0f, 0.0015f * scale_factor);
Blob blob2 = new Blob(35.0f, 36.0f, 24.0f, 32.0f, 0.0031f * scale_factor);
Blob blob3 = new Blob(36.0f, 24.0f, 32.0f, 35.0f, 0.0019f * scale_factor);

Blob blob4 = new Blob(36.0f, 35.0f, 32.0f, 24.0f, 0.00151f * scale_factor);
Blob blob5 = new Blob(35.0f, 36.0f, 24.0f, 32.0f, 0.00311f * scale_factor);
Blob blob6 = new Blob(36.0f, 24.0f, 32.0f, 35.0f, 0.00191f * scale_factor);

Blob blob7 = new Blob(36.0f, 35.0f, 32.0f, 24.0f, 0.001501f * scale_factor);
Blob blob8 = new Blob(35.0f, 36.0f, 24.0f, 32.0f, 0.003101f * scale_factor);
Blob blob9 = new Blob(36.0f, 24.0f, 32.0f, 35.0f, 0.001901f * scale_factor);

void draw() {
  glg1.beginDraw();
  
  // clear  
  int clear_alpha = round(1 + 5.0/2.0 * ((
    sin(blob1.c2 * 0.000007f) + 
    sin(blob2.c3 * 0.000007f) + 
    sin(blob3.c4 * 0.000007f)) / 3.0 + 1.0));
  glg1.fill(0, 0, 0, clear_alpha);
  glg1.rect(0, 0, width, height);
  
  // blobs
  glg1.colorMode(HSB, 360, 100, 100, 100);
  
  int draw_alpha = round(60 + 25 / 2.0 * ((
    sin(blob1.c2 * 0.000137f) + 
    sin(blob2.c3 * 0.000137f) + 
    sin(blob3.c4 * 0.000137f)) / 3.0 + 1.0));

  blob1.move(speed);
  blob1.draw(glg1, draw_alpha);
  blob2.move(speed);
  blob2.draw(glg1, draw_alpha);
  blob3.move(speed);
  blob3.draw(glg1, draw_alpha);

  blob4.move(speed);
  blob4.draw(glg1, draw_alpha);
  blob5.move(speed);
  blob5.draw(glg1, draw_alpha);
  blob6.move(speed);
  blob6.draw(glg1, draw_alpha);

  blob7.move(speed);
  blob7.draw(glg1, draw_alpha);
  blob8.move(speed);
  blob8.draw(glg1, draw_alpha);
  blob9.move(speed);
  blob9.draw(glg1, draw_alpha);

  glg1.colorMode(RGB);

  glg1.endDraw();

  glg1.beginDraw();
  // feedback
  GLTexture tex1 = glg1.getTexture();
  float zoom = 25.0f + 15.0f * (
    sin(blob1.c1 * 0.00011f) + 
    sin(blob2.c2 * 0.00011f) + 
    sin(blob3.c3 * 0.00011f)) / 3.0f;
  glg1.image(tex1, -zoom/2, -zoom/2, width+zoom, height+zoom);

  glg1.endDraw();
  
  image(glg1.getTexture(), 0, 0, width, height); 
  
  if (isRecording && mm!=null) {
    mm.addFrame();
//    text("rec", 10, 20);
  }
}

void keyPressed() {
  switch (key) {
    case '+': speed += 0.1f; break;
    case '-': speed -= 0.1f; break;
    case '0': speed = 1.0f; break;
    case 'r':
      if (isRecording) {
        println("Stop recording.");
        mm.finish();
        mm = null;
      }
      else {
        String clipName = clipNamePrefix + clipCounter + ".mov";
        clipCounter++;
        println("Recording to: " + clipName);
        mm = new MovieMaker(this, width, height, 
          clipName,
          30, MovieMaker.MOTION_JPEG_B, MovieMaker.BEST);
      }
      isRecording = !isRecording;
      break; // 'r'
  }
}

void stop() {
  if (isRecording && mm!=null) {
    mm.finish();
  }
}
