
// Swarm with spawning, seeking, "fly paper" traps, with a maze generator
// to generate obstacles.
//
// Agents are coloured according to the time they were spawned.
//
// Builds and draws histograms of live agents, and agents that reached
// their target. This allows to observe how quickly agents manage to 
// find a target, a result of the kinds of obstacles they are presented 
// with.
//
// Martin Dittus, March 2012.

// TODO: wall collision checks when targeting, when avoiding other agents
// TODO: better backing off function when hitting wall: e.g. iterate new random direction until not hitting a wall
// TODO: calculate min wall thickness as max speed * x to avoid collision detection failures
// TODO: smaller agents get repelled by larger agents

/*
 * Constants.
 */

// Maze dimensions, in cells.
int mazeW = 7;
int mazeH = 10;

// Likelihood that adjacent cells are separated by a wall.
// This is used for the initial maze seed.
float mazeWallP = 0.75;

// Wall width, relative to cell size. Sensible values: [0.1 .. 0.9]
float minWallSize = 0.25;
float maxWallSize = 0.7;

// Agents.
int numAgents = 800;
int numTargets = 10;

// Larger agents will be faster.
float minSize = 5;
float maxSize = 10;
float minSpeed = 0.5;
float maxSpeed = 2;

// How quickly can they turn?
float aimAdjust = 0.9;

// How keen are they to avoid collisions?
float collisionAdjust = 0.2;

// Stats.
int numHistogramBins = 25;

/*
 * Variables.
 */

Maze maze;
PVector mazePos;
PVector mazeSize;

PVector spawnPoint;
List<PVector> targets = new ArrayList<PVector>();
List<int[]> targetHist = new ArrayList<int[]>();

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
  smooth();
  noFill();
  strokeWeight(5);
  
  stroke(id2hue(agentId), 200, 255, 255);
  ellipse(spawnPoint.x, spawnPoint.y, 20, 20); // spawn point
  
  stroke(0, 0, 200, 100);
  for (int i=0; i<targets.size(); i++) {
    PVector target = targets.get(i);
    ellipse(target.x, target.y, 20, 20); // target
  }

  strokeWeight(1);
  
  // Agents
  for (Agent a : agents) {
    a.move();
    a.draw();
  }

  // Stats.
  fill(0, 0, 0, 100);
  noStroke();
  rect(10, 10, width-20, 20);
  
  int mainHistW = round(width*0.2) / numHistogramBins * numHistogramBins;
  int targetHistW = mainHistW / 2;
  
  int[] agentHist = makeAgentHistogram(agents, numHistogramBins);
  drawHistogram(
    agentHist,
    width - 12 - mainHistW, // - targetHistW*3 - 15*3, 
    12, 
    mainHistW, 16);

  drawHistogram(
    targetHist.get(0),
//    width - 12 - targetHistW*3 - 15*2, 12, 
    targets.get(0).x + 20, targets.get(0).y - 8,
    targetHistW, 16);

  drawHistogram(
    targetHist.get(1),
//    width - 12 - targetHistW*2 - 15, 12, 
    targets.get(1).x + 20, targets.get(1).y - 8,
    targetHistW, 16);

  drawHistogram(
    targetHist.get(2),
//    width - 12 - targetHistW, 12, 
    targets.get(2).x + 20, targets.get(2).y - 8,
    targetHistW, 16);

  fill(0, 0, 255, 200);
  text(agents.size() + " agents", 15, 25);

  // Remove agents that reached their target.  
  for (int i=0; i<agents.size(); i++) {
    if (agents.get(i).arrived) {
      Agent a = agents.remove(i);
      addToTargetHist(a);
    }
  }
  
  // Spawn new agents (at a moderate pace.)
  if (agents.size() < numAgents && random(1)<0.3) {
    float size = random(1);
    size *= size * size * size * size; // agent size: few large ones, many small ones
    PVector p = // spawn point
      new PVector(
        spawnPoint.x + random(-10, 10), 
        spawnPoint.y + random(-10, 10));
    PVector target = targets.get(floor(random(targets.size())));
    agents.add(makeAgent(size, p, target));
  }
}

void buildScene() {
  maze = new Maze(mazeW, mazeH, mazeWallP, minWallSize, maxWallSize);
  mazePos = new PVector(width * 0.3, height * 0.2);
  mazeSize = new PVector(width * 0.4, height * 0.8);

  spawnPoint = new PVector(width * 0.16, height * 0.8);
  
  targets.clear();
  targets.add(new PVector( // top
    random(width * 0.3, width * 0.7), 
    random(height * 0.1, height * 0.15)));
  targets.add(new PVector( // top right
    random(width * 0.75, width * 0.85), 
    random(height * 0.1, height * 0.4)));
  targets.add(new PVector( // bottom right
    random(width * 0.75, width * 0.85), 
    random(height * 0.6, height * 0.9)));
  
  targetHist.clear();
  targetHist.add(new int[numHistogramBins]);
  targetHist.add(new int[numHistogramBins]);
  targetHist.add(new int[numHistogramBins]);
    
  agents.clear();
  agentId = 0;
}

Agent makeAgent(float size, PVector p, PVector target) {
  return new Agent(agentId++, 
    map(size, 0, 1, minSpeed, maxSpeed), 
    map(size, 0, 1, minSize, maxSize), 
    p,
    target);
}

int id2hue(int id) {
  return round((id * 0.1) % 255);
}

int[] makeAgentHistogram(List<Agent> agents, int numBins) {
  int[] hist = new int[numBins];
  for (Agent a : agents) {
    addToAgentHistogram(hist, a);
  }
  return hist;
}

void addToAgentHistogram(int[] hist, Agent a) {
  int bin = round(map(a.hue, 0, 255, 0, hist.length-1));
  hist[bin]++;
}

void drawHistogram(int[] hist, float x, float y, float w, float h) {
  int maxCount = max(hist);
  noStroke();
  for (int bin=0; bin<hist.length; bin++) {
    fill(map(bin, 0, hist.length, 0, 255), 255, 255, 200);
    float height = (h-1) * hist[bin] / maxCount;
    rect(x + bin*w/hist.length, y + h-height, w/hist.length, height + 1);
  }
}

// Add to target's histogram;
void addToTargetHist(Agent a) {
  PVector t = a.target;
  for (int i=0; i<targets.size(); i++) {
    if (targets.get(i)==t) {
      addToAgentHistogram(targetHist.get(i), a);
      return;
    }
  }
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
  boolean isTrapped = false;
  
  public Agent(int id, float speed, float size, PVector p, PVector target) {
    this.id = id;
    this.hue = id2hue(id);
    this.p = p;
    //target = new PVector(width*2/3, height/2 + random(-height/4, height/4));
    this.target = target;
    v = new PVector(random(-10, 10), random(-10, 10));
    v.normalize();
    this.speed = speed;
    this.size = size;
  }
  
  void move() {
    if (!isTrapped) {
      aimAtTarget();
      avoidAgentCollision();
      step();
    }
    if (dist(p.x, p.y, target.x, target.y)<size) {
      arrived = true;
    }
  }
  
  protected void aimAtTarget() {
    PVector aim = PVector.sub(target, p); // direction we should move in
//    aim.normalize();
    PVector adjust = PVector.sub(aim, v); // actual direction -> correction course
    adjust.normalize();
    adjust.mult(aimAdjust); // degree of adjustment
    v.add(adjust);
  }
  
  protected void avoidAgentCollision() {
    for (Agent other : agents) {
       if (other!=this) {
         if (dist(p.x, p.y, other.p.x, other.p.y) < (this.size + other.size)) {
           PVector repel = PVector.sub(p, other.p);
           repel.normalize();
           repel.mult(collisionAdjust);
           v.add(repel);
         }
       }
    }
  }
  
  protected void step() {
    v.normalize();
    v.mult(speed);
    p.add(adjustForWallCollision(p, v, 1));
  }
  
  // Test if agent can move from p to p+v without colliding with a wall.
  // Will adjust v in case of collision. 
  // Returns new v.
  // This is primitive:
  // - assumes walls are always thicker than v's magnitude.
  // - can't determine collision angle
  // TODO: switch to a raycasting approach instead.
  protected PVector adjustForWallCollision(PVector p, PVector direction, float repel) {
    if (!isWall(PVector.add(p, direction))) {
        return direction; // Not a wall.
    }
    
    // Wall. Try a few random directions.
    for (int i=0; i<5; i++) {
      PVector v = new PVector(direction.x, direction.y);
//      v.mult(-1); // back off
      v.add(new PVector(random(-speed, speed), random(-speed, speed))); // random angle adjustment
      v.normalize();
      v.mult(speed * repel);
      if (!isWall(PVector.add(p, v))) {
        return v;
      }
    }
    
    isTrapped = true;
    // Give up: stay where you are.
    return new PVector(0, 0);
  }
  
  protected boolean isWall(PVector p) {
    PVector t = PVector.add(p, v);
    color c = get(round(t.x), round(t.y));
    return (red(c)+green(c)+blue(c) == 0);
  }
  
  void draw() {
    noStroke();
    fill(hue, 255, 255, 200);
    ellipse(p.x, p.y, size, size);

    if (isTrapped) {
      fill(0);
      ellipse(p.x, p.y, 3, 3);
    } else {
      stroke(hue, 255, 255, 100);
      line(p.x, p.y, p.x + v.x*(minSize*3 + speed*2), p.y + v.y*(minSize*3 + speed*2));
    }
  }
}
