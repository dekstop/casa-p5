
// Swarm with spawning, seeking.
// Martin Dittus, March 2012

int numAgents = 400;
int agentId = 0;

// Larger agents will be faster.
float minSize = 1;
float maxSize = 10;
float minSpeed = 0.5;
float maxSpeed = 2;

// How quickly can they turn?
float aimAdjust = 0.2;

// How keen are they to avoid collisions?
float collisionAdjust = 1;

List<Agent> agents = new ArrayList<Agent>();
PrintWriter pr;

PVector target;

void setup() {
  colorMode(HSB);
  size(800, 600);
  
  target = new PVector(width*2/3, height/2);
  
  pr = createWriter("dataOut/out.csv");
  pr.println("time, ID, px, py, vx, vy");
}

void draw() {
  noStroke();
  fill(255/4, 200, 100);
  rect(0, 0, width, height);
  
  smooth();

  noFill();
  stroke(255, 0, 200, 100);
  
  rect(width/6-5, 30, 10, height-60);
  
  strokeWeight(5);
  ellipse(target.x, target.y, 20, 20);
  strokeWeight(1);
  
  for (Agent a : agents) {
    a.aimAtTarget();
  }
  for (Agent a : agents) {
    a.avoidCollision();
  }
  for (Agent a : agents) {
    a.move();
    a.draw();
    if (dist(a.p.x, a.p.y, target.x, target.y)<5) {
      a.arrived = true;
    }
    if (frameCount < 100) {
      write(pr, a);
    }
  }
  
  for (int i=0; i<agents.size(); i++) {
    if (agents.get(i).arrived) {
      agents.remove(i);
    }
  }
  while (agents.size() < numAgents) {
    float size = random(1);
    agents.add(new Agent(agentId++, 
      map(size, 0, 1, minSpeed, maxSpeed), 
      map(size, 0, 1, minSize, maxSize), 
      new PVector(width/6, random(30, height-30)),
      target));
  }
  if (frameCount==100) {
    pr.flush();
    pr.close();
  }
}

void write(PrintWriter pr, Agent a) {
  pr.println(
    frameCount + ", " +
    a.id + ", " +
    a.p.x + ", " +
    a.p.y + ", " +
    a.v.x + ", " +
    a.v.y
  );
}

void keyPressed() {
  switch(key) {
    case ' ': setup(); break;
  }
}

class Agent {
  int id;
  PVector p;
  PVector v;
  PVector target;
  float speed;
  float size;
  boolean arrived = false;
  
  public Agent(int id, float speed, float size, PVector p, PVector target) {
    this.id = id;
    this.p = p;
    //target = new PVector(width*2/3, height/2 + random(-height/4, height/4));
    this.target = target;
    v = new PVector(random(-10, 10), random(-10, 10));
    v.normalize();
    this.speed = speed;
    this.size = size;
  }
  
  void aimAtTarget() {
    // direction we should move in
    PVector aim = PVector.sub(target, p);
    aim.normalize();
    
    // actual direction
    PVector curdir = v.get();
    curdir.normalize();
    
    // correction course
    PVector adjust = PVector.sub(aim, curdir);
    adjust.normalize();
    adjust.mult(aimAdjust);
    v.add(adjust);
  }
  
  void avoidCollision() {
    for (Agent other : agents) {
       if (other!=this) {
         if (dist(p.x, p.y, other.p.x, other.p.y) < max(this.size, other.size) * 2) {
           PVector adjust = PVector.sub(p, other.p);
           adjust.normalize();
           adjust.mult(collisionAdjust);
           v.add(adjust);
         }
       }
    }
  }
  
  void move() {
    v.normalize();
    v.mult(speed);
    p.add(v);
  }
  
  void draw() {
    noStroke();
    fill(id * 0.05, 255, 255, 200);
    ellipse(p.x, p.y, size, size);

    stroke(id * 0.05, 255, 255, 200);
    line(p.x, p.y, p.x + v.x*(5 + speed*2), p.y + v.y*(5 + speed*2));
  }
}

