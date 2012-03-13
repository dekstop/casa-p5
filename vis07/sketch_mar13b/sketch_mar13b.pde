
// Swarm with spawning, seeking, primitive collision detection,
// with a maze generator to generate obstacles.
// Martin Dittus, March 2012.

/*
 * Constants.
 */

// Maze dimensions, in cells.
int mazeW = 2;
int mazeH = 15;

// Likelihood that adjacent cells are separated by a wall.
// This is used for the initial maze seed.
float mazeWallP = 0.3;

// Wall width, relative to cell size. Sensible values: [0.1 .. 0.9]
float minWallSize = 0.1;
float maxWallSize = 0.7;

// Agents.
int numAgents = 100;

// Larger agents will be faster.
float minSize = 5;
float maxSize = 10;
float minSpeed = 0.5;
float maxSpeed = 2;

// How quickly can they turn?
float aimAdjust = 0.2;

// How keen are they to avoid collisions?
float collisionAdjust = 0.9;

/*
 * Variables.
 */

Maze maze;
PVector mazePos;
PVector mazeSize;

PVector target;

int agentId = 0; // running counter
List<Agent> agents = new ArrayList<Agent>();

/*
 * Main app.
 */

void setup() {
  colorMode(HSB);
  size(800, 600);
  buildScene();
}

void draw() {
  // Background.
  noStroke();
  fill(255/4, 200, 100);
  rect(0, 0, width, height);
  
  // Maze.
  maze.draw(mazePos.x, mazePos.y, mazeSize.x, mazeSize.y);

  // Spawn point and target.
  noFill();
  stroke(0, 0, 200, 100);
  
  rect(width/6-5, 30, 10, height-60); // spawn point
  
  strokeWeight(5);
  ellipse(target.x, target.y, 20, 20); // target
  strokeWeight(1);
  
  // Agents
  for (Agent a : agents) {
    a.move();
    a.draw();
  }
  
  for (int i=0; i<agents.size(); i++) {
    if (agents.get(i).arrived) {
      agents.remove(i);
    }
  }
  
  // Spawn 1% agents max per iteration
  int numSpawned=0;
  while (agents.size() < numAgents && numSpawned<round(numAgents/100.0)) {
    float size = random(1);
    size *= size * size * size * size; // few large ones
    agents.add(new Agent(agentId++, 
      map(size, 0, 1, minSpeed, maxSpeed), 
      map(size, 0, 1, minSize, maxSize), 
      new PVector(width/6, random(30, height-30)),
      target));
    numSpawned++;
  }
}

void buildScene() {
  maze = new Maze(mazeW, mazeH, mazeWallP, minWallSize, maxWallSize);
  mazePos = new PVector(width/3, height*0.1);
  mazeSize = new PVector(width/8, height*0.8);

  target = new PVector(width*4/5, height/2);
}

void keyPressed() {
  switch(key) {
    case ' ': 
      buildScene();
      break;
  }
}

/**
 * Maze class.
 * Uses a graph-based approach: cells are nodes, walls are edges.
 * First builds a fully connected graph, then recursively removes walls.
 * Randomises wall strength for further shape variation.
 */
class Maze {

  class Node {
    Set<Node> walls = new HashSet<Node>();
    int x;
    int y;
    boolean visited = false;
  
    public Node(int x, int y) {
      this.x = x;
      this.y = y;
    }
  }
  
  int w, h;
  float wallP;
  float minWallSize, maxWallSize;
  
  Node[][] maze;
  float[][] wallSize;
  
  public Maze(int w, int h, float wallP, float minWallSize, float maxWallSize) {
    this.w = w;
    this.h = h;
    this.wallP = wallP;
    this.minWallSize = minWallSize;
    this.maxWallSize = maxWallSize;
    
    this.maze = new Node[w+1][h+1];
    this.wallSize = new float[w+1][h+1];
    
    buildMaze();
  }
  
  void draw(float x, float y, float width, float height) {    
    float cw = (float)width / w;
    float ch = (float)height / h;
    noStroke();
    fill(0);
    for (int i=0; i<w+1; i++) {
      for (int j=0; j<h+1; j++) {
        Node a = maze[i][j];
        for (Node b : a.walls) {
          if (b.x>a.x || b.y>a.y) { // prevent double-drawing
            // draw wall between nodes
            float ww = cw * wallSize[i][j];
            float wh = ch * wallSize[i][j];
            rect(
              x + a.x * cw - ww / 2, 
              y + a.y * ch - wh / 2, 
              (b.x - a.x) * cw + ww,
              (b.y - a.y) * ch + wh);
          }
        }
      }
    }
  }
  
  void buildMaze() {
    buildGraph();
    visitNode(maze[0][0]);
    
    // randomise wall thickness
    for (int i=0; i<w+1; i++) {
      for (int j=0; j<h+1; j++) {
        wallSize[i][j] = random(minWallSize, maxWallSize);
      }
    }
    
    agents.clear();
    agentId = 0;
  }
  
  // Builds an initial maze graph where all cells still have four walls.
  void buildGraph() {
    for (int i=0; i<w+1; i++) {
      for (int j=0; j<h+1; j++) {
        maze[i][j] = new Node(i, j);
      }
    }
    for (int i=0; i<w+1; i++) {
      for (int j=0; j<h+1; j++) {
        if (i>0 && random(1) < wallP) addWall(maze[i][j], maze[i-1][j]);
        if (j>0 && random(1) < wallP) addWall(maze[i][j], maze[i][j-1]);
      }
    }
  }
  
  void addWall(Node a, Node b) {
    a.walls.add(b);
    b.walls.add(a);
  }
  
  void removeWall(Node a, Node b) {
    a.walls.remove(b);
    b.walls.remove(a);
  }
  
  void visitNode(Node a) {
    if (a.visited) {
      return;
    }
    a.visited = true;
    
    List<Node> walls = new ArrayList<Node>(a.walls);
    Collections.shuffle(walls);
    for (Node b : walls) {
      if (!b.visited) {
        removeWall(a, b);
        visitNode(b);
      }
    }
  }
}

/**
 * Agent class.
 */

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
    this.hue = round((id * 0.5) % 255);
    this.p = p;
    //target = new PVector(width*2/3, height/2 + random(-height/4, height/4));
    this.target = target;
    v = new PVector(random(-10, 10), random(-10, 10));
    v.normalize();
    this.speed = speed;
    this.size = size;
  }
  
  void move() {
    aimAtTarget();
    avoidCollision();
    step();
    if (dist(p.x, p.y, target.x, target.y)<size*2) {
      arrived = true;
    }
  }
  
  protected void aimAtTarget() {
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
  
  protected void avoidCollision() {
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
  
  protected void step() {
    v.normalize();
    v.mult(speed);
    p.add(adjustForCollision(p, v));
  }
  
  // Test if agent can move from p to p+v without colliding with a wall.
  // Will adjust v in case of collision. 
  // Returns new v.
  protected PVector adjustForCollision(PVector p, PVector v) {
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
    line(p.x, p.y, p.x + v.x*(minSize*3 + speed*2), p.y + v.y*(minSize*3 + speed*2));
  }
}
