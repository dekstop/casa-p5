PVector eye = new PVector(500, 500, 500);
PVector centre = new PVector(0,0,0);
PVector ud = new PVector(0, 0, -1);

void setup()
{
    size(500, 500, P3D);
}

void draw()
{
    background(50);
    
    ambientLight(100, 100, 100);
    directionalLight(100, 100, 100, 0, -1, 0);
    camera(eye.x*sin(0.02*frameCount), cos(0.02*frameCount)*eye.y, eye.z*cos(0.02*frameCount), centre.x, centre.y, centre.z, ud.x, ud.y, ud.z);
    //camera(eye.x, eye.y, eye.z, centre.x, centre.y, centre.z, ud.x, ud.y, ud.z);
    
    
    fill(100);
    pushMatrix();
      rotateZ(0.05*frameCount);
      box(50, 50, 50);      
    popMatrix();
    
    pushMatrix();
      fill(255, 0, 0);
      rotateY(0.01*frameCount);
      translate(250, 0, 0);
      
      box(100, 100, 100);
    popMatrix();
    
    pushMatrix();
      fill(0, 255, 0);
      rotateZ(0.01*frameCount);
      translate(0, 250, 0);
      box(100, 100, 100);
    popMatrix();
    
    pushMatrix();
      fill(0, 0, 255);
      rotateX(0.1*frameCount);
      translate(0, 0, 250);
      box(100, 100, 100);
    popMatrix();
    
}
