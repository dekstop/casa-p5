
// Visualising flows of bike journey data.
// Step three: node activity.
// Martin Dittus, Feb 2012.

// TODO:
// - only increment activity counters at start/end of journey
// - node size/brightness: activity over time (number of journeys starting or ending here)
// - node hue: relative inventory balance (red/white/green)
// - add basemap of boroughs

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
float dotSize = 0.01f;

Map<Integer, Location> locations = null;
List<Flow> flows = null;
List<Journey> journeys = null;

// Loop state
long minTime, maxTime;
int maxConcurrentJourneys = 871; //0;
long loopDuration = 20 * 1000; // loop time in ms
long loopStartTime;

void setup() {
  size(800, 600, OPENGL);
  calibrateProjection();
  noStroke();
  colorMode(HSB);
  background(0);
//  frameRate(20);

  try {
    locations = readLocations("locations.csv");
    println("Locations: " + locations.size());
    flows = readFlows("flows.csv");
    println("Flows: " + flows.size());
    journeys = readJourneys("journeys.csv");
    println("Journeys: " + journeys.size());
  } catch (ParseException e) {
    println(e);
    return;
  }
  minTime = Long.MAX_VALUE;
  maxTime = Long.MIN_VALUE;
  for (Journey j : journeys) {
    minTime = Math.min(minTime, j.startDate.getTime());
    maxTime = Math.max(maxTime, j.endDate.getTime());
//    maxConcurrentJourneys = max(maxConcurrentJourneys, getActiveJourneys(journeys, j.startDate.getTime()).size());
  }
  println("Max concurrent journeys: " + maxConcurrentJourneys);
  loopStartTime = System.currentTimeMillis();
}

void draw() {

  // Current state
  long loopTime; // playback time within loop, in ms
  while ((loopTime = System.currentTimeMillis() - loopStartTime) > loopDuration) {
    loopStartTime += loopDuration;
    background(255);
    resetInventory();
  }
  long curTime = minTime + loopTime * (maxTime-minTime) / loopDuration; // time in model, in ms
  List<Journey> activeJourneys = getActiveJourneys(journeys, curTime);
  
  // Prepare display
//  background(0);
  noStroke();
  fill(0, 0, 0, 10);
//  fill(0, 0, 0, 255);
  rect(0, 0, width, height);
  
  // Model
  pushMatrix();
//  rotateZ(-PI / 10);
  translate(width / 2, height / 2);
  rotateX(rotX);
  rotateZ(rotZ);
  translate(-width / 2, -height / 2);
//  fill(0, 0, 0, 10);
//  rect(0, 0, width, height);

  // Journeys
  for (Journey j : activeJourneys) {
    Location a = locations.get(j.startStandId);
    Location b = locations.get(j.endStandId);
    a.inventory--; // TODO: move this to first frame of this journey only
    b.inventory++; // TODO: move this to last frame of this journey only
    
    // Path
    float x1 = projectLat(a.lat);
    float y1 = projectLon(a.lon);
    float x2 = projectLat(b.lat);
    float y2 = projectLon(b.lon);
//    strokeWeight(1);
//    stroke(0, 0, 255, 100);
//    line(x1, y1, x2, y2);
    
    // Current position
    float progress = (float)(curTime - j.startDate.getTime()) / (j.endDate.getTime() - j.startDate.getTime());
    // Tween: ease in, ease out
    float position = sin(progress * PI - PI/2) / 2 * 0.5;
    float size = sin(progress * PI);
    float px = ((1-position) * x1) + (position * x2);
    float py = ((1-position) * y1) + (position * y2);
    noStroke();
    fill(255*5/8, 200, 150 + 100 * size, 20 + size * 50); // blue
    dot(px, py, 0, size * size * 5);
  }

  // Stations
  noStroke();
  for (Location l : locations.values()) {
    if (l.inventory > 0) {
      fill(256 / 4, 250, 200, 200); // green
    } else {
      fill(0, 200, 250, 200); // red
    }
    dot(projectLat(l.lat), projectLon(l.lon), 0, 2 + dotSize * abs(l.inventory));
  }
  
  // End model
  popMatrix();

  // Text panels, bars
  noStroke();
  fill(0, 0, 30, 100);
  rect(15, 15, width-30, 42); // background panel

  fill(255);
  text("FPS: " + frameRate, width-15-100, 30);
  text(new Date(curTime).toString(), 15, 30);
  text("Bikes in motion: " + activeJourneys.size(), 15, 45);

  fill(255/2, 100, 100); // activity bar
  float activity = (float)activeJourneys.size() / maxConcurrentJourneys; // [0..1]
  rect(15, 50, activity * (width-30), 3);

  fill(255/2, 100, 250); // histogram
  float curPos = (float)loopTime / loopDuration;
  float h = activity * 10;
  rect(15 + curPos * (width-30), 70 - h, 5, h);
}

void dot(float x, float y, float z, float size) {
//  pushMatrix();
//  float minHeight = cellSize/10;
//  translate(x, y, (z + minHeight)/2);
//  box(cellSize * 0.999, cellSize * 0.999, z + minHeight);
//  popMatrix();

//  beginShape();
//  vertex(x, y - size, z);
//  vertex(x + size, y, z);
//  vertex(x, y + size, z);
//  vertex(x - size, y, z);
//  endShape(CLOSE);

  ellipse(x, y, size, size);
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

// Get journeys active at a given point in time.
// FIXME: this is really sloow... need a better data structure for fast lookups.
// Maybe try segmenting it.
List<Journey> getActiveJourneys(List<Journey> journeys, long time) {
  List<Journey> active = new ArrayList<Journey>();
  for (Journey j : journeys) {
    if (j.startDate.getTime() <= time && j.endDate.getTime() >= time) {
      active.add(j);
    }
  }
  return active;
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
