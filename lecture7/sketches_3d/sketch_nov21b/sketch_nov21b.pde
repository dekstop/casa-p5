PMatrix3D matrix = new PMatrix3D();
boolean overview = true;
int speed = 1;

void setup()
{
    size(500, 500, P3D);
    
    matrix.translate(0, 250, 55);
}

void draw()
{
    background(255);
    camera(300, 300, 300, 0, 0, 0, 0, 0, -1);
    
    //matrix.rotateZ(0.1);
    matrix.translate(0, -speed, 0);
    
    if(!overview)
    {
      PMatrix3D inv = new PMatrix3D(matrix);
      inv.translate(-300, -300, -300);
      inv.translate(0, 0, 55);
      inv.invert();
      applyMatrix(inv);
    }
    
    pushMatrix();
      //translate(0, (250- 10*frameCount),55);
      applyMatrix(matrix);
      fill(255, 255, 200);
      box(5,5,110);
    popMatrix();
    
    //rotateZ(0.02*frameCount);
    
    for(int i = 0; i<5; i++)
    {
        for(int j = 0; j<5; j++)
        {
            pushMatrix();
              int tx = 100*(i-2);
              int ty = 100*(j-2);
              
              translate(tx, ty, 0);
              //rotateZ(0.02*frameCount);
              domino(50, 10, 100);
            popMatrix();
        }
    }

    fill(255, 0,0);
    box(15, 15, 15);
}

void domino(int x, int y, int z)
{
    pushMatrix();
      translate(0, 0, z/2);
      fill(100);
      box(x,y,z);
      
      pushMatrix();
        translate(0, 0, z/4);
        translate(0, 0.5*y, 0);
        fill(0, 0, 255);
        sphere(5);
      popMatrix();
      
      pushMatrix();
        translate(0, 0, -z/4);
        translate(0, 0.5*y, 0);
        fill(0, 255, 0);
        sphere(5);
        
        translate(x/4, 0, z/8);
        sphere(5);
        
        translate(-x/2, 0, -z/4);
        sphere(5);        
      popMatrix();
      
      noFill();
      stroke(0);
      line(-x/2, 1 + (y/2), 0, x/2, 1 + (y/2), 0);
      
    popMatrix();
}

void keyPressed()
{
    if(key==' ') overview = !overview;
    if(key=='a') matrix.rotateZ(-0.1);
    if(key=='d') matrix.rotateZ(0.1);
    if(key=='w') speed++;
    if(key=='s') speed--;
}
