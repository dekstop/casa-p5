
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

static final SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy HH:mm");

long duration = 100 * 100; // loop duration in milliseconds

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

List<Record> records;
float minLat = 51.1;
float maxLat = 51.9;
float minLon = -0.7;
float maxLon = 0.5;

long startTime, curTime, lastTime;

void setup() {
  size(500, 500, P3D);
  try {
    records = readFile("London_05-05-2010_coded.csv");
  } catch (ParseException e) {
    println(e);
  }
  println(records.size());
  Collections.sort(records, new Comparator<Record>() {
    public int compare(Record r1, Record r2) {
      return r2.date.compareTo(r1.date);
    }
    public boolean equals(Object obj) {
      return this == obj;
    }
  });
  //updateBounds(records);

  smooth();
  noStroke();
  colorMode(HSB);
  
  startTime = curTime = lastTime = System.currentTimeMillis();
}

void draw() {
  // Update counters
  curTime = System.currentTimeMillis();
  if (curTime - startTime > duration) {
    println("last frame");
    curTime = startTime + duration;
  }
  if (lastTime == startTime) { // start of loop
    println("start loop");
    //fill(0, 0, 0);
    //rect(0, 0, width, height);  // clear canvas
    background(0);
  }

  // Determine next chunk to draw
  int firstIdx = round(records.size() * ((float)(lastTime - startTime) / duration));
  int lastIdx = round(records.size() * ((float)(curTime - startTime) / duration));

//  rotateY(map(mouseX, 0, width, 0, PI));
//  rotateY(map(mouseY, 0, height, 0, -PI));
  rotateZ(map(mouseX, 0, width, 0, PI));
  
  // Draw
  //fill(255, 255, 255, 30);
  for (int idx=firstIdx; idx<lastIdx; idx++) {
    Record rec = records.get(idx);
    int category = //rec.weekday - 1; //rec.hour; //rec.userid % 10;
      (rec.weekday - 1) * 24 + rec.hour;
    int numCategories = //7; //24; //10;
      7 * 24;
    int hue = rec.userid * 255 / 11510;
    //hue = rec.hour * 255 / 24;
    //hue = (int)((long)rec.source.hashCode() * 255 / Integer.MAX_VALUE);
    hue = (rec.weekday - 1) * 255 / 7;
    fill(hue, 255, 255, 10);
    /*
    ellipse(
      projectLat(rec.pos.x, category, numCategories), 
      projectLon(rec.pos.y, category, numCategories),
      2, 2);
    */
    dot(rec.pos.x, rec.pos.y, 0, category, numCategories);
  }
  
  lastTime = curTime;
  if (curTime == startTime + duration) {
    startTime = curTime = lastTime = System.currentTimeMillis();
  }
}

float dotSize = 3.0;
void dot(float x, float y, float z, int category, int numCategories) {
  float px = projectLat(x, category, numCategories); 
  float py = projectLon(y, category, numCategories);
  beginShape();
  vertex(px, py - dotSize, z);
  vertex(px + dotSize, py, z);
  vertex(px, py + dotSize, z);
  vertex(px - dotSize, py, z);
  endShape(CLOSE);
}

float projectLat(float lat) {
  return width * (lat - minLat) / (maxLat - minLat);
}

float projectLon(float lon) {
  return height * (lon - minLon) / (maxLon - minLon);
}

float projectLat(float lat, int category, int numCategories) {
  int numRows = ceil(sqrt(numCategories));
  int numCols = ceil((float)numCategories / numRows);
  //float rowHeight = height / numRows;
  float colWidth = width / numCols;
  //int row = category / numCols;
  int col = category % numCols;
  return colWidth * col + colWidth * (lat - minLat) / (maxLat - minLat);
}

float projectLon(float lon, int category, int numCategories) {
  int numRows = ceil(sqrt(numCategories));
  int numCols = ceil((float)numCategories / numRows);
  float rowHeight = height / numRows;
  //float colWidth = width / numCols;
  int row = category / numCols;
  //int col = category % numCols;
  return rowHeight * row + rowHeight * (lon - minLon) / (maxLon - minLon);
}

void updateBounds(List<Record> records) {
  Record first = records.get(0);
  minLat = first.pos.x;
  maxLat = first.pos.x;
  minLon = first.pos.y;
  maxLon = first.pos.y;
  
  for (Record rec : records) {
    minLat = min(minLat, rec.pos.x);
    maxLat = max(maxLat, rec.pos.x);
    minLon = min(minLon, rec.pos.y);
    maxLon = max(maxLon, rec.pos.y);
  }
  println(minLat);
  println(maxLat);
  println(minLon);
  println(maxLon);
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
  println(weekdays);
  println(hours);
  println(sources);
  return records;
}

