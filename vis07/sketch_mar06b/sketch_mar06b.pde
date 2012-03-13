
// Swarm with spawning, seeking, primitive collision detection.
// Martin Dittus, March 2012

int numAgents = 600;
int agentId = 0;

// Larger agents will be faster.
float minSize = 1;
float maxSize = 5;
float minSpeed = 0.5;
float maxSpeed = 2;

// How quickly can they turn?
float aimAdjust = 0.2;

// How keen are they to avoid collisions?
float collisionAdjust = 03;

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
  
  fill(0); // walls
  rect(width/3, height/6, 10, height/5);  
  rect(width*1.5/3, height/2, 10, height/5);
  
  smooth();

  noFill();
  stroke(255, 0, 200, 100);
  
  rect(width/6-5, 30, 10, height-60); // spawn point
  
  strokeWeight(5);
  ellipse(target.x, target.y, 20, 20); // target
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
    size *= size * size * size * size; // few large ones
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
  int hue;
  PVector p;
  PVector v;
  PVector target;
  float speed;
  float size;
  boolean arrived = false;
  
  public Agent(int id, float speed, float size, PVector p, PVector target) {
    this.id = id;
    this.hue = round((id * 0.05) % 255);
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
    p.add(adjustForCollision(p, v));
  }
  
  // Test if agent can move from p to p+v without colliding with a wall.
  // Will adjust v in case of collision. 
  // Returns new v.
  PVector adjustForCollision(PVector p, PVector v) {
    // This is primitive:
    // - assumes walls are always thicker than v's magnitude.
    // - can't determine collision angle
    // TODO: switch to a raycasting approach instead.
    PVector t = PVector.add(p, v);
    color c = get(round(t.x), round(t.y));
    if (red(c)+green(c)+blue(c)==0) { // wall
      v.mult(-1); // back off
      v.add(new PVector(random(-speed/2, speed/2), random(-speed/2, speed/2)));
      v.normalize();
    }
    return v;
  }
  
  void draw() {
    noStroke();
    fill(hue, 255, 255, 200);
    ellipse(p.x, p.y, size, size);

    stroke(hue, 255, 255, 100);
    line(p.x, p.y, p.x + v.x*(5 + speed*2), p.y + v.y*(5 + speed*2));
  }
}

