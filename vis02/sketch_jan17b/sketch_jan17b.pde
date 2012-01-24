
// Visualising points over time
// Thoughts:
// * dots that appear and fade out (blend, or scale)
// * motion blur whose direction changes with moving average of spatial trend
// * group into hourly slices, draw intensity curve at bottom, then highlight drawn sections when playing back

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.text.SimpleDateFormat;

import processing.opengl.PGraphicsOpenGL;

class Record {
  Date date;
  String lang;
  String source;
  PVector pos;
  int weekday;
  int hour;
  int userid;
  boolean at;
  boolean rt;
}

static final SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy HH:mm");

float minLat = 51.1;
float maxLat = 51.9;
float minLon = -0.7;
float maxLon = 0.5;

int numCols = 50;
int numRows = 50;
float cellSize = 0.3;

float gridWidth = numCols * cellSize;
float gridHeight = numRows * cellSize;
float gridDepth = (gridWidth + gridHeight) / 2;

float rx = 0;
float ry = 0;
float rz = 0;

int[] counts; // histogram: aggregates counts per hour
int maxCount;
Map<Integer, Float[]> cells; // one entry per hour
float maxCellCount = 0;

int curIdx = 0;
Float[] sourceState;
Float[] targetState;
long startBlendTime = System.currentTimeMillis();
long blendDuration = 500; // in ms

void setup() {
  size(640, 480, OPENGL);
  List<Record> records;
  try {
    records = readFile("London_05-05-2010_coded.csv");
    records = records.subList(0, 2000);
  } catch (ParseException e) {
    println(e);
    return;
  }
  counts = buildHourHistogram(records);
  maxCount = max(counts);
  cells = buildCellGrid(records);
  for (Float[] grid : cells.values()) {
    maxCellCount = max(maxCellCount, Collections.max(Arrays.asList(grid)));
  }
  sourceState = targetState = cells.get(0);

  smooth();
  noStroke();
  colorMode(HSB);
}

void draw() {
  
  background(0);

  // Draw
  
  // hist
  float maxH = height/5f;
  float w = (float)width / counts.length;
  for (int idx=0; idx<counts.length; idx++) {
    float x = map(idx, 0, counts.length, 0, width);
    float h = map(counts[idx], 0, maxCount, 0, maxH);
    
    float hue = 0;//(idx / 24) * 255 / 7;
    float sat = map(counts[idx], 0, maxCount, 0, 255);
    float bri = map(counts[idx], 0, maxCount, 0, 155) + 100;
    float alpha = map(counts[idx], 0, maxCount/6, 0, 140) + 30;
    fill(hue, sat, bri, alpha);
    
    rect(x, height-h, w, h);
  }  
  
  // grid
  pushMatrix();
  scale(width / gridWidth);
  translate(gridWidth/2, gridHeight/3, - (gridWidth+gridHeight) / 2);
  
  rotateX(PI/4 -map(mouseY, 0, height, -PI/6f, PI/6f));
  rotateZ(-map(mouseX, 0, width, -PI/6f, PI/6f));

  Float[] grid = new Float[numRows * numCols];
  long now = System.currentTimeMillis();
  float blend = 1.0f * min(now - startBlendTime, blendDuration) / blendDuration;
  blend = sin((blend-0.5) * PI) / 2 + 0.5; // easing in and out
  for (int i=0; i<numRows*numCols; i++) {
    grid[i] = (1-blend)*sourceState[i] + blend*targetState[i];
  }
  drawGrid(grid);
  popMatrix();
  
  // check for mouse movement -> determine new state
  int idx = mouseX * cells.size() / width;
  if (idx != curIdx) {
    sourceState = grid;
    targetState = cells.get(idx);
    startBlendTime = System.currentTimeMillis();
    curIdx = idx;
  }
  
  // picker
  //fill(255, 0, 255, 130);
  noFill();
  strokeWeight(3);
//  strokeCap(SQUARE);
//  strokeJoin(MITER);
  stroke(0, 0, 255, 130);
  float x = map(idx, 0, counts.length, 0, width);
  rect(x-2, height-maxH-2, w+2, maxH+4);
  noStroke();
}

void drawGrid(Float[] grid) {
  for (int row=0; row<numRows; row++) {
    for (int col=0; col<numCols; col++) {
      float x = map(col, 0, numCols, -gridWidth/2f, gridWidth/2f);
      float y = map(row, 0, numRows, -gridHeight/2f, gridHeight/2f);
      
      Float value = grid[numCols * row + col];
      float sat = map(value, 0, maxCellCount, 0, 255);
      float bri = map(value, 0, maxCellCount, 0, 155) + 100;
      float alpha = map(value, 0, maxCellCount/6, 0, 140) + 30;
//      if (abs(value) <= 0.1f) {
//        fill(0, 0, 100, 30);
//      } else {
        int hue = 0;
        fill(hue, sat, bri, alpha);
//      }
      float z = map(value, 0, maxCellCount, 0, gridDepth);
      dot(x, y, z);
    }
  }
}

int[] buildHourHistogram(List<Record> records) {
  int[] hours = new int[24*7];
  Arrays.fill(hours, 0);
  for (Record rec : records) {
    int hour = (rec.weekday - 1) * 24 + rec.hour;
    hours[hour]++;
  }
  return hours;
}

Map<Integer, Float[]> buildCellGrid(List<Record> records) {
  Map<Integer, Float[]> cells = new HashMap<Integer, Float[]>();
  
  for (int idx=0; idx<7*24; idx++) {
      Float[] grid = new Float[numRows * numCols];
      for (int y=0; y<numRows; y++) {
        for (int x=0; x<numCols; x++) {
          grid[y*numCols + x] = 0.0;
        }
      }
      cells.put(idx, grid);
  }
  
  for (Record rec : records) {
    int col = round(map(rec.pos.x, minLat, maxLat, 0, numCols-1));
    int row = round(map(rec.pos.y, minLon, maxLon, 0, numRows-1));
    int idx = (rec.weekday - 1) * 24 + rec.hour;
    cells.get(idx)[numCols * row + col] += 1.0;
  }
  return cells;
}

void dot(float x, float y, float z) {
  pushMatrix();
  translate(x, y, z);
  box(cellSize);
  popMatrix();
//  beginShape();
//  vertex(x, y - dotSize, z);
//  vertex(x + dotSize, y, z);
//  vertex(x, y + dotSize, z);
//  vertex(x - dotSize, y, z);
//  endShape(CLOSE);
}

// Data format:
// dateT,lang,source,Lat,Long,WeekDay,Hour,UserId,at,rt
// 02/05/2010 21:37,en,UberTwitter,51.477377,-0.209171,1,21,1,1,0
List<Record> readFile(String filename) throws ParseException {
  String[] lines = loadStrings(filename);
  List<Record> records = new ArrayList<Record>();
  
  Map<Integer, Integer> hours = new HashMap<Integer, Integer>();
  Map<Integer, Integer> weekdays = new HashMap<Integer, Integer>();
  Map<Integer, Integer> sources = new HashMap<Integer, Integer>();
  
  for (int i=1; i<lines.length; i++) {
    String[] col = split(lines[i], ",");

    Record rec = new Record();
    rec.date = df.parse(col[0]);
    rec.lang = col[1];
    rec.source = col[2];
    try {
    rec.pos = new PVector(
      Float.parseFloat(col[3]),
      Float.parseFloat(col[4]));
    } catch (Exception e) {
      println(col[3]);
      println(col[4]);
      println(e);
    }
    rec.weekday = Integer.parseInt(col[5]);
    rec.hour = Integer.parseInt(col[6]);
    rec.userid = Integer.parseInt(col[7]);
    rec.at = col[8].equals("1") ? true : false;
    rec.rt = col[9].equals("1") ? true : false;
    
    if (weekdays.get(rec.weekday) == null) {
      weekdays.put(rec.weekday, 0);
    }
    weekdays.put(rec.weekday, weekdays.get(rec.weekday) + 1);

    if (hours.get(rec.hour) == null) {
      hours.put(rec.hour, 0);
    }
    hours.put(rec.hour, hours.get(rec.hour) + 1);

    int s = rec.source.hashCode();
    if (sources.get(s) == null) {
      sources.put(s, 0);
    }
    sources.put(s, sources.get(s) + 1);

    records.add(rec);
  }
  return records;
}

