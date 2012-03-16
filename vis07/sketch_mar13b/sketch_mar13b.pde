
// Swarm with spawning, seeking, starving, eating agent carcasses, with a maze generator
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

// TODO: size histogram for agents that reached target.
// TODO: starving agents should seek carcasses.
// TODO: for wall collisions: switch to a raycasting approach instead...
// TODO: calculate min wall thickness as max speed * x to avoid wall collision detection failures.

/*
 * Constants.
 */

// Agents.
int numAgents = 400;
int agentLifetime = 3000; // max iterations (frames) per agent

// Larger agents will be faster.
float minSize = 5;
float maxSize = 10;
float minSpeed = 0.5;
float maxSpeed = 2;

// How quickly can they turn?
float aimAdjust = 0.2;

// Max proximity for agent collision checks, in relation to size of both agents.
float collisionCheckProximity = 2.5;

// How quick are they when avoiding collisions with larger agents?
float collisionAdjust = 0.4;

// How many attempts per iteration at navigating around walls until giving up?
int numWallBounceAttempts = 15;

// Rate at which bounce speed increases per attempt per iteration.
// Max bounce speed = agent speed * numWallBounceAttempts ^ wallBouncePaceIncrease
float wallBouncePaceIncrease = 1.1;

// How much of an agent's speed and size is transferred when getting eaten?
float agentNutritionRate = 0.1;

// ...
float targetSize = 20;

// Stats.
int numHistogramBins = 25;

/*
 * Mazes. These are all generated. 
 * See MazeModel class below for description of parameters.  
 */

static List<MazeModel> mazeModels = new ArrayList<MazeModel>();

static {
  mazeModels.add(new MazeModel(
    11, // w
    15, // h
    0.2, // wallP
    0.2, // min wall size
    1.2 // max wall size
  ));
  mazeModels.add(new MazeModel(
    11, // w
    15, // h
    0.4, // wallP
    0.2, // min wall size
    0.5 // max wall size
  ));
  mazeModels.add(new MazeModel(
    8, // w
    11, // h
    0.9, // wallP
    0.5, // min wall size
    0.5 // max wall size
  ));
  mazeModels.add(new MazeModel(
    6, // w
    7, // h
    0.3, // wallP
    0.8, // min wall size
    0.8 // max wall size
  ));
  mazeModels.add(new MazeModel(
    60, // w
    70, // h
    0.02, // wallP
    2, // min wall size
    4 // max wall size
  ));
  mazeModels.add(new MazeModel(
    15, // w
    18, // h
    0.3, // wallP
    0.4, // min wall size
    0.8 // max wall size
  ));
}


/*
 * Variables.
 */

Maze maze;
PVector mazePos;
PVector mazeSize;

PVector spawnPoint;
List<PVector> targets = new ArrayList<PVector>();

int agentId = 0; // running counter
List<Agent> agents = new ArrayList<Agent>();

// Stats
List<int[]> targetHist = new ArrayList<int[]>();
int[] deadAgentHist;
int deadAgentCount;
int eatenAgentCount;
int targetAgentCount;

/*
 * Main app.
 */

void setup() {
  colorMode(HSB);
  size(800, 600);

  buildScene();
}

void buildScene() {
  // Model
  maze = new Maze(mazeModels.get(floor(random(mazeModels.size()))));
  mazePos = new PVector(width * 0.2, height * 0.225);
  mazeSize = new PVector(width * 0.5, height * 0.7);

  spawnPoint = new PVector(width * 0.1, height * 0.8);
  
  targets.clear();
  targets.add(new PVector( // top
    random(width * 0.3, width * 0.7), 
    random(height * 0.1, height * 0.15)));
  targets.add(new PVector( // top right
    random(width * 0.8, width * 0.85), 
    random(height * 0.1, height * 0.4)));
  targets.add(new PVector( // bottom right
    random(width * 0.8, width * 0.85), 
    random(height * 0.5, height * 0.8)));
  
  agents.clear();
  agentId = 0;
  
  // Stats
  targetHist.clear();
  targetHist.add(new int[numHistogramBins]);
  targetHist.add(new int[numHistogramBins]);
  targetHist.add(new int[numHistogramBins]);
  deadAgentHist = new int[numHistogramBins];
  deadAgentCount = 0;
  eatenAgentCount = 0;
  targetAgentCount = 0;
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
    ellipse(target.x, target.y, targetSize, targetSize); // target
  }

  strokeWeight(1);
  
  // Agents
  for (Agent a : agents) {
    a.move();
  }
  for (Agent a : agents) {
    a.draw(); // Only draw after all have moved.
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
    12,
    12, 
    mainHistW, 16);
  fill(0, 0, 255, 200);
  textAlign(LEFT);
  text((agents.size()-(deadAgentCount - eatenAgentCount)) + " live agents", 10 + mainHistW + 5, 25);

  textAlign(CENTER);
  text(targetAgentCount + " agents reached target", width/2, 25);

  drawHistogram(
    deadAgentHist,
    width - 12 - mainHistW,
    12, 
    mainHistW, 16);
  fill(0, 0, 255, 200);
  textAlign(RIGHT);
  text(deadAgentCount + " agents died", width - 12 - mainHistW - 10, 25);

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

  // Remove agents that reached their target, or have been eaten.  
  for (int i=0; i<agents.size(); i++) {
    if (agents.get(i).arrived) {
      Agent a = agents.remove(i);
      addToTargetHist(a);
    } else if (agents.get(i).hasBeenEaten) {
      agents.remove(i);
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
    if (!a.isDead) { // only add live ones
      addToAgentHistogram(hist, a);
    }
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
 * Maze model, describes a type of maze that is then rendered by the Maze class.
 */
static class MazeModel {
  
  int w; // Grid width, in cells.
  int h; // Grid height, in cells.

  // Likelihood that adjacent cells are separated by a wall.
  // This is used for the initial maze seed; further walls will be removed 
  // when building the maze.
  float wallP; 
  
  // Wall strength, relative to cell size. Sensible values: [0.1 .. 0.9]
  float minWallStrength;
  float maxWallStrength;
  
  public MazeModel(int w, int h, float wallP, float minWallStrength, float maxWallStrength) {
    this.w = w;
    this.h = h;
    this.wallP = wallP;
    this.minWallStrength = minWallStrength;
    this.maxWallStrength = maxWallStrength;
  }
}

/**
 * Maze class, builds and draws mazes (a grid of interconnected cells.)
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
  
  MazeModel model;
  
  Node[][] maze;
  float[][] wallSize;
  
  public Maze(MazeModel model) {
    this.model = model;
    
    this.maze = new Node[model.w+1][model.h+1];
    this.wallSize = new float[model.w+1][model.h+1];
    
    buildMaze();
  }
  
  void draw(float x, float y, float width, float height) {    
    float cw = (float)width / model.w;
    float ch = (float)height / model.h;
    noStroke();
    fill(0);
    for (int i=0; i<model.w+1; i++) {
      for (int j=0; j<model.h+1; j++) {
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
    for (int i=0; i<model.w+1; i++) {
      for (int j=0; j<model.h+1; j++) {
        wallSize[i][j] = random(model.minWallStrength, model.maxWallStrength);
      }
    }
  }
  
  // Builds an initial maze graph where all cells still have four walls.
  void buildGraph() {
    for (int i=0; i<model.w+1; i++) {
      for (int j=0; j<model.h+1; j++) {
        maze[i][j] = new Node(i, j);
      }
    }
    for (int i=0; i<model.w+1; i++) {
      for (int j=0; j<model.h+1; j++) {
        if (i>0 && random(1) < model.wallP) addWall(maze[i][j], maze[i-1][j]);
        if (j>0 && random(1) < model.wallP) addWall(maze[i][j], maze[i][j-1]);
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
  int lifetime;
  int hue;
  PVector p;
  PVector v;
  PVector target;
  float speed;
  float size;
  boolean arrived = false;
  boolean isDead = false;
  boolean hasBeenEaten = false;
  
  public Agent(int id, float speed, float size, PVector p, PVector target) {
    this.id = id;
    this.lifetime = agentLifetime;
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
    if (isDead) return;
    if (--lifetime == 0) {
      markDead();
      return;
    }
    aimAtTarget();
    avoidAgentCollision();
    step();
    if (dist(p.x, p.y, target.x, target.y)<size) {
      arrived = true;
      targetAgentCount++;
    }
  }
  
  protected void markDead() {
    isDead = true; 
    addToAgentHistogram(deadAgentHist, this);
    deadAgentCount++;
  }
  
  protected void eat(Agent other) {
    println(id + " eats " + other.id + ". Munch.");
    size += other.size * agentNutritionRate;
    speed += other.speed * agentNutritionRate;
    lifetime = agentLifetime;
    other.hasBeenEaten = true;
    eatenAgentCount++;
  }
  
  protected void aimAtTarget() {
    PVector aim = PVector.sub(target, p); // direction we should move in
    PVector adjust = PVector.sub(aim, v); // actual direction -> correction course
    adjust.normalize();
    adjust.mult(aimAdjust); // degree of adjustment
    v.add(adjust);
  }
  
  protected void avoidAgentCollision() {
    for (Agent other : agents) {
       if (other!=this) {
         float d = dist(p.x, p.y, other.p.x, other.p.y);
         if (d < (this.size + other.size) * collisionCheckProximity) { // approaching?
           if (other.isDead && !other.hasBeenEaten && d <= this.size) { // touching, eatable and smaller?
             // AH MUNNA EAT CHOO
             eat(other);
           } else if (this.size <= other.size) { // alive and larger?
             // Avoid.
             PVector repel = PVector.sub(p, other.p);
             repel.normalize();
             repel.mult(speed * collisionAdjust);
             v.add(repel);
           }
         }
       }
    }
  }
  
  protected void step() {
    v.normalize();
    v.mult(speed);
    v = adjustForWallCollision(p, v, 1);
    p.add(v);
  }
  
  // Test if agent can move from p to p+v without colliding with a wall.
  // Will adjust v in case of collision. 
  // Returns new v.
  // This is primitive:
  // - assumes walls are always thicker than v's magnitude.
  // - can't determine collision angle
  protected PVector adjustForWallCollision(PVector p, PVector direction, float repel) {
    if (!isWall(PVector.add(p, direction))) {
        return direction; // Not a wall.
    }
    
    // Wall. Try a few random directions.
    float vAdjust = speed;
    for (int i=0; i<numWallBounceAttempts; i++) {
      PVector v = new PVector(-direction.x, -direction.y); // back off
      v.add(new PVector( // random angle adjustment
        random(-vAdjust, vAdjust), 
        random(-vAdjust, vAdjust))); 
      if (!isWall(PVector.add(p, v))) {
        return v;
      }
      vAdjust *= wallBouncePaceIncrease; // try harder next time...
    }
    
    // Give up: stay where you are, but set a new random target.
    target = targets.get(floor(random(targets.size())));
    println(id + " is trapped. Setting new target.");
    return new PVector(0, 0);
  }
  
  protected boolean isWall(PVector p) {
    if (p.x<0 || p.x>=width-1 || p.y<0 || p.y>=height-1) {
      return false; // off-screen? -> no wall.
    }
    PVector t = PVector.add(p, v);
    color c = get(round(t.x), round(t.y));
    return (red(c)+green(c)+blue(c) == 0); // black pixel? -> wall.
  }
  
  void draw() {
    noStroke();
    float sat = 255.0 * (1 - pow(1 - (float)lifetime / agentLifetime, 10));
    fill(hue, sat, 255, 200);
    ellipse(p.x, p.y, size, size);
    
    if (!isDead) {
      stroke(hue, sat, 255, 100);
      PVector beak = new PVector(v.x, v.y);
      beak.normalize();
      beak.mult(minSize); // vector in direction v, but with size minSize
      beak.add(v);
      beak.mult(2);
      line(p.x, p.y, p.x + beak.x, p.y + beak.y);
    }
  }
}
