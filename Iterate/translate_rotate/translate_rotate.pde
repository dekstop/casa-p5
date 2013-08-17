
// Martin Dittus, Oct 2011.

import processing.opengl.*;
import codeanticode.glgraphics.*;

GLGraphicsOffScreen glg1;

void drawShape(GLGraphicsOffScreen g, int x, int y, float radius) {
  g.ellipse(x, y, radius/2f, radius/2f);
  g.ellipse(x + radius/2f, y, radius/4f, radius/4f);
  g.ellipse(x - radius/2f, y, radius/4f, radius/4f);
  g.ellipse(x, y + radius/2f, radius/4f, radius/4f);
  g.ellipse(x, y - radius/2f, radius/4f, radius/4f);
}

void setup() {
  size(800, 800, GLConstants.GLGRAPHICS);

  glg1 = new GLGraphicsOffScreen(this, width, height, true, 0);
  glg1.smooth();
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

float rot1 = 0.0f;
float dx_rot1 = 0.09f;

float rot2 = PI;
float dx_rot2 = 2*PI / 300000f; //0.0011f;

float trans1 = 0.0f;
float dx_trans1 = 0.013f;

float trans2 = 0.0f;
float dx_trans2 = 0.007f;

int num_objects = 200;

float reScale(float cur, float max, float new_max) {
  return cur * new_max / max;
}

void draw() {
  
  glg1.beginDraw();
  glg1.colorMode(HSB, 360, 100, 100, 100);
  
  // clear 
  glg1.fill(0, 0, 0, 70);
  glg1.rect(0, 0, width, height);
  
  // draw shapes
  float size = (width+height)/4f;
  glg1.translate(width/2, height/2);

  float select = (sin(rot2) + 1) / 2f; // [0..1]

  for (int i=0; i<num_objects; i++) {
    glg1.fill(
      round(
        360f * rot1 / 100f 
        - reScale(i, num_objects, 25f)
        + 6 / reScale(i, num_objects, 25f)) % 360,
      100 - reScale(i, num_objects, 60f), 
      100, 
      5 + sin(reScale(i, num_objects, PI)) * 50);
//    glg1.fill(350, 100, 100, 90);
    drawShape(glg1, 
      -width/30, 
      round(sin(trans2 + reScale(i, num_objects, 3*PI)) * height/5f), 
      size * ((float)num_objects / i) * 0.01);
    glg1.translate(
      sin(reScale(i, num_objects, 5f) + trans1) * size * 0.1f, 
      reScale(i, num_objects, -100f));

    float a = PI + sin(i / (1f + rot1)) * PI;
    float b = PI + sin(i) * PI;
    glg1.rotate(select * a + (1f - select) * b);
//      PI + sin(i / (1f + rot1)) * PI);
  }
  
  rot1 += dx_rot1;
  rot2 += dx_rot2;
  trans1 += dx_trans1;
  trans2 += dx_trans2;
 
  // done  
  glg1.endDraw();

  // feedback
  glg1.beginDraw();
  GLTexture tex1 = glg1.getTexture();
  float zoom = size + size * sin(rot2 * 0.011f) / 3.0f;
  glg1.image(tex1, -zoom/2, -zoom/2, width+zoom, height+zoom);
  glg1.endDraw();
  
  // display
  image(glg1.getTexture(), 0, 0, width, height); 
}

