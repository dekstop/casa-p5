// Sprites & Feedback Zoom
// Martin Dittus 2011-10-03
//
// Requires the GLGraphics library, http://glgraphics.sourceforge.net/
// Coefficients (36, 35, 32, 24) from La Monte Young's "The Second Dream of the High-Tension Line Stepdown Transformer"


import processing.opengl.*;
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
  
  void move() {
    c1 += d1;
    c2 += d2;
    c3 += d3;
    c4 += d4;
  }
  
  void draw(GLGraphicsOffScreen g) {
    g.fill(
      360 * getHue(), 
      100, 
      100, 
      90);
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

void setup() {
  size(500, 500, GLConstants.GLGRAPHICS);
  
  glg1 = new GLGraphicsOffScreen(this, width, height, true, 0);
  glg1.beginDraw();
  glg1.noStroke();
  glg1.fill(255, 255, 255);
  glg1.rect(0, 0, width, height);
  glg1.endDraw();
  
  smooth();
  noStroke();
  fill(255, 255, 255);
  rect(0, 0, width, height);
}

Blob blob1 = new Blob(36.0f, 35.0f, 32.0f, 24.0f, 0.0015f);
Blob blob2 = new Blob(35.0f, 36.0f, 24.0f, 32.0f, 0.0031f);
Blob blob3 = new Blob(36.0f, 24.0f, 32.0f, 35.0f, 0.0019f);

void draw() {
  glg1.beginDraw();
  
  // feedback
  GLTexture tex1 = glg1.getTexture();
  float zoom = 20.0f + 15.0f * (
    sin(blob1.c1 * 0.00011f) + 
    sin(blob2.c2 * 0.00011f) + 
    sin(blob3.c3 * 0.00011f)) / 3.0f;
  println(zoom);
  glg1.image(tex1, -zoom/2, -zoom/2, width+zoom, height+zoom);

  // clear  
  glg1.fill(255, 255, 255, 3);
  glg1.rect(0, 0, width, height);
  
  // blobs
  glg1.colorMode(HSB, 360, 100, 100, 100);

  blob1.move();
  blob1.draw(glg1);

  blob2.move();
  blob2.draw(glg1);

  blob3.move();
  blob3.draw(glg1);

  glg1.colorMode(RGB);

  glg1.endDraw();
  
  image(glg1.getTexture(), 0, 0, width, height); 
}

