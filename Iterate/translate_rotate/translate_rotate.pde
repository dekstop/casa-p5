
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
  size(1200, 500, GLConstants.GLGRAPHICS);

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

float rot2 = 0.0f;
float dx_rot2 = 0.0011f;

float trans1 = 0.0f;
float dx_trans1 = 0.013f;

void draw() {
  
  glg1.beginDraw();
  glg1.colorMode(HSB, 360, 100, 100, 100);
  
  // clear 
  glg1.fill(0, 0, 0, 3);
  glg1.rect(0, 0, width, height);
  
  // draw shapes
  float size = (width+height)/2f;
  glg1.translate(width/2, height/2);

  for (int i=0; i<100; i++) {
    glg1.fill(
      round(360 * rot1 / 100f + i) % 360,
      100, 
      100 - (i/100), 
      15 + i/4f);
//    glg1.fill(350, 100, 100, 90);
    drawShape(glg1, -width/4, 0, size * (100f / i) * 0.01);
    glg1.rotate(
      PI + sin(i / (1f + rot1) + rot2) * PI);
    glg1.translate(sin(i / 20f + trans1) * size * 0.1f, 0);
  }
  
  rot1 += dx_rot1;
  rot2 += dx_rot2;
  trans1 += dx_trans1;
 
  // done  
  glg1.endDraw();

  // feedback
  glg1.beginDraw();
  GLTexture tex1 = glg1.getTexture();
  float zoom = 25.0f + 15.0f * sin(rot1 * 0.00011f) / 3.0f;
  glg1.image(tex1, -zoom/2, -zoom/2, width+zoom, height+zoom);
  glg1.endDraw();
  
  // display
  image(glg1.getTexture(), 0, 0, width, height); 
}

