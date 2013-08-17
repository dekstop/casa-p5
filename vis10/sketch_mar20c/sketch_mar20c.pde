
// Entropy maximisation model.
// beta = 1 / x0  # x0: drop-off coefficient (small x0: small range)
// 
// Y_ij = O_i * exp(-beta * d_ij) / sum_j(exp(-beta * d_ij))
//
// Steps:
// * determine purchases based on probabilities
// * determine all d_ij for each combination of shop and origin
//   * then pick randomly allocated destination based on probabilities
// * travel
// * Lotka-Volterra (arriving flows vs cost)
//   * every time an agent arrives they deposit some money:
//     deltaZ_j = E * Z_j(D_j - c * Z_j)
//   * note: don't set cost c too high

import processing.video.*;


float G = 500;
float minX0 = 10;
float maxX0 = 100;

List<Agent> agents;
ArrayList<Place> places;
Grid grid;

MovieMaker mm;

void setup() {
  colorMode(HSB);
  size(1920, 1080, P3D);
  buildScene();
}

void buildScene() {
 agents = new ArrayList<Agent>();
 places = new ArrayList<Place>();
 for (int i=0; i<5; i++) {
   places.add(new Place(random(width), random(height), random(minX0, maxX0)));
 }
 grid = new Grid(places);
}

void draw() {
  println(frameCount);
  float t = frameCount / 100.0;
  camera(
    width*cos(t), height*sin(t), height, // pos
    width/2, height/2, 0, // target
    0, 0, -1 // rotation
    );

  background(255);
  smooth();
  
  grid.display();
  
//  if (agents.size() < 100) {
//    agents.add(new Agent());
//  }
//  
//  for (int i=0; i<agents.size(); i++) {
//    Agent a = agents.get(i);
//    a.gravity(place);
//    a.step();
//    a.display();
//    if (PVector.dist(a.p, place.p) < 25) {
//      agents.remove(i);
//      i--;
//    }
//  }

  for (Place place : places) {
    place.display();
  }

  // Record
  if (mm!=null) {
    mm.addFrame();
  }
}

void stop() {
  stopRecording();
}

void startRecording() {
  println("Starting recording...");
  mm = new MovieMaker(this, width, height, 
    "recording-" + System.currentTimeMillis() + ".mov",
    30, MovieMaker.MOTION_JPEG_B, MovieMaker.BEST);
}

void stopRecording() {
  println("Stopping recording.");
  if (mm!=null) {
    mm.finish();
    mm = null;
  }
}

void keyPressed() {
  switch (key) {
    case ' ': buildScene(); break;
    case 'r':
      if (mm==null) {
        startRecording();
      } else {
        stopRecording();
      }
      break;
  }
}

/**
 * Agent class.
 */
class Agent {
  PVector p, v;
  
  Agent() {
    p = new PVector(random(10, width-10), random(10, height-10));
    float angle = random(0, TWO_PI);
    v = new PVector(cos(angle), sin(angle));
  }
  
  void gravity(Place place) {
    PVector dir = PVector.sub(place.p, p);
//    float r12 = constrain(dir.mag(), 1, 1000);
    float r12 = dir.mag();
    dir.normalize();
    if (r12>0) {
      dir.mult(G/(r12*r12));
    } else {
      dir.mult(0);
    }
    v.add(dir);
  }
  
  void step() {
    p.add(v);
    v.mult(0.99);
  }
  
  void display() {
    noStroke();
    fill(0);
    pushMatrix();
      int x = round(constrain(p.x/grid.bin, 0, grid.z.length-1));
      int y = round(constrain(p.y/grid.bin, 0, grid.z.length-1));
      translate(p.x, p.y, grid.z[x][y]);
      ellipse(0, 0, 10, 10);
    popMatrix();
  }
}

/**
 * Place class.
 */
class Place {
  PVector p;
  float x0;
  
  Place(float x, float y, float x0) {
    p = new PVector(x, y);
    this.x0 = x0;
  }
  
  void display() {
    noFill();
    stroke(0, 255, 255);
    strokeWeight(3);
    ellipse(p.x, p.y, 30, 30);
    strokeWeight(1);
  }
}

/**
 * Grid class.
 */
class Grid {
  float z[][] = new float[100][100];
  float bin;
  
  Grid(List<Place> places) {
    bin = width / 100.0;
    
    // forces
    for (int x=0; x<z.length; x++) {
      for (int y=0; y<z[x].length; y++) {
        PVector p = new PVector(x * bin, y*bin);
        z[x][y] = 0;
        for (Place place : places) {
          float d = p.dist(place.p);
          z[x][y] += - G * exp(-d/place.x0);
        }
//        d = d * 0.01; // cheating for vis purposes
//        if (d==0) {
//          z[x][y] = -G;
//        } else {
//          z[x][y] = -G / (d*d);
//        }
      }
    }
  }
  
  void display() {
    for (int x=1; x<z.length; x++) {
      for (int y=1; y<z[x].length; y++) {
        stroke(128 - abs(z[x][y] / 10), 200, 200);
        line(
          bin*(x-1), bin*y, z[x-1][y], 
          bin*x, bin*y, z[x][y]);
        line(
          bin*x, bin*(y-1), z[x][y-1], 
          bin*x, bin*y, z[x][y]);
      }
    }
  }
}
