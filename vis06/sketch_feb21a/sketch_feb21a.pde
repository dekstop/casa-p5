
Cell[][] cells;
int side = 200;
int cellSize;

void setup() {
  size(800, 800);
  frameRate(10);
  colorMode(HSB);
  
  cells = new Cell[side][side];
  cellSize = width / side;
  reset();
}

void reset() {
  for (int i=0; i<cells.length; i++) {
    for (int j=0; j<cells[i].length; j++) {
      cells[i][j] = new Cell();
      if (random(1) < 0.7) {
        cells[i][j].present = 1;
      }
    }
  }
}

void update() {
  for (int i=1; i<cells.length-1; i++) {
    for (int j=1; j<cells[i].length-1; j++) {
      float localSum = 
        cells[i-1][j].present +
        cells[i][j-1].present +
        cells[i+1][j].present +
        cells[i][j+1].present;
        
      if (localSum < 2) {
        cells[i][j].future = 0;
      } else if (localSum >= 2 && localSum < 3) {
        cells[i][j].future = 1;
      } else if (localSum >= 3 && localSum < 4) {
        cells[i][j].future = cells[i][j].present;
      } else if (localSum>=4) {
        cells[i][j].future = 0;
      }
    }
  }
  for (int i=1; i<cells.length-1; i++) {
    for (int j=1; j<cells[i].length-1; j++) {
      cells[i][j].present = cells[i][j].future;
    }
  }
}

void draw() {
  update();
  noStroke();
  for (int i=0; i<cells.length; i++) {
    for (int j=0; j<cells[i].length; j++) {
      float h = 0;
      float s = 0;
      float b = 0;

      if (cells[i][j].present > 0) {
//        b = 0;
//        h = 0;
      } else {
        b = 255;
//        h = 255 / 4;
      }
      fill(h, s, b);
      rect(i * cellSize, j * cellSize, cellSize, cellSize);
    }
  }
}

void keyPressed() {
  switch (key) {
    case ' ': reset(); break;
  }
}

void mouseMoved() {
  int i = mouseX / cellSize;
  int j = mouseY / cellSize;
  cells[i][j].present = 1;
  cells[i-1][j-1].present = 1;
  cells[i-1][j+1].present = 1;
  cells[i+1][j+1].present = 1;
  cells[i+1][j-1].present = 1;
}

class Cell {
  float present, future;
  
  Cell() {
    present = 0;
    future = 0;
  }
}
