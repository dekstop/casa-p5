
// Visualising flows of bike journey data.
// Step three: bike stand activity, journeys in motion.
// - bike stand size: estimated inventory; or rather, cumulative growth since start of day: all incoming minus all outgoing bikes
// - bike stand hue: gain/loss of bicycles within the last ~2h (green: gain, red: loss, yellow: no change)
// 
// Martin Dittus, Feb 2012.

// TODO:
// - test if journey duration (not distance) is location-specific; it is dependent on time of day
// - find higher resolution basemap, maybe a river outline, parks etc
// - inverted colour scheme: background white, darker journeys
// - render basemap, nodes and flows onto separate textures, only blend them during display
//   - only flows renderer should have motion blur
// - render static histogram once, then overlay a cursor with current position
// - implement zoom/pan
//   - then show all of London as opening shot, but zoom in for animation

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.text.SimpleDateFormat;

import processing.opengl.PGraphicsOpenGL;

import processing.video.*;

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
  float distance;
}

class Location {
  int id;
  String name;
  float lat;
  float lon;
  int numSource = 0;
  int numDest = 0;
  
  LinkedList<Integer> inventoryHistory = new LinkedList<Integer>();
}

static final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

// Projection
//float minLat = 51.25;
//float maxLat = 51.75;
//float minLon = -0.22;
//float maxLon = -0.05;

//float minLat = 51.47;
//float maxLat = 51.55 + 0.0133;
//float minLon = -0.22;
//float maxLon = -0.05;

float minLat = 51.47 + 0.0133 + 0.002;
float maxLat = 51.55 - 0.0133 + 0.01;
float minLon = -0.22 + 0.01;
float maxLon = -0.05 - 0.01;

float projectionAspect = 3.0 / 1.7; // Aspect ratio: w/h

// Shapes
float dotScale = 2.0;
int fontSize = 24;

Map<String, List<PVector>> map = null;

Map<Integer, Location> locations = null;
List<Flow> flows = null;
Set<Journey> journeys = null;
Set<Journey> activeJourneys = new HashSet<Journey>();

// Loop state
long minTime, maxTime;
int maxConcurrentJourneys = 871; //0;
long loopDuration = 50 * 1000; // loop time in ms
long loopStartTime;

long inventoryChurnWindowDuration = loopDuration / 1000 * 3; // time between old and new inventory, in number of frames

long currentTimeMillis;
MovieMaker mm = null;
boolean recordMovie = true;

void setup() {
  size(1920, 1080, OPENGL);
  textSize(fontSize);
  calibrateProjection();
  noStroke();
  colorMode(HSB);
  background(0);
//  frameRate(20);

  try {
    map = readMap("boroughs.csv");
    locations = readLocations("locations.csv");
    println("Locations: " + locations.size());
    flows = readFlows("flows.csv");
    println("Flows: " + flows.size());
    journeys = new HashSet<Journey>(readJourneys("journeys.csv"));
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

    // Precompute trip distances
    Location a = locations.get(j.startStandId);
    Location b = locations.get(j.endStandId);
    j.distance = sqrt(sq(a.lat-b.lat) + sq(a.lon-b.lon));
  }
  println("Max concurrent journeys: " + maxConcurrentJourneys);
  loopStartTime = currentTimeMillis = 0; //System.currentTimeMillis();
}

void draw() {
  // Current state
  long loopTime; // playback time within loop, in ms
  while ((loopTime = currentTimeMillis - loopStartTime) > loopDuration) {
    if (mm != null) {
      mm.finish();
      System.exit(0);
    }
    loopStartTime += loopDuration;
    background(255);
    resetInventory();
  }
  currentTimeMillis += 1000 / 30;

  long curTime = minTime + loopTime * (maxTime-minTime) / loopDuration; // time in model, in ms
  Set<Journey> oldActiveJourneys = activeJourneys;
  activeJourneys = getActiveJourneys(journeys, curTime);
  
  // Update counters
  Set<Journey> journeysAdded = new HashSet<Journey>(activeJourneys);
  journeysAdded.removeAll(oldActiveJourneys);
  for (Journey j : journeysAdded) {
    Location l = locations.get(j.startStandId);
    l.numSource++;
  }
  
  Set<Journey> journeysRemoved = new HashSet<Journey>(oldActiveJourneys);
  journeysRemoved.removeAll(activeJourneys);
  for (Journey j : journeysRemoved) {
    Location l = locations.get(j.endStandId);
    l.numDest++;
  }
  
  // Update inventory
  for (Location l : locations.values()) {
    int inventory = l.numDest - l.numSource;
    l.inventoryHistory.add(inventory);
    while (l.inventoryHistory.size() > inventoryChurnWindowDuration) {
      l.inventoryHistory.remove(0);
    }
  }
  
  // Prepare display
  fill(0, 0, 0, 10);
  rect(0, 0, width, height);
  
  // Basemap
//  noFill();
//  stroke(255 * 5 / 8, 50, 100, 2); // blue
//  strokeWeight(4.5f);
//  drawMap(map);
//  noStroke();

  // Model
  drawStations(locations.values());
  drawJourneys(activeJourneys, curTime);

  // Text panel, bars
  drawCaptions(activeJourneys, maxConcurrentJourneys, curTime, loopTime, loopDuration);

  // Recording
  if (recordMovie) {
   if (mm==null) {
      mm = new MovieMaker(this, width, height, 
        "recording-" + System.currentTimeMillis() + ".mov",
        30, MovieMaker.MOTION_JPEG_B, MovieMaker.BEST);
    }
    mm.addFrame();
  }
}

void drawMap(Map<String, List<PVector>> map) {
  for (List<PVector> poly : map.values()) {
    beginShape();
    for (PVector p : poly) {
      vertex(projectLon(p.x), projectLat(p.y), 0);
//      dot(x, y, 0, 4);
    }
    vertex(projectLon(poly.get(0).x), projectLat(poly.get(0).y), 0);
    endShape(CLOSE);
  }
}

void drawStations(Collection<Location> locations) {
  for (Location l : locations) {
    int oldInventory = l.inventoryHistory.getFirst();
    int inventory = l.inventoryHistory.getLast();
    int inventoryDifference = inventory - oldInventory;

    float fillState = min(20, max(0, inventoryDifference + 10)) / 20f; // map [-20..20] inventory change to [0..1] range
    fill(
      (256 / 4) * fillState, // map [0..1] to [red..green] colour
      250, 200, 130);
//    dot(projectLon(l.lon), projectLat(l.lat), 0, 4 + dotSize * turnover); // circle: turnover and inventory
    dot(projectLon(l.lon), projectLat(l.lat), 0, 1 + max(0, inventory + 6) / 2f); // circle: inventory

//    fill(0, 0, 150, 255);
//    dot(projectLon(l.lon), projectLat(l.lat), 0, 1); // dot: location
  }
}

// curTime: current model time, in ms since epoch
void drawJourneys(Collection<Journey> journeys, long curTime) {
  for (Journey j : journeys) {
    Location a = locations.get(j.startStandId);
    Location b = locations.get(j.endStandId);
    
    // Path
    float x1 = a.lon;
    float y1 = a.lat;
    float x2 = b.lon;
    float y2 = b.lat;
    
    // Current position
    float progress = (float)(curTime - j.startDate.getTime()) / (j.endDate.getTime() - j.startDate.getTime());
    // Tween: ease in, ease out
    float position = sin(progress * PI - PI/2) / 2 + 0.5;
    float size = sin(progress * PI);
    float px = projectLon(((1-position) * x1) + (position * x2));
    float py = projectLat(((1-position) * y1) + (position * y2));

    fill(255*5/8, 200, 150 + 100 * size, size * 1); // blue halo: trajectory
    if (size > 0.5) dot(px, py, 0, size * size * size * 50);
//    fill(255*5/8, 200, 150 + 100 * progress, progress * 10); // blue halo: focus on destination
//    dot(px, py, 0, progress * progress * 50);
//    float s = 1 - progress;
//    fill(255*5/8, 200, 150 + 100 * s, s * 10); // blue halo: focus on source
//    dot(px, py, 0, s * 50);

    fill(255*5/8, 200, 150 + 100 * size, 0 + size * 10); // blue body
    if (size > 0.2) dot(px, py, 0, size * size * size * 10);

    fill(255*5/8, 50, 55 + 200 * size, 50 + 70 * size); // blue/white peak
    dot(px, py, 0, 1 + size * size * 1.5);
  }
}

void dot(float x, float y, float z, float size) {
  ellipse(x, y, size * dotScale, size * dotScale);
}

void drawCaptions(Collection<Journey> journeys, int maxConcurrentJourneys, long curTime, long loopTime, long loopDuration) {
  fill(0, 0, 15 + 2 * fontSize, 100);
  rect(15, 15, width-30, 2.5 * fontSize); // background panel

  fill(255);
  text(df.format(new Date(curTime)), 15 + 0.5 * fontSize, 15 + fontSize);
  text(String.format("Bikes in motion: %d", activeJourneys.size()), 15 + 0.5*fontSize, 15 + 2 * fontSize);
  text("covspc.wordpress.com", width-15-11.5*fontSize, 15 + fontSize);
//  text(String.format("FPS: %.1f", frameRate), width-15-70, 45);
  
  float distance = 0;
  float duration = 0;
  for (Journey j : activeJourneys) {
    distance += j.distance;
    duration += j.duration * 60;
  }
  distance /= activeJourneys.size();
  duration /= activeJourneys.size() * 60;
  text(String.format("Avg trip distance: %.3f", distance), width/2-10*fontSize, 15 + fontSize);
  text(String.format("Avg trip duration: %.1f min", duration), width/2-10*fontSize, 15 + 2 * fontSize);

  fill(255/2, 100, 100); // activity bar
  float activity = (float)activeJourneys.size() / maxConcurrentJourneys; // [0..1]
  rect(15, 15 + 3 * fontSize, activity * (width-30), 3);

  fill(255/2, 100, 250); // histogram
  float curPos = (float)loopTime / loopDuration;
  float h = activity * 1.5 * fontSize;
  rect(15 + curPos * (width-30), 15 + 5 * fontSize - h, 5, h);
}


void resetInventory() {
  for (Location l : locations.values()) {
    l.numSource = 0;
    l.numDest = 0;
    l.inventoryHistory.clear();
  }
}

// Updates the viewport in relation to the window size
// so that the target area is fully visible, but aspect
// ratios preserved during projection.
void calibrateProjection() {
  float viewportWidth = abs(maxLon-minLon);
  float viewportHeight = abs(maxLat-minLat);
  float viewportAspect = viewportWidth / viewportHeight;
  float windowAspect = (float)width / height * projectionAspect;
  if (viewportAspect > windowAspect) {
    // extend viewport vertically
    float adjustedVPHeight = viewportWidth / windowAspect;
    float diff = adjustedVPHeight - viewportHeight;
    minLat -= diff/2;
    maxLat += diff/2;
  } else {
    // extend viewport horizontally
    float adjustedVPWidth = viewportHeight * windowAspect;
    float diff = abs(adjustedVPWidth - viewportWidth);
    minLon -= diff/2;
    maxLon += diff/2;
  }
}

float projectLon(float lon) {
  return map(lon, minLon, maxLon, 0, width);
}

float projectLat(float lat) {
  return map(lat, minLat, maxLat, height, 0);
}

// Get journeys active at a given point in time.
// FIXME: this is really sloow... need a better data structure for fast lookups.
// Maybe try segmenting it.
Set<Journey> getActiveJourneys(Set<Journey> journeys, long time) {
  Set<Journey> active = new HashSet<Journey>();
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

// Data format:
// id, name, lat, lon
// 1,Bromley,541177.710938455,173555.745843674
Map<String, List<PVector>> readMap(String filename) throws ParseException {
  String[] lines = loadStrings(filename);
  Map<String, List<PVector>> records = new HashMap<String, List<PVector>>();
  for (int i=1; i<lines.length; i++) {
    String[] col = split(lines[i], ",");
    String name = col[1];
    if (!records.containsKey(name)) {
      records.put(name, new ArrayList<PVector>());
    }
    List<PVector> coords = records.get(name);
    float lat = Float.parseFloat(col[2]);
    float lon = Float.parseFloat(col[3]);
    coords.add(new PVector(lon, lat));
  }
  return records;
}

void keyPressed() {
  switch(key) {
    case ' ': resetInventory(); break;
  }
}
