
List<Agent> agents = new ArrayList<Agent>();
PrintWriter pr;

void setup() {
  colorMode(HSB);
  size(800, 600);

  for (int i=0; i<100; i++) {
    agents.add(new Agent(i, random(2, 5)));
  }
  
  pr = createWriter("dataOut/out.csv");
  pr.println("time, ID, px, py, vx, vy");
}

void draw() {
  noStroke();
  fill(255/4, 200, 100, 10);
  rect(0, 0, width, height);
  
  for (Agent a : agents) {
    a.move();
    a.draw();
    if (frameCount < 100) {
      write(pr, a);
    }
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

class Agent {
  int id;
  PVector p;
  PVector v;
  PVector target;
  float speed;
  
  public Agent(int id, float speed) {
    this.id = id;
    p = new PVector(width/3, random(30, height-30));
    target = new PVector(width*2/3, height/2 + random(-height/4, height/4));
    v = new PVector(random(-10, 10), random(-10, 10));
    v.normalize();
    this.speed = speed;
  }
  
  void move() {
    PVector aim = PVector.sub(target, p);
    float m = aim.mag();
    if (m >= speed) {
      v.normalize();
      v.mult(20);
      aim.normalize();
      v = PVector.add(v, aim);
      v.normalize();
      v.mult(speed);
    } else {
      p.set(target);
      v = new PVector(0, 0);
    }
    p.add(v);
  }
  
  void draw() {
    noStroke();
    fill(0, 200, 100, 50);
    ellipse(p.x, p.y, 15, 15);

    stroke(0, 255, 255, 50);
    line(p.x, p.y, p.x + v.x*10, p.y + v.y*10);

    noFill();
    stroke(255, 0, 255, 30);
    ellipse(target.x, target.y, 10, 10);
    line(p.x, p.y, target.x, target.y);
  }
}

