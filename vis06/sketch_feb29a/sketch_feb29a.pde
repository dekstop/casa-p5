// Multiple cellular automata nested into processes of reorganisation:
// - move some random tiles
// - fill all tiles with dominant colour
// - reorder all tiles in circular shape, based on tile fill state
// - reorder all rows, based on row fill state
//
// On each iteration: progress CA. After n iterations: reorganise.
//
// Martin Dittus, Feb 2012

int d = 100; // CA size
int n = 3;  // reorganise after n iterations

List<CA> cas = new ArrayList<CA>();

void setup() {
  size(800, 600);
  frameRate(10);
  colorMode(HSB);

//  cas.add(new CA(d, n));

  cas.add(new RandCA(d, n, 4, 10));
  cas.add(new RandCA(d, n, 4, 40));
  cas.add(new RandCA(d, n, 4, 60));

  cas.add(new FillCA(d, n, 2));
  cas.add(new FillCA(d, n, 4));
  cas.add(new FillCA(d, n, 5));

  cas.add(new CircularCA(d, n, 2));
  cas.add(new CircularCA(d, n, 4));
  cas.add(new CircularCA(d, n, 5));

  cas.add(new RowCA(d, n, 1));
  cas.add(new RowCA(d, n, 2));
  cas.add(new RowCA(d, n, 4));
  
  reset();
}

void reset() {
  float fillRate = 0.1 + random(0.5);
  for (CA ca : cas) {
    ca.reset(fillRate);
  }
}

void update() {
  for (CA ca : cas) {
    ca.advance();
  }
}

void draw() {
  update();
  noStroke();

  int x = 0;
  int y = 0;
  int cellSize = 2;
  for (CA ca : cas) {
    drawCA(ca, x, y, cellSize);
    y += cellSize * d;
    if (y >= height) {
      y = 0;
      x += cellSize * d;
    }
  }
}

void drawCA(CA ca, int x, int y, int cellSize) {
  for (int i=0; i<ca.cells.length; i++) {
    for (int j=0; j<ca.cells[i].length; j++) {
      fill(0, 0, ca.cells[i][j].present * 255);
      rect(x + i * cellSize, y + j * cellSize, cellSize, cellSize);
    }
  }
}

void keyPressed() {
  switch (key) {
    case ' ': reset(); break;
  }
}

class Cell {
  float present, future;
  
  Cell() {
    present = 0;
    future = 0;
  }
}

/**
 * General CA.
 */
class CA {
  public Cell[][] cells;
  public int n;
  public int stepCounter = 0;
  
  public CA(int d, int n) {
    cells = new Cell[d][d];
    this.n = n;
  }
  
  // fillRate [0..1] of 'present' values.
  public void reset(float fillRate) {
    seed(fillRate);
    stepCounter = 0;
  }
  
  protected void seed(float fillRate) {
    for (int i=0; i<cells.length; i++) {
      for (int j=0; j<cells[i].length; j++) {
        cells[i][j] = new Cell();
        if (random(1) <= fillRate) {
          cells[i][j].present = 1;
        } else {
          cells[i][j].present = 0;
        }
      }
    }
  }
  
  // Computes new state of 'future' values.
  public void advance() {
    advanceCA();
    apply();
    if ((++stepCounter) % n == 0) {
      reorganise();
    }
  }
  
  protected void advanceCA() {
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
  
  protected void apply() {
    for (int i=1; i<cells.length-1; i++) {
      for (int j=1; j<cells[i].length-1; j++) {
        cells[i][j].present = cells[i][j].future;
      }
    }
  }

  protected void reorganise() {
    // nop
  }
}

/**
 * Implements tile splitting.
 */
abstract class TiledCA extends CA {
  
  int xs, ys;
  int numX, numY;

  public TiledCA(int d, int n, int xs, int ys) {
    super(d, n);
    this.xs = xs;
    this.numX = d / xs;
    this.ys = ys;
    this.numY = d / ys;
  }
  
  protected void reorganise() {
    List<Cell[][]> tiles = getTiles(xs, ys);
    applyTiles(reorganiseTiles(tiles));
  }

  // To be implemented by subclasses. 
  abstract protected List<Cell[][]> reorganiseTiles(List<Cell[][]> tiles);

  // xs: tile width
  // ys: tile height
  protected List<Cell[][]> getTiles(int xs, int ys) {
    List<Cell[][]> tiles = new ArrayList<Cell[][]>();
    for (int y=0; y<d/ys; y++) {
      for (int x=0; x<d/xs; x++) {
        tiles.add(getTile(
          x*xs, y*ys, 
          xs, ys
          ));
      }
    }
    return tiles;
  }

  protected Cell[][] getTile(int x, int y, int w, int h) {
    Cell[][] tile = new Cell[w][h];
    for (int i=0; i<w; i++) {
      for (int j=0; j<h; j++) {
        tile[i][j] = cells[x+i][y+j];
      }
    }
    return tile;
  }

  protected void applyTiles(List<Cell[][]> tiles) {
    tiles = new ArrayList<Cell[][]>(tiles); // clone
    for (int y=0; y<numY; y++) {
      for (int x=0; x<numX; x++) {
        applyTile(
          tiles.remove(0),
          x * xs, y * ys
          );
      }
    }
  }

  protected void applyTile(Cell[][] tile, int x, int y) {
    for (int i=0; i<tile.length; i++) {
      for (int j=0; j<tile[i].length; j++) {
        cells[x+i][y+j] = tile[i][j];
      }
    }
  }

  // Calculate sum of cells.
  protected int sum(Cell[][] tile) {
    int n = 0;
    for (int i=0; i<tile.length; i++) {
      for (int j=0; j<tile[i].length; j++) {
        n += tile[i][j].present;
      }
    }
    return n;
  }
}

/**
 * Random tile movement, using square tiles.
 */
class RandCA extends TiledCA {
  
  int numMovements;

  public RandCA(int d, int n, int tileSize, int numMovements) {
    super(d, n, tileSize, tileSize);
    this.numMovements = numMovements;
  }

  protected List<Cell[][]> reorganiseTiles(List<Cell[][]> tiles) {
    // Move a few blocks to random new positions
    for (int n=0; n<numMovements; n++) {
      tiles.add(
        (int)random(tiles.size()),
        tiles.remove((int)random(tiles.size())));
    }
    return tiles;
  }
  
}

/**
 * Fill tile with dominant colour, using square tiles.
 */
class FillCA extends TiledCA {
  
  public FillCA(int d, int n, int tileSize) {
    super(d, n, tileSize, tileSize);
  }

  protected List<Cell[][]> reorganiseTiles(List<Cell[][]> tiles) {
    int numCells = xs * ys;
    for (Cell[][] tile : tiles) {
      int sum = sum(tile);
      if (sum > numCells / 2) { // > 50% of cells are filled
        fill(tile, 1);
      } else {
        fill(tile, 0);
      }
    }
    return tiles;
  }
  
  protected void fill(Cell[][] tile, float value) {
    for (int i=0; i<tile.length; i++) {
      for (int j=0; j<tile[i].length; j++) {
        tile[i][j].present = value;
      }
    }
  }
  
}

/**
 * Circular tile reorganisation, using square tiles.
 */
class CircularCA extends TiledCA {

  public CircularCA(int d, int n, int tileSize) {
    super(d, n, tileSize, tileSize);
  }

  protected List<Cell[][]> reorganiseTiles(List<Cell[][]> tiles) {
    // Sort by fill state
    Collections.sort(tiles, new Comparator<Cell[][]>(){
      public int compare(Cell[][] o1, Cell[][] o2) {
        return sum(o2) - sum(o1);
      }
    });
    return tiles;
  }
  
  // Reconstruct in circular order
  protected void applyTiles(List<Cell[][]> tiles) {
    float maxDist = sqrt(numX/2 * numX/2 + numY/2 * numY/2);
    for (int y=0; y<numY; y++) {
      for (int x=0; x<numX; x++) {
        float dist = sqrt((y-numY/2)*(y-numY/2) + (x-numX/2)*(x-numX/2));
        float nDist = dist / maxDist; // [0..1]
        // Now pick from list based on distance from centre:
        applyTile(
          tiles.remove(round(nDist * (tiles.size()-1))),
          x*xs, y*ys
          );
      }
    }
  }
  
}

/**
 * Row reorganisation, using one tile per cell row.
 */
class RowCA extends TiledCA {

  public RowCA(int d, int n, int height) {
    super(d, n, d, height);
  }

  protected List<Cell[][]> reorganiseTiles(List<Cell[][]> tiles) {
    // Sort by fill state
    Collections.sort(tiles, new Comparator<Cell[][]>(){
      public int compare(Cell[][] o1, Cell[][] o2) {
        return sum(o2) - sum(o1);
      }
    });
    return tiles;
  }
}
