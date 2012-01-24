
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

interface Predicate<T> {
  boolean apply(T item);
}

public static <T> List<T> filter(Collection<T> target, Predicate<T> predicate) {
  List<T> result = new ArrayList<T>();
  for (T element: target) {
    if (predicate.apply(element)) {
      result.add(element);
    }
  }
  return result;
}

static final SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy HH:mm");

// Projection
float minLat = 51.1;
float maxLat = 51.9;
float minLon = -0.7;
float maxLon = 0.5;

// Grid geometry
int numCols = 50;
int numRows = 50;
float cellSize = 0.3;

float gridWidth = numCols * cellSize;
float gridHeight = numRows * cellSize;
float gridDepth = (gridWidth + gridHeight) / 2;

// Model
List<Record> records;
int[] counts; // histogram: aggregates counts per hour
int maxCount;
Map<Integer, Float[]> cells; // one entry per hour
float maxCellCount = 0;

// Filters
Boolean filterAt = null; // three-state toggles
Boolean filterRt = null;

String[] languages = new String[] { // top 9, and "all"
  null, "de", "en", "es", "eo", "fr", "id", "it", "nl", "no"
};
int filterLangIdx = 0;

String[] sources = new String[] { // top 9, and "all"
  null, "API", "Echofon", "TweetDeck", "Tweetie", "Twittelator", 
  "Twitter for BlackBerry", "Twitterrific", "UberTwitter", "web"
};
int filterSourceIdx = 0;

// Transitions
int curIdx = 0;
boolean lockSelection = false; // allow to move mouse without changing selection
Float[] sourceState;
Float[] targetState;
long startBlendTime;
long blendDuration = 500; // in ms
boolean forceTransition = false; // after filter changes

void setup() {
  size(800, 600, OPENGL);
  try {
    records = readFile("London_05-05-2010_coded.csv");
//    records = records.subList(0, 2000);
  } catch (ParseException e) {
    println(e);
    return;
  }
  updateModel(records);
  resetTransition();

  noStroke();
  colorMode(HSB);
}

void draw() {
  background(0);
  
  // Captions
  fill(255, 0, 255, 255);
  noSmooth();
  text("[L] Lock selection: " + lockSelection, 15, 25);
  text("Filters:", 15, 50);
  text("[1] AT: " + (filterAt==null ? "off" : filterAt), 15, 62);
  text("[2] RT: " + (filterRt==null ? "off" : filterRt), 15, 74);
  text("[3] Language: " + (languages[filterLangIdx]==null ? "all" : languages[filterLangIdx]), 15, 86);
  text("[4] Source: " + (sources[filterSourceIdx]==null ? "all" : sources[filterSourceIdx]), 15, 98);
  smooth();
  
  // Histogram
  float maxH = height/10f;
  float w = (float)width / counts.length;
  int prevX = 0;
  for (int idx=0; idx<counts.length; idx++) {
    int x = round(map(idx+1, 0, counts.length, 0, width));
    float h = maxH; //map(counts[idx], 0, maxCount, 0, maxH); // scale with value
    
    float hue = 255 / 2;//(idx / 24) * 255 / 7;
    float sat = 70;//map(counts[idx], 0, maxCount, 0, 200) + 55;
    float bri = map(counts[idx], 0, maxCount, 0, 100) + 155;
    float alpha = map(counts[idx], 0, maxCount/6, 0, 50) + 50;
    fill(hue, sat, bri, alpha);
    
    rect(prevX, height-h, x-prevX, h);
    prevX = x;
  }  
  
  // Grid projection
  pushMatrix();
  scale(width / gridWidth);
  translate(gridWidth/2, gridHeight/4, - (gridWidth+gridHeight) / 2);
  scale(2);
  
  rotateX(PI/4 -map(mouseY, 0, height, -PI/6f, PI/6f));
  rotateZ(-map(mouseX, 0, width, -PI/6f, PI/6f));

  Float[] grid = new Float[numRows * numCols];
  long now = System.currentTimeMillis();
  float blend = 1.0f * min(now - startBlendTime, blendDuration) / blendDuration;
  //blend = sin((blend-0.5) * PI) / 2 + 0.5; // easing in and out
  blend = sin(blend * PI/2); // easing out
  for (int i=0; i<numRows*numCols; i++) {
    grid[i] = (1-blend)*sourceState[i] + blend*targetState[i];
  }
  drawGrid(grid);
  popMatrix();
  
  // Transitions
  // check for mouse movement -> determine new state
  int idx;
  if (lockSelection) {
    idx = curIdx;
  } else {
    idx = mouseX * cells.size() / width;
  }
  if (forceTransition || idx != curIdx) {
    forceTransition = false;
    sourceState = grid;
    targetState = cells.get(idx);
    startBlendTime = System.currentTimeMillis();
    curIdx = idx;
  }
  
  // Picker
  //fill(255, 0, 255, 130);
  noFill();
  noSmooth();
  strokeWeight(3);
//  strokeCap(SQUARE);
//  strokeJoin(MITER);
  stroke(0, 0, 255, 255);
  float x = map(idx, 0, counts.length, 0, width);
  rect(x-2, height-maxH-2, w+2, maxH+4);
  smooth();
  noStroke();
}

void drawGrid(Float[] grid) {
  for (int row=0; row<numRows; row++) {
    for (int col=0; col<numCols; col++) {
      float x = map(col, 0, numCols, -gridWidth/2f, gridWidth/2f);
      float y = map(row, 0, numRows, -gridHeight/2f, gridHeight/2f);
      Float value = grid[numCols * row + col];
      float z = map(value, 0, maxCellCount, 0, gridDepth);

      float xd = (numCols/2f-col) / numCols/2f;
      float yd = (numRows/2f-row) / numRows/2f;
      int hue = round(sqrt((xd*xd)+(yd*yd)) * 255); // distance from centre
      float sat = map(value, 0, maxCellCount/6, 0, 155) + 100; // value
      float bri = map(value, 0, maxCellCount/10, 0, 155) + 100; // value
      float alpha = map(value, 0, maxCellCount/100, 0, 140) + 30; // value
      fill(hue, sat, bri, alpha);

      dot(x, y, z);
    }
  }
}

void dot(float x, float y, float z) {
  pushMatrix();
  translate(x, y, (z + cellSize)/2);
  box(cellSize, cellSize, z + cellSize);
  popMatrix();
//  beginShape();
//  vertex(x, y - dotSize, z);
//  vertex(x + dotSize, y, z);
//  vertex(x, y + dotSize, z);
//  vertex(x - dotSize, y, z);
//  endShape(CLOSE);
}

// Three-state toggle
Boolean toggle(Boolean value) {
  if (value==null) {
    return true;
  } else if (Boolean.TRUE.equals(value)) {
    return false;
  } else {
    return null;
  }
}

void keyPressed() {
  if (key == '1') {
    filterAt = toggle(filterAt);
    applyModelFilters();
  } else if (key=='2') {
    filterRt = toggle(filterRt);
    applyModelFilters();
  } else if (key=='3') {
    filterLangIdx = (filterLangIdx + 1) % languages.length;
    applyModelFilters();
  } else if (key=='4') {
    filterSourceIdx = (filterSourceIdx + 1) % sources.length;
    applyModelFilters();
  } else if (key=='l') {
    lockSelection = !lockSelection;
  }
}

void applyModelFilters() {
  List<Record> filteredRecords = filter(records, new Predicate<Record>() {
    public boolean apply(Record rec) {
      if (filterAt!=null) {
        if (!filterAt.equals(rec.at)) return false;
      }
      if (filterRt!=null) {
        if (!filterRt.equals(rec.rt)) return false;
      }
      String lang = languages[filterLangIdx];
      if (lang!=null) {
        if (!lang.equals(rec.lang)) return false;
      }
      String source = sources[filterSourceIdx];
      if (source!=null) {
        if (!source.equals(rec.source)) return false;
      }
      return true;
    }
  });
  updateModel(filteredRecords);
  forceTransition = true;
}

void updateModel(List<Record> records) {
  counts = buildHourHistogram(records);
  maxCount = max(counts);
  cells = buildCellGrid(records);
  for (Float[] grid : cells.values()) {
    maxCellCount = max(maxCellCount, Collections.max(Arrays.asList(grid)));
  }
}

void resetTransition() {
  sourceState = targetState = cells.get(curIdx);
  startBlendTime = System.currentTimeMillis();
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
    int col = max(0, min(numCols-1, round(map(rec.pos.x, minLat, maxLat, 0, numCols-1))));
    int row = max(0, min(numRows-1, round(map(rec.pos.y, minLon, maxLon, 0, numRows-1))));
    int idx = (rec.weekday - 1) * 24 + rec.hour;
    cells.get(idx)[numCols * row + col] += 1.0;
  }
  return cells;
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

