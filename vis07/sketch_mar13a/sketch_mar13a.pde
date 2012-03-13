
// Maze generator
// Martin Dittus, March 2012

// Maze dimensions, in cells.
int w = 40;
int h = 40;

// Likelihood that adjacent cells are separated by a wall.
// This is used for the initial maze seed.
float wallP = 0.3;

// Wall width, relative to cell size. Sensible values: [0.1 .. 0.9]
float minWallSize = 0.1;
float maxWallSize = 1.2;

Node[][] maze = new Node[w+1][h+1];
float[][] wallSize = new float[w+1][h+1];

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

void setup() {
  size(500, 500);
  buildMaze();
}

void draw() {
  noStroke();
  fill(255);
  rect(0, 0, width, height);
  
  float cw = width * 0.8 / w;
  float ch = height * 0.8 / h;
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
            a.x * cw + width * 0.1 - ww / 2, 
            a.y * ch + height * 0.1 - wh / 2, 
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
//  removeIsolatedCells();

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

//void removeIsolatedCells() {
//  for (int i=0; i<w+1; i++) {
//    for (int j=0; j<h+1; j++) {
//      Node a = maze[i][j];
//      if (a.walls.size()==4) {
//        List<Node> walls = new ArrayList<Node>(a.walls);
//        for (Node b : walls) {
//          removeWall(a, b);
//          println("removing wall");
//        }
//      }
//    }
//  }
//}

void keyPressed() {
  switch(key) {
    case ' ': 
      buildMaze();
      break;
  }
}

void mouseMoved() {
  int x = floor((mouseX - width*0.1) / (width * 0.8) * w);
  int y = floor((mouseY - height*0.1) / (height * 0.8) * h);
  
  try {
    Node a = maze[x][y];
    println(x + "/" + y + ": " + a.walls.size());
    println(a);
    for (Node b : a.walls) {
      println(b);
    }
  } catch (ArrayIndexOutOfBoundsException e) { } // lazy
}
