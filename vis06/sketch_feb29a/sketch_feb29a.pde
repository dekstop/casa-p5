// Cellular automaton nested into a tile sorting process.
// On each iteration: progress CA, then sort tiles.
// Martin Dittus, Feb 2012

Cell[][] cells;
int side = 200;
int tileSize = 10; // needs to be an even divisor of 'side'
int numTiles = side / tileSize;
int cellSize;

int stepCounter = 0;

void setup() {
  size(600, 600);
  frameRate(10);
  colorMode(HSB);
  
  cells = new Cell[side][side];
  cellSize = width / side;
  seedCells();
}

void update() {
  advanceCA();
  applyFutureCells();
  if ((++stepCounter) % 15 == 0) {
    reorganiseTiles();
  }
}

void draw() {
  update();
  noStroke();
  for (int i=0; i<cells.length; i++) {
    for (int j=0; j<cells[i].length; j++) {
      fill(0, 0, cells[i][j].present * 255);
      rect(i * cellSize, j * cellSize, cellSize, cellSize);
    }
  }
}

void seedCells() {
  float thresh = 0.1 + random(0.1);
  println("Fill rate: " + thresh);
  for (int i=0; i<cells.length; i++) {
    for (int j=0; j<cells[i].length; j++) {
      cells[i][j] = new Cell();
      if (random(1) <= thresh) {
        cells[i][j].present = 1;
      } else {
        cells[i][j].present = 0;
      }
    }
  }
  stepCounter = 0;
}

void advanceCA() {
  for (int i=1; i<cells.length-1; i++) {
    for (int j=1; j<cells[i].length-1; j++) {
      float localSum = 
        cells[i-1][j].present +
        cells[i][j-1].present +
        cells[i+1][j].present +
        cells[i][j+1].present;
        
      if (localSum <= 0) {
        cells[i][j].future = 0;
      } else if (localSum > 0 && localSum < 2) {
        cells[i][j].future = 0;
      } else if (localSum >= 2 && localSum < 3) {
        cells[i][j].future = 1;
      } else if (localSum >= 3 && localSum < 4) {
        cells[i][j].future = cells[i][j].present;
      } else if (localSum>=4) {
        cells[i][j].future = 1;
      }
    }
  }
}

void applyFutureCells() {
  for (int i=1; i<cells.length-1; i++) {
    for (int j=1; j<cells[i].length-1; j++) {
      cells[i][j].present = cells[i][j].future;
    }
  }
}

void reorganiseTiles() {
  // Split
  List<Cell[][]> blocks = new ArrayList<Cell[][]>();
  for (int y=0; y<numTiles; y++) {
    for (int x=0; x<numTiles; x++) {
      blocks.add(getCellBlock(
        x*tileSize, y*tileSize, 
        tileSize, tileSize
        ));
    }
  }
  
  // Move a few blocks to random new positions
//  for (int n=0; n<10; n++) {
//    blocks.add(
//      (int)random(blocks.size()),
//      blocks.remove((int)random(blocks.size())));
//  }

  // Sort by fill state
  Collections.sort(blocks, new Comparator<Cell[][]>(){
    public int compare(Cell[][] o1, Cell[][] o2) {
      return count(o2) - count(o1);
    }
  });
  
  // Reconstruct in linear order
//  int idx = 0;
//  for (int y=0; y<numTiles; y++) {
//    for (int x=0; x<numTiles; x++) {
//      applyCellBlock(
//        blocks.get(idx++),
//        x*tileSize, y*tileSize
//        );
//    }
//  }

  // Reconstruct in circular order
  float maxDist = sqrt(numTiles/2 * numTiles/2 + numTiles/2 * numTiles/2);
  for (int y=0; y<numTiles; y++) {
    for (int x=0; x<numTiles; x++) {
      float dist = sqrt((y-numTiles/2)*(y-numTiles/2) + (x-numTiles/2)*(x-numTiles/2));
      float nDist = dist / maxDist; // [0..1]
      // Now pick from list based on distance from centre:
      applyCellBlock(
        blocks.remove(round(nDist * (blocks.size()-1))),
        x*tileSize, y*tileSize
        );
    }
  }
}

int count(Cell[][] block) {
  int n = 0;
  for (int i=0; i<block.length; i++) {
    for (int j=0; j<block[i].length; j++) {
      n += block[i][j].present;
    }
  }
  return n;
}

Cell[][] getCellBlock(int x, int y, int w, int h) {
  Cell[][] block = new Cell[w][h];
  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      block[i][j] = cells[x+i][y+j];
    }
  }
  return block;
}

void applyCellBlock(Cell[][] block, int x, int y) {
  for (int i=0; i<block.length; i++) {
    for (int j=0; j<block[i].length; j++) {
      cells[x+i][y+j] = block[i][j];
    }
  }
}

// Copies a block of cells from 'present' to a new region of 'future'.
void setFutureCellBlock(int x, int y, int w, int h, int newX, int newY) {
  for (int i=0; i<w; i++) {
    for (int j=0; j<h; j++) {
      cells[newX+i][newY+j].future = cells[x+i][y+j].present;
    }
  }
}

void keyPressed() {
  switch (key) {
    case ' ': seedCells(); break;
  }
}

void mouseMoved() {
  int i = mouseX / cellSize;
  int j = mouseY / cellSize;
  
  try {
    cells[i][j].present = random(1);
    cells[i-1][j-1].present = random(1);
    cells[i-1][j+1].present = random(1);
    cells[i+1][j+1].present = random(1);
    cells[i+1][j-1].present = random(1);
  } catch (ArrayIndexOutOfBoundsException e) { }
}

class Cell {
  float present, future;
  
  Cell() {
    present = 0;
    future = 0;
  }
}
