ArrayList<Hunter> h = new ArrayList<Hunter>();

void setup() {
  size(800, 800);
  Hunter h1 = new Hunter();
  h1.x = new PVector(width/2, height/2);
  h1.fixed = true;
  h.add(h1);
}

void draw() {
  if (h.size() < 1000) {
    h.add(new Hunter());
  }
  
//  background(255);
  fill(255, 255, 255, 10);
  rect(0, 0, width, height);
  
  for (Hunter hunter : h) {
    hunter.walk();
    hunter.stick(h);
    hunter.display();
  }
}

class Hunter {

  boolean fixed;
  PVector x;
  PVector velocity;
  
  Hunter() {
    x = new PVector(random(0, width), random(0, height));
    velocity = new PVector(random(-1, 1), random(-1, 1));
  }
 
 void display() {
   noStroke();
   if (fixed) {
     fill(255, 0, 0);
     ellipse(x.x, x.y, 5, 5);
   } else {
     fill(0);
     ellipse(x.x, x.y, 2, 2);
   }
 } 
 
 void walk() {
   if (!fixed) {
//     x.add(new PVector(random(-2, 2), random(-2, 2)));
     x.add(velocity);
     velocity.add(new PVector(random(-0.1, 0.1), random(-0.1, 0.1)));
     if (x.x < 0) x.x = width-1;
     if (x.x >= width) x.x = 0;
     if (x.y < 0) x.y = height-1;
     if (x.y >= height) x.y = 0;
   }
 }
 
 void stick(ArrayList<Hunter> all) {
   for (Hunter h : all) {
     if (h!=this && h.fixed) {
       if (h.x.dist(x) < 6) {
         fixed = true;
//         h.fixed = true;
       }
     }
   }
 }
}
