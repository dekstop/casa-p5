
// Swarming agents that are spawned, seek a target, navigate through terrain 
// (with fairly primitive means), avoid potential predators, starve, die, eat 
// prey and carcasses. With a maze generator to make the terrain.
//
// Agents are coloured by generation (i.e., according to the time they were 
// spawned), but lose saturation when they starve. Their target is determined 
// at spawn time. They can survive (and grow) by eating smaller agents, or
// taking a bite off a carcass.
//
// Agents will avoid larger live agents, and carcasses when they're not hungry
// (the repelling force is a power law distribution relative to agent sizes), 
// but they won't notice walls until they hit them, and then bounce off or get 
// stuck.
//
// There is a limit to the total number of live (and dead) agents on screen.
// Once the limit has been reached, new agents can only be spawned when any
// agent reaches their target and is removed. (For this reason targets can 
// also be considered "breeding grounds", disregarding the fact that their 
// location is different from the central spawning point.)
//
// Press the "f" key to toggle "flypaper mode", which makes agents stick to 
// walls and die instantly. In this mode complex terrains are much harder to 
// vavigate. Since agents will avoid larger carcasses these now act as "beacons"
// for nearby walls, and allow new agents to travel farther. 
//
// A few histograms show live/dead/arrived agent counts per generation. This 
// allows to observe how quickly agents manage to find their target, a function 
// of the terrain. The target histograms are especially interesting in flypaper 
// mode, where it may take a few generations of dead "beacon" agents to mark a 
// path along walls until new agents can pass.
//
// Press the space bar to start again with a new terrain. The basis of these 
// generated terrain models is a maze generator, with a few additions. Wall 
// strengths can be randomised, and a post-processing step may remove random 
// walls between cells of the maze. Each terrain will be a variant of a number 
// of preconfigured types.

// With more complex terrains it is worth letting the model run for a few minutes 
// to observe emerging zones, e.g.:
// * The distribution of colour across the terrain which may indicate zones of
//   faster or slower propagation.
// * Groups of agents pushing other (smaller) agents in wrong directions until
//   they get a chance to escape. These "bullied" agents will wiggle their beak
//   as they continuously attempt to change direction.
// * Dense clusters between walls where agents start panicking as there is no 
//   space to evade potential predators.
// * Dead ends which result in starvation deaths, which provides food to grow.
//   This allows a few agents to escape once they have become large enough to
//   move in larger steps.
// * Also note the interaction between walls and carcass prey in flypaper mode: 
//   an agent may be tempted to eat a wall beacon carcass to survive, but this 
//   brings it in closer proximity with the wall, and makes it likely that it 
//   will itself get stuck and die. This could be regarded as a form of "weary 
//   desperation"...
// * The system may reach an equilibrium where many agents are stuck, but enugh
//   of them reach their targets that there is a steady trickle of renewal. 
//   Such equilibria may have any number of live and stuck (or dead) agents.
//
// A big limitation of this model is the absence of any "line of sight" logic.
// As a result agents will head in the direction of their target even with 
// walls between them. Additionally, in the case of a wall collision agents will 
// bounce off in random directions as opposed to maintaining their general 
// direction, or picking reasonable alternative routes.
//
// Martin Dittus, March 2012.

// TODO: starving agents should seek carcasses and prey, not just eat by happenstance.
// TODO: for wall collisions: switch to a ray casting approach instead.
// TODO: calculate min wall thickness as max speed * x to avoid wall collision detection failures.

/*
 * Constants.
 */

// Agents.
int numAgents = 400;
int agentLifetime = 3000; // lifetime in iterations (frames) per agent, can be extended by eating

// At which remaining lifetime level do agents start eating smaller agents?
float hungerThreshold = 0.2;

// How much of an agent's speed and size is transferred when getting eaten?
float agentNutritionRate = 0.1;

// How much lifetime do agents get for eating?
int eatingLifetime = agentLifetime / 3;

// Share of size that is chewed off dead agents.
// Agents of size minSize will be eaten whole.
float biteSize = 0.3;

// Larger agents will be faster.
float minSize = 5;
float maxSize = 10;
float minSpeed = 0.9;
float maxSpeed = 1.4;

// How quickly can they turn?
float aimAdjust = 0.2;

// Max proximity for agent collision checks, in relation to size of both agents.
float collisionCheckProximity = 1.1;

// How quick are they when avoiding collisions with larger agents?
// This is relative to normal agent speed.
float collisionAdjust = 1.4;

// How many attempts per iteration at navigating around walls until giving up?
int numWallBounceAttempts = 15;

// Rate at which bounce speed increases per attempt per iteration.
// Max bounce speed = agent speed * numWallBounceAttempts ^ wallBouncePaceIncrease
float wallBouncePaceIncrease = 1.1;

// Size of the agent targets.
float targetSize = 20;

// Stats.
int numHistogramBins = 25;

/*
 * Mazes (terrain models.) These are preconfigured types of terrain models.
 * See the MazeModel class below for a description of the parameters.  
 */

static List<MazeModel> mazeModels = new ArrayList<MazeModel>();

static {
  mazeModels.add(new MazeModel( // "city model"
    11, // w
    15, // h
    0.2, // wallP
    0.2, // min wall size
    1.2 // max wall size
  ));
  mazeModels.add(new MazeModel( // large "city model", may cover top target
    5, // w
    5, // h
    0.9, // wallP
    0.1, // min wall size
    1.9 // max wall size
  ));
  mazeModels.add(new MazeModel( // maze with randomized small/medium-sized walls
    11, // w
    15, // h
    0.4, // wallP
    0.2, // min wall size
    0.5 // max wall size
  ));
  mazeModels.add(new MazeModel( // maze with medium-sized walls
    9, // w
    11, // h
    0.9, // wallP
    0.5, // min wall size
    0.5 // max wall size
  ));
  mazeModels.add(new MazeModel( // maze with a few larger walls
    4, // w
    4, // h
    0.9, // wallP
    0.3, // min wall size
    0.3 // max wall size
  ));
  mazeModels.add(new MazeModel( // maze with huge walls and narrow paths
    6, // w
    7, // h
    0.3, // wallP
    0.8, // min wall size
    0.8 // max wall size
  ));
  mazeModels.add(new MazeModel( // canyons/hills (randomly distributed adjunct rectangles)
    60, // w
    70, // h
    0.02, // wallP
    2, // min wall size
    4 // max wall size
  ));
  mazeModels.add(new MazeModel( // rectangular maze pattern
    15, // w
    18, // h
    0.3, // wallP
    0.4, // min wall size
    0.8 // max wall size
  ));
  mazeModels.add(new MazeModel( // few massive blocks
    3, // w
    3, // h
    0.2, // wallP
    0.5, // min wall size
    0.9 // max wall size
  ));
  mazeModels.add(new MazeModel( // few medium-sized blocks
    11, // w
    15, // h
    0.01, // wallP
    0.5, // min wall size
    1.2 // max wall size
  ));
  mazeModels.add(new MazeModel( // few small blocks; occasionally blank
    22, // w
    30, // h
    0.002, // wallP
    0.5, // min wall size
    1.2 // max wall size
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

boolean flypaperMode = false; // stick to walls?

// Stats
List<int[]> targetHist = new ArrayList<int[]>();
List<Integer> targetCount = new ArrayList<Integer>();
int[] deadAgentHist;
int deadAgentCount;
int eatenAgentCount;

/*
 * Main app.
 */

void setup() {
  colorMode(HSB);
//  size(640, 480);
  size(800, 600);
//  size(1280, 800);

  buildScene();
  
  spawnAgent();
  Agent a = agents.get(0);
  println(a.isWall(new PVector(324.16608, 598.58887)));
}

void buildScene() {
  buildScene(mazeModels.get(floor(random(mazeModels.size()))));
}

void buildScene(MazeModel model) {
  // Model
  maze = new Maze(model);
  mazePos = new PVector(width * 0.2, height * 0.225);
  mazeSize = new PVector(width * 0.5, height * 0.65);

  spawnPoint = new PVector(width * 0.1, height * 0.8);
  
  targets.clear();
  targets.add(new PVector( // top
    random(width * 0.3, width * 0.7), 
    random(height * 0.1, height * 0.1)));
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
  targetCount.clear();
  targetCount.add(0);
  targetCount.add(0);
  targetCount.add(0);
  deadAgentHist = new int[numHistogramBins];
  deadAgentCount = 0;
  eatenAgentCount = 0;
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
  cleanupAgents();

  if (agents.size() < numAgents && random(1)<0.3) { // at a moderate pace
    spawnAgent();
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

//  textAlign(CENTER);
//  text(targetAgentCount + " agents reached target", width/2, 25);

  drawHistogram(
    deadAgentHist,
    width - 12 - mainHistW,
    12, 
    mainHistW, 16);
  fill(0, 0, 255, 200);
  textAlign(RIGHT);
  text(deadAgentCount + " agents died", width - 12 - mainHistW - 10, 25);

  drawTargetStats(targets.get(0), targetHistW, 16, targetCount.get(0), targetHist.get(0));
  drawTargetStats(targets.get(1), targetHistW, 16, targetCount.get(1), targetHist.get(1));
  drawTargetStats(targets.get(2), targetHistW, 16, targetCount.get(2), targetHist.get(2));
  
  fill(0, 0, 0, 100);
  noStroke();
  rect(10, height-30, width-20, 20);

  fill(0, 0, 255, 200);
  textAlign(LEFT);
  text("[space] restart with new terrain  [f] turn flypaper mode " +
    (flypaperMode ? "off" : "on"), 15, height-15);
  textAlign(RIGHT);
  text("covspc.wordpress.com", width-25, height-15);
}

// Remove agents that reached their target, or have been eaten. 
// Also increases some stats counters.
// ("Dead agent" stats are updated by agents.)
void cleanupAgents() {
  for (int i=0; i<agents.size(); i++) {
    if (agents.get(i).arrived) {
      Agent a = agents.remove(i);
      addToTargetStats(a);
    } else if (agents.get(i).hasBeenEaten) {
      agents.remove(i);
      eatenAgentCount++;
    }
  }
}

// Add to target's histogram and counter.
void addToTargetStats(Agent a) {
  PVector t = a.target;
  for (int i=0; i<targets.size(); i++) {
    if (targets.get(i)==t) {
      addToAgentHistogram(targetHist.get(i), a);
      targetCount.set(i, targetCount.get(i) + 1);
      return;
    }
  }
}

// Make one new agent
void spawnAgent() {
  float size = random(1);
  size *= size * size * size * size; // agent size: few large ones, many small ones
  PVector p = // spawn point
    new PVector(
      spawnPoint.x + random(-10, 10), 
      spawnPoint.y + random(-10, 10));
  PVector target = targets.get(floor(random(targets.size())));
  agents.add(makeAgent(size, p, target));
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

void drawTargetStats(PVector target, int width, int height, int counter, int[] hist) {
  drawHistogram(
    hist,
    target.x + 20, target.y - 8,
    width, height);
  if (counter > 0) {
    fill(0, 0, 255, 200);
    textAlign(LEFT);
    text(counter, target.x + 20, target.y + 8  + 15);
  }
}

void keyPressed() {
  switch(key) {
    case ' ': 
      buildScene();
      break;
    case 'f': 
      flypaperMode = !flypaperMode;
      break;
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      buildScene(mazeModels.get(Integer.parseInt("" + key)));
      break;
    case '0':
      buildScene(mazeModels.get(10));
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
        if (i==0 || i==model.w || j==0 || j==model.h) {
          // outer walls: always min strength (so we don't overdraw too much.)
          wallSize[i][j] = model.minWallStrength;
        } else {
          wallSize[i][j] = random(model.minWallStrength, model.maxWallStrength);
        }
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
    v = new PVector(random(-1, 1), random(-1, 1));
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
    handleAgentCollision();
    step();
    if (dist(p.x, p.y, target.x, target.y)<min(size, targetSize)) {
      arrived = true;
    }
  }
  
  protected void markDead() {
    isDead = true; 
    lifetime = 0;
    deadAgentCount++;
    addToAgentHistogram(deadAgentHist, this);
  }
  
  // Take a bite off a dead agent.
  // If it reaches minSize: mark it for removal.
  protected void eat(Agent other) {
    if (other.hasBeenEaten) {
      return; // Someone else got here first.
    }
    println(id + " takes a bite off " + other.id + ". Munch.");
    size += other.size * agentNutritionRate * biteSize;
    speed += other.speed * agentNutritionRate * biteSize;
    lifetime += eatingLifetime + other.lifetime * agentNutritionRate;
    
    if (other.size <= minSize) { // How big?
      // Small, and either dead or alive. 
      if (!other.isDead) {
        other.markDead();
      }
      other.hasBeenEaten = true; // Eat whole
      println(other.id + " has been eaten.");
    } else if (other.isDead) { 
      // Large carcass.
      other.size -= other.size * biteSize; // Just take a bite off.
      other.speed -= other.speed * biteSize;
    }
  }
  
  boolean isHungry() {
    return lifetime <= agentLifetime * hungerThreshold;
  }
  
  // proximity must be > 0 and should be <= 1, and proportional to distance.
  //   Smaller numbers will increase the repelling force.
  // forceSpread must be > 0 and should be <= 1
  //   Limits how far repelling forces will reach.
  //   Smaller numbers result in a smaller force radius.
  // collisionAdjust is the maximum pace, relative to agent speed.
  protected void runFrom(Agent other, float proximity, float forceSpread, float collisionAdjust) {
    PVector repel = PVector.sub(p, other.p);
    repel.normalize();
    float force = pow(2, -proximity / forceSpread);
    repel.mult(speed * collisionAdjust * force);
    v.add(repel);
  }
  
  protected void aimAtTarget() {
    PVector aim = PVector.sub(target, p); // direction we should move in
    PVector adjust = PVector.sub(aim, v); // actual direction -> correction course
    adjust.normalize();
    adjust.mult(aimAdjust); // degree of adjustment
    v.add(adjust);
    v.normalize();
  }
  
  protected void handleAgentCollision() {
    for (Agent other : agents) {
      if (other!=this) {
        float dist = dist(p.x, p.y, other.p.x, other.p.y);
        float maxAvoidanceDist = (this.size + other.size) * collisionCheckProximity; 
        if (dist < maxAvoidanceDist) { // Approaching?
          if (isHungry() && (other.isDead || other.size <= size)) { // Potential prey?
            if (dist <= size + other.size) { // Touching?
              // AH MUNNA EAT CHOO
              eat(other);
            } 
          } else { // Potential predator?
            float proximity = dist / maxAvoidanceDist;
            if (other.isDead) { 
              // Dead. Try not to hit.
              runFrom(other, proximity, 1, collisionAdjust * 0.5);
            } else if (other.size <= size) { 
              // Harmless. Half-hearted attempt at making way.
              runFrom(other, 1.5 - pow(1.5, - proximity), 1, collisionAdjust * 0.1);
            } else { 
              // Potential predator. RUUN.
              runFrom(other, proximity, 2, collisionAdjust);
            }
          }
        }
      }
    }
  }
  
  protected void step() {
//    v.normalize();
    v.mult(speed);
    v = avoidWalls(p, v, 1);
    p.add(v);
  }
  
  // Test if agent can move from p to p+v without colliding with a wall.
  // Will adjust v in case of collision. 
  // Returns new v.
  // This is primitive:
  // - assumes walls are always thicker than v's magnitude.
  // - can't determine collision angle
  protected PVector avoidWalls(PVector p, PVector direction, float repel) {
    if (!isWall(PVector.add(p, direction))) {
        return direction; // Not a wall.
    }
    
    // Approaching wall.
    if (flypaperMode) {
      // Stick.
      markDead();
      println(id + " is stuck on a wall.");
      // Find collision point.
      float vAdjust = speed;
      for (int i=0; i<numWallBounceAttempts; i++) {
        PVector v = new PVector(direction.x, direction.y); // back off
        v.normalize();
        v.mult(vAdjust);
        if (!isWall(PVector.add(p, v))) {
          return v;
        }
        vAdjust /= wallBouncePaceIncrease; // try smaller steps next time...
      }
      return new PVector(0, 0);
    } else {
      // Avoid. Try a few random directions.
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
  }
  
  protected boolean isWall(PVector p) {
    int x = round(p.x);
    int y = round(p.y);
    if (x<0 || x>width-1 || y<0 || y>height-1) {
      return false; // off-screen? -> no wall.
    }
    color c = get(x, y);
    return (red(c)+green(c)+blue(c) == 0); // black pixel? -> wall.
  }
  
  void draw() {
    noStroke();
    float sat = 255.0 * (1 - pow(1 - (float)lifetime / agentLifetime, 10));
    fill(hue, sat, 255, 200);
    ellipse(p.x, p.y, size, size);
    
    if (!isDead) {
      stroke(hue, sat, 255, 100);
      strokeWeight(3);
      PVector beak = new PVector(v.x, v.y);
      beak.normalize();
      beak.mult(size); // vector in direction v, but with size size
      beak.add(v);
//      beak.mult(1.5);
      line(p.x, p.y, p.x + beak.x, p.y + beak.y);
      strokeWeight(1);
    }
  }
}
