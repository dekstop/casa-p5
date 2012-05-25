// 1D Cellular Automaton that produces MIDI files.
// Martin Dittus, Feb 2012.
//

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

boolean recordMidi = false;
MidiFile mf;
final int MIDI_BASE_NOTE = 60;
final int[] MIDI_VOICES = new int[]{
  MIDI_BASE_NOTE,
  MIDI_BASE_NOTE + 1,
  MIDI_BASE_NOTE + 2,
  MIDI_BASE_NOTE + 3,
  MIDI_BASE_NOTE + 4,
  MIDI_BASE_NOTE + 5,
  MIDI_BASE_NOTE + 6,
  MIDI_BASE_NOTE + 7,
  MIDI_BASE_NOTE + 8,
  MIDI_BASE_NOTE + 9,
  MIDI_BASE_NOTE + 10,
  MIDI_BASE_NOTE + 11,
};
final int MIDI_DELTA = MidiFile.QUAVER;
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
  
  // Midi
  if (mf!=null) {
    for (int i=0; i<MIDI_VOICES.length; i++) {
      mf.noteOn(0, MIDI_VOICES[i], cells[i]);
    }
    for (int i=0; i<MIDI_VOICES.length; i++) {
      int delta = (i==0 ? MIDI_DELTA : 0);
      mf.noteOff(delta, MIDI_VOICES[i]);
    }
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
    
    if (mf!=null) {
      stopMidi();
    }
    if (recordMidi) {
      startMidi();
    }
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
  } else if (key=='m') {
    recordMidi = !recordMidi;
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

void startMidi() {
  println("Starting MIDI stream...");
  mf = new MidiFile();
}

void stopMidi() {
  println("Writing MIDI file.");
  try {
    mf.writeToFile ("/Users/mongo/Documents/code/Processing/casa/modelling04/CA1DMidi/poly-" + System.currentTimeMillis() + ".mid");
  } catch (IOException e) {
    println(e);
  }
  mf = null;
}
