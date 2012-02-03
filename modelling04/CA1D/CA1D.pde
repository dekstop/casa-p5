// 1D Cellular Automaton.
// Martin Dittus, Feb 2012.
//
// General process:
// * CA state is a 1D vector of cells
// * During each iteration, every cell receives a new value based on the current CA state
// * This process continues until the new CA state is a repetition of an old state
//
// Process to fill a cell:
// * Extract one bit of each parent cell at positions (idx-1, idx, idx+1)
// * Pack into 3-bit variable, resulting of values: [0..7]
// * Based on this value, apply one of 8 rules
//
// Rules determine how the new cell state is computed. General structure:
// * old value = value of cell at current index
// * offset = old value * fixed coefficient
// * source index = current cell index + offset
// * new cell value = value of cell at source index
//
// During setup:
// * Seed cells with random value
// * Randomise indices of bit to extract from each parent cell
// * Randomise coefficients {-1, 1} to apply for all 8 rules
//
// You do get spaceships, but not very often.

import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;

import processing.video.*;

int numCells = 71;
int maxVal = 100;
int maxParentBit = 7; // TODO: calculate from maxVal

int[] cells = new int[numCells];
int[] nextCells = new int[numCells];

int historySize = numCells * numCells;
LinkedList<int[]> history = new LinkedList<int[]>();

int cellSize;
int numRows;
int rowIdx = 0;
int numGenerations;
int[] parentBits = new int[3];
int[] ruleCoefficients = new int[8];
Map<Integer, Integer> ruleStats = new HashMap<Integer, Integer>();

MovieMaker mm;

void setup() {
  size(800, 600);
//  frameRate(10);
  colorMode(HSB);
  background(0);
  
  cellSize = (width-30) / numCells;
  numRows = (height - 30) / cellSize;
  
  seed();
  makeRules();
}

void draw() {
//  int idx = numGenerations % numRows; // vertical drawing position

  // Draw
  stroke(0);
  for (int i=0; i<numCells; i++) {
    fill(
      (float)get(i) / maxVal * 255/4.0,
     250, 
      200);
    rect(
      15 + i * cellSize,
      15 + rowIdx * cellSize, 
      cellSize,
      cellSize);
  }
  
  // Move
  for (int i=0; i<numCells; i++) {
    int value = 
      getBit(get(i-1), parentBits[0]) << 2 |
      getBit(get(i), parentBits[1]) << 1 |
      getBit(get(i+1), parentBits[2]);
    
    int coeff = ruleCoefficients[value];
    switch(value) {
      // "The Rules"
      case 0: set(i, get(i+coeff*get(i))); break;
      case 1: set(i, get(i+coeff*get(i))); break;
      case 2: set(i, get(i+coeff*get(i))); break;
      case 3: set(i, get(i+coeff*get(i))); break;
      case 4: set(i, get(i+coeff*get(i))); break;
      case 5: set(i, get(i+coeff*get(i))); break;
      case 6: set(i, get(i+coeff*get(i))); break;
      case 7: set(i, get(i+coeff*get(i))); break;
    }

    // Stats
    if (!ruleStats.containsKey(value)) ruleStats.put(value, 0);
    ruleStats.put(value, ruleStats.get(value) + 1);
  }
  
  // Prepare next generation
  cells = nextCells;
  nextCells = new int[numCells];

  if (inHistory(cells)) {
    println("Cycle detected after " + numGenerations + " generations.");
    println("Rule frequency table: " + ruleStats);
    println();
    restart();
  }
  else {
    addToHistory(cells);  
    numGenerations++;
  }
  
  if (++rowIdx > numRows) {
    rowIdx = 0;
  }
  
  // Record
  if (mm!=null) {
    mm.addFrame();
//    text("Recording...", 15, 130);
  }
}

void restart() {
    seed();
    makeRules();
    numGenerations = 0;
//    background(0);
    fill(0, 0, 0, 100);
    rect(0, 0, width, height);
    history.clear();
    ruleStats.clear();
}

void addToHistory(int[] cells) {
  history.add(cells);
  if (history.size() > historySize) {
    history.remove(); // remove first (oldest)
  }
}

boolean inHistory(int[] cells) {
  for (int[] h : history) {
    if (Arrays.equals(h, cells)) {
      return true;
    }
  }
  return false;
}

void seed() {
  for (int i=0; i<numCells; i++) {
    cells[i] = floor(random(maxVal + 1));
  }
}

void makeRules() {
  print("Parent bits: ");
  for (int i=0; i<parentBits.length; i++) {
    parentBits[i] = floor(random(maxParentBit + 1));
    print(parentBits[i] + " ");
  }
  println();
  print("Rule coefficients: ");
  for (int i=0; i<ruleCoefficients.length; i++) {
    ruleCoefficients[i] = random(1) >= 0.5 ? 1 : -1;
    print(ruleCoefficients[i] + " ");
  }
  println();
}

int getBit(int val, int bitIdx) {
  return (val & (1 << bitIdx)) >> bitIdx;
}

int get(int idx) {
  while(idx<0) idx += numCells;
  return cells[idx % numCells];
}

void set(int idx, int value) {
  while(idx<0) idx += numCells;
  nextCells[idx % numCells] = value;
}

void keyPressed() {
  if (key == ' ') {
    restart();
  } else if (key=='r') {
    if (mm==null) {
      startRecording();
    } else {
      stopRecording();
    }
  }
}

void stop() {
  stopRecording();
}

void startRecording() {
  println("Starting recording...");
  mm = new MovieMaker(this, width, height, 
    "recording-" + System.currentTimeMillis() + ".mov",
    30, MovieMaker.MOTION_JPEG_B, MovieMaker.BEST);
}

void stopRecording() {
  println("Stopping recording.");
  if (mm!=null) {
    mm.finish();
    mm = null;
  }
}
