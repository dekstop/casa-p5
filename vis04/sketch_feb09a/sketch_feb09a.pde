
// Visualising flows of bike journey data.
// Step three: node activity.
// Martin Dittus, Feb 2012.

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.text.SimpleDateFormat;

import processing.opengl.PGraphicsOpenGL;

class Flow {
  int startStandId;
  int endStandId;
  int count;
}

class Journey {
  int id;
  int bikeId;
  Date startDate;
  Date endDate;
  int startStandId;
  int endStandId;
  int duration;
}

class Location {
  int id;
  String name;
  float lat;
  float lon;
  int inventory = 0;
}

static final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

// Projection
float minLat = 51.47;
float maxLat = 51.55;
float minLon = -0.22;
float maxLon = -0.05;
float projectionAspect = 1.0 / 3.0; // Aspect ratio: w/h

float oRotX, rotX = 0;
float oRotZ, rotZ = 0;
boolean isDragging = false;
int mouseClickX;
int mouseClickY;

// Shapes
float dotSize = 0.02f;

Map<Integer, Location> locations = null;
List<Flow> flows = null;
List<Journey> journeys = null;

// Slices of time
TreeMap<Long, List<Journey>> slices;
long currentSliceIdx, minSliceIdx, maxSliceIdx;
int sliceWidth = 10; // moving window size: number of slices drawn per iteration

void setup() {
  size(500, 500, OPENGL);
  calibrateProjection();
  noStroke();
  colorMode(HSB);
  background(0);
//  frameRate(20);

  try {
    locations = readLocations("locations.csv");
    println(locations.size());
    flows = readFlows("flows.csv");
    println(flows.size());
    journeys = readJourneys("journeys.csv");
    println(journeys.size());
  } catch (ParseException e) {
    println(e);
    return;
  }
  slices = aggregateSlices(journeys);
  currentSliceIdx = minSliceIdx = slices.firstKey();
  maxSliceIdx = slices.lastKey();
}

void draw() {

  List<Journey> slice = getSlice(currentSliceIdx, currentSliceIdx + sliceWidth);
  
  background(0);
  noStroke();
  fill(0, 0, 0, 10);
//  fill(0, 0, 0, 255);
//  rect(0, 0, width, height);
  
  // Model
  pushMatrix();
//  rotateZ(-PI / 10);
  translate(width / 2, height / 2);
  rotateX(rotX);
  rotateZ(rotZ);
  translate(-width / 2, -height / 2);
//  fill(0, 0, 0, 10);
//  rect(0, 0, width, height);

  // 1. Stations
  noStroke();
  for (Location l : locations.values()) {
    if (l.inventory > 0) {
      fill(256 / 4, 200, 200, 250); // green
    } else {
      fill(0, 200, 200, 250); // red
    }
    dot(
      map(l.lat, minLat, maxLat, 0, width), 
      map(l.lon, minLon, maxLon, 0, height), 
      0,
      dotSize * abs(l.inventory));
  }
  
  // 2. Journeys
  for (Journey j : slice) {
    Location a = locations.get(j.startStandId);
    Location b = locations.get(j.endStandId);
    a.inventory--;
    b.inventory++;
    float x1 = projectLat(a.lat);
    float y1 = projectLon(a.lon);
    float x2 = projectLat(b.lat);
    float y2 = projectLon(b.lon);
    strokeWeight(1);
    stroke(0, 0, 255, 100);
    line(x1, y1, x2, y2);
  }

  // End model
  popMatrix();

  // Text panels, bars
  noStroke();
  fill(0, 0, 30, 100);
  rect(15, 15, width-30, 50);
  fill(255);
  text("FPS: " + frameRate, width-15-100, 30);
  
  fill(255);
  text(slice.get(0).startDate.toString(), 15, 30);
  text("Bikes in motion: " + slice.size(), 15, 45);
  fill(255/2, 100, 100);
  rect(15, 50, slice.size(), 10);
  float curPos = (float)(currentSliceIdx - minSliceIdx) / (maxSliceIdx - minSliceIdx);
  float h = 10f * slice.size() / 350;
  rect(15 + curPos * (width-30), 75 - h, 5, h);

  // Select next slice
  currentSliceIdx++;
  if (currentSliceIdx > maxSliceIdx) { // restart?
    currentSliceIdx = minSliceIdx;
    background(255);
    resetInventory();
  }
}

void dot(float x, float y, float z, float size) {
//  pushMatrix();
//  float minHeight = cellSize/10;
//  translate(x, y, (z + minHeight)/2);
//  box(cellSize * 0.999, cellSize * 0.999, z + minHeight);
//  popMatrix();
  beginShape();
  vertex(x, y - size, z);
  vertex(x + size, y, z);
  vertex(x, y + size, z);
  vertex(x - size, y, z);
  endShape(CLOSE);
}

void resetInventory() {
  for (Location l : locations.values()) {
    l.inventory = 0;
  }
}

// Updates the viewport in relation to the window size
// so that the target area is fully visible, but aspect
// ratios preserved during projection.
void calibrateProjection() {
  float viewportWidth = abs(maxLat-minLat);
  float viewportHeight = abs(maxLon-minLon);
  float viewportAspect = viewportWidth / viewportHeight;
  float windowAspect = (float)width / height * projectionAspect;
  if (viewportAspect > windowAspect) {
    // extend viewport vertically
    float adjustedVPHeight = viewportWidth / windowAspect;
    float diff = adjustedVPHeight - viewportHeight;
    minLon -= diff/2;
    maxLon += diff/2;
  } else {
    // extend viewport horizontally
    println(viewportAspect);
    println(windowAspect);
    float adjustedVPWidth = viewportHeight * windowAspect;
    println(adjustedVPWidth);
    float diff = abs(adjustedVPWidth - viewportWidth);
    minLat -= diff/2;
    maxLat += diff/2;
  }
}

float projectLat(float lat) {
  return map(lat, minLat, maxLat, 0, width);
}

float projectLon(float lon) {
  return map(lon, minLon, maxLon, 0, height);
}

// Returns all journeys within the range [fromIdx, toIdx[
List<Journey> getSlice(long fromIdx, long toIdx) {
  Map<Long, List<Journey>> window = 
    slices.subMap(currentSliceIdx, currentSliceIdx + sliceWidth);
  List<Journey> slice = new ArrayList<Journey>();
  for (List<Journey> l : window.values()) {
    for (Journey j : l) {
      slice.add(j);
    }
  }
  return slice;
}

// Aggregate journeys by time slice.
TreeMap<Long, List<Journey>> aggregateSlices(List<Journey> journeys) {
  TreeMap<Long, List<Journey>> slices = new TreeMap<Long, List<Journey>>();
  for (Journey j : journeys) {
    long slice = j.startDate.getTime() / 1000 / 60; // 1 minute slices
    if (!slices.containsKey(slice)) {
      slices.put(slice, new ArrayList<Journey>());
    }
    slices.get(slice).add(j);
  }
  return slices;
}

// Data format:
// "casa_id","casa_nicename","lat","lon"
// 10108,"Abbey Orchard Street",51.49812559,-0.132102166
Map<Integer, Location> readLocations(String filename) throws ParseException {
  String[] lines = loadStrings(filename);
  Map<Integer, Location> records = new HashMap<Integer, Location>();
  for (int i=1; i<lines.length; i++) {
    String[] col = split(lines[i], ",");
    Location record = new Location();
    record.id = Integer.parseInt(col[0]);
    record.name = col[1].replaceAll("\"", "");
    record.lat = Float.parseFloat(col[2]);
    record.lon = Float.parseFloat(col[3]);
    records.put(record.id, record);
  }
  return records;
}

// Data format:
// "start_stand_id","end_stand_id","flow"
// 10191,10191,71
List<Flow> readFlows(String filename) throws ParseException {
  String[] lines = loadStrings(filename);
  List<Flow> records = new ArrayList<Flow>();
  for (int i=1; i<lines.length; i++) {
    String[] col = split(lines[i], ",");
    Flow record = new Flow();
    record.startStandId = Integer.parseInt(col[0]);
    record.endStandId = Integer.parseInt(col[1]);
    record.count = Integer.parseInt(col[2]);
    records.add(record);
  }
  return records;
}

// Data format:
// "journey_id","bike_id","start_dt","end_dt","start_stand_id","end_stand_id","duration_amt"
// 1004041956,2682,"2011-04-29 06:00:00","2011-04-29 06:04:00",10087,10104,4
List<Journey> readJourneys(String filename) throws ParseException {
  String[] lines = loadStrings(filename);
  List<Journey> records = new ArrayList<Journey>();
  for (int i=1; i<lines.length; i++) {
    String[] col = split(lines[i], ",");
    Journey record = new Journey();
    record.id = Integer.parseInt(col[0]);
    record.bikeId = Integer.parseInt(col[1]);
    record.startDate = df.parse(col[2].replaceAll("\"", ""));
    record.endDate = df.parse(col[3].replaceAll("\"", ""));
    record.startStandId = Integer.parseInt(col[4]);
    record.endStandId = Integer.parseInt(col[5]);
    record.duration = Integer.parseInt(col[6]);
    records.add(record);
  }
  return records;
}

void mousePressed() {
  mouseClickX = mouseX;
  mouseClickY = mouseY;
  oRotX = rotX;
  oRotZ = rotZ;
}

void mouseDragged() {
  rotX = oRotX + (mouseClickY - mouseY) * PI / height;
  rotZ = oRotZ + (mouseClickX - mouseX) * PI / width;
}

void keyPressed() {
  switch(key) {
    case ' ': resetInventory(); break;
  }
}
