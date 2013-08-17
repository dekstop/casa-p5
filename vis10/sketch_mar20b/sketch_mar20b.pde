
// Inverse square law of gravity:
// G = (m_1 * m_2) / r_12^2    # gravity, mass, radius
// r_12 = dist(o_1, o_2)       # distance
// F = m_1 * a                 # force
// a = delta_v / delta_t       # acceleration
// v = delta_pos               # velocity: change of position

float G = 1000;

List<Agent> agents;
Place place;
Grid grid;

void setup() {
  colorMode(HSB);
  size(500, 500, P3D);
  buildScene();
}

void buildScene() {
 agents = new ArrayList<Agent>();
 place = new Place(width/2, height/2);
 grid = new Grid(place);
}

void draw() {
  if (agents.size() < 100) {
    agents.add(new Agent());
  }
  
  float t = frameCount / 100.0;
  camera(
    width*cos(t), height*sin(t), height, // pos
    width/2, height/2, 0, // target
    0, 0, -1 // rotation
    );

  background(255);
  smooth();
  
  grid.display();
  
  for (int i=0; i<agents.size(); i++) {
    Agent a = agents.get(i);
    a.gravity(place);
    a.step();
    a.display();
    if (PVector.dist(a.p, place.p) < 25) {
      agents.remove(i);
      i--;
    }
  }

  place.display();
}

void keyPressed() {
  switch (key) {
    case ' ': buildScene(); break;
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
  
  Place(float x, float y) {
    p = new PVector(x, y);
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
  
  Grid(Place place) {
    bin = width / 100.0;
    
    // forces
    for (int x=0; x<z.length; x++) {
      for (int y=0; y<z[x].length; y++) {
        PVector p = new PVector(x * bin, y*bin);
        float d = p.dist(place.p);
        d = d * 0.01; // cheating for vis purposes
        if (d==0) {
          z[x][y] = -G;
        } else {
          z[x][y] = -G / (d*d);
        }
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
