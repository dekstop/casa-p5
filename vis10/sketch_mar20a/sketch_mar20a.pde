
// Inverse square law of gravity:
// G = (m_1 * m_2) / r_12^2    # gravity, mass, radius
// r_12 = dist(o_1, o_2)       # distance
// F = m_1 * a                 # force
// a = delta_v / delta_t       # acceleration
// v = delta_pos               # velocity: change of position

float G = 1000;

List<Agent> agents;
Place place;

void setup() {
  size(500, 500);
  buildScene();
}

void buildScene() {
 agents = new ArrayList<Agent>();
 place = new Place(width/2, height/2);
}

void draw() {
  if (agents.size() < 100) {
    agents.add(new Agent());
  }

  background(255);
  smooth();
  
  place.display();
  
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
}

void keyPressed() {
  switch (key) {
    case ' ': buildScene(); break;
  }
}

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
    ellipse(p.x, p.y, 5, 5);
  }
}

class Place {
  PVector p;
  
  Place(float x, float y) {
    p = new PVector(x, y);
  }
  
  void display() {
    noFill();
    stroke(200, 0, 0);
    ellipse(p.x, p.y, 30, 30);
  }
}
