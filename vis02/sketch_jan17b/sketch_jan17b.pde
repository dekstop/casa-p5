
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

class Node {
  Record record;
  float x;
  float y;
  float z;
}

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

float dotSize = 0.3;

float xDim = 400;
float yDim = 400;
float zDim = 24 * 7 * dotSize;

float rx = 0;
float ry = 0;
float rz = 0;

List<Node> nodes;

void setup() {
  size(500, 500, OPENGL);
  List<Record> records;
  try {
    records = readFile("London_05-05-2010_coded.csv");
    records = records.subList(0, 2000);
  } catch (ParseException e) {
    println(e);
    return;
  }
  nodes = buildModel(records);

  smooth();
  noStroke();
  colorMode(HSB);
}

void draw() {
  
  background(0);

  pushMatrix();
  translate(xDim/2, yDim/2, -zDim * 5);
  scale(width / zDim);
  
//  rotateY(map(mouseX, 0, width, 0, PI));
//  rotateY(map(mouseY, 0, height, 0, -PI));
//  rotateZ(map(mouseX, 0, width, 0, PI));

  rx = map(-mouseY, 0, width, 0, PI*2);
//  ry = map(mouseX, 0, width, 0, PI*2);
  rz = map(-mouseX, 0, width, 0, PI*2);

  rotateX(rx);
  rotateY(ry);
  rotateZ(rz);
  
  // Draw
  for (Node node : nodes) {
    Record rec = node.record;
    int hue = (rec.weekday - 1) * 255 / 7;
    fill(hue, 255, 255, 50);
    dot(node.x, node.y, node.z);
  }

  popMatrix();
}

List<Node> buildModel(List<Record> records) {
  List<Node> nodes = new ArrayList<Node>();
  for (Record rec : records) {
    Node node = new Node();
    node.record = rec;
    node.x = map(rec.pos.x, minLat, maxLat, -xDim/2, xDim/2);
    node.y = map(rec.pos.y, minLon, maxLon, -yDim/2, yDim/2);
    node.z = map(rec.hour * (rec.weekday - 1), 0, 7*24, -zDim/2, zDim/2);
    nodes.add(node);
  }
  return nodes;
}

void dot(float x, float y, float z) {
  pushMatrix();
  translate(x, y, z);
  box(dotSize * 2);
  popMatrix();
//  beginShape();
//  vertex(x, y - dotSize, z);
//  vertex(x + dotSize, y, z);
//  vertex(x, y + dotSize, z);
//  vertex(x - dotSize, y, z);
//  endShape(CLOSE);
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

