
// Visualising flows of bike journey data.
// Step one: load and draw the network.
// Martin Dittus, Feb 2012.

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
}

static final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

// Projection
float minLat = 51.47;
float maxLat = 51.55;
float minLon = -0.22;
float maxLon = -0.05;

// Shapes
float dotSize = 2f;

Map<Integer, Location> locations = null;
List<Flow> flows = null;
List<Journey> journeys = null;

int maxFlows = 71; // TODO: determine dynamically


void setup() {
  size(800, 600, OPENGL);
  noStroke();
  colorMode(HSB);

  try {
    locations = readLocations("locations.csv");
    println(locations.size());
    flows = readFlows("flows.csv");
    println(flows.size());
    journeys = readJourneys("journeys.csv");
    println(journeys.size());
//    records = records.subList(0, 2000);
  } catch (ParseException e) {
    println(e);
    return;
  }
}

void draw() {
  background(0);
  noStroke();
  fill(200);
  for (Location l : locations.values()) {
    dot(
      map(l.lat, minLat, maxLat, 0, width), 
      map(l.lon, minLon, maxLon, 0, height), 
      0);
  }
/*
  strokeWeight(2);
  for (Journey j : journeys) {
    Location a = locations.get(j.startStandId);
    Location b = locations.get(j.endStandId);
    float x1 = map(a.lat, minLat, maxLat, 0, width);
    float y1 = map(a.lon, minLon, maxLon, 0, height); 
    float x2 = map(b.lat, minLat, maxLat, 0, width); 
    float y2 = map(b.lon, minLon, maxLon, 0, height); 
    float dist = sqrt(sq(x1-x2) + sq(y1-y2));
//    println(dist);
    float maxDist = sqrt(width*width + height*height);
    maxDist /= 2;
//    println(maxDist);
    float distC = min(dist, maxDist) / maxDist;
//    println(sat);
//    stroke(0, 200, 255, 10 * (1-distC));
    stroke((255/4) * distC, 200, 255, 10 * (1-distC));
    line(x1, y1, x2, y2);
   
//    dot(l.lat, l.lon, 0);
  }
*/
  for (Flow f : flows) {
    Location a = locations.get(f.startStandId);
    Location b = locations.get(f.endStandId);
    float x1 = map(a.lat, minLat, maxLat, 0, width);
    float y1 = map(a.lon, minLon, maxLon, 0, height); 
    float x2 = map(b.lat, minLat, maxLat, 0, width); 
    float y2 = map(b.lon, minLon, maxLon, 0, height); 
    float dist = sqrt(sq(x1-x2) + sq(y1-y2));
//    println(dist);
    float maxDist = sqrt(width*width + height*height);
    maxDist /= 2;
//    println(maxDist);
    float distC = min(dist, maxDist) / maxDist;
    float flowC = ((float)f.count / maxFlows);
//    flowC *= flowC;
//    println(flowC);
//    println(sat);
//    stroke(0, 200, 255, 10 * (1-distC));
//    stroke((255/4) * distC, 200, 255, 10 * (1-distC));
    strokeWeight(40 * flowC);
//    stroke((255/4) * distC, 200, 255, 10 * (1-distC));
//    stroke((255/4) * distC, 200, 255, 100 * flowC);
    stroke(100 * distC, 200, 255 * (1-flowC), 50);
    if (flowC > 0.03) {
      line(x1, y1, x2, y2);
    }
   
//    dot(l.lat, l.lon, 0);
  }
}

void dot(float x, float y, float z) {
//  pushMatrix();
//  float minHeight = cellSize/10;
//  translate(x, y, (z + minHeight)/2);
//  box(cellSize * 0.999, cellSize * 0.999, z + minHeight);
//  popMatrix();
  beginShape();
  vertex(x, y - dotSize, z);
  vertex(x + dotSize, y, z);
  vertex(x, y + dotSize, z);
  vertex(x - dotSize, y, z);
  endShape(CLOSE);
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

