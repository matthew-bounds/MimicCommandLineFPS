/*  
  Used to create a simple container for two floating point values  
*/

private class Pair  
{
  public float first;
  public float second;
  
  public Pair(float a, float b)
  {
    first = a;
    second = b;
  }  
} // end Pair class



int nMapWidth = 16;        // World Dimensions
int nMapHeight = 16;       

int fScale = 80;

int nBlockWidth;       // fScale to draw single block
int nBlockHeight;

float fPlayerX = 14.7f;      // Player Start Position
float fPlayerY = 5.011f;
float fPlayerA = 0.0f;      // Player Start Rotation
float fFOV = QUARTER_PI;  // Field of View
float fDepth = 16.0f;      // Maximum rendering distance
float fSpeed = 3.0f;      // Walking Speed

int nBlinkCounter = 0;    // Blink player posistion on mini-map
String levelMap = "";
boolean[] bCurrentKeysPressed = new boolean[4]; // stores the current keys pressed 4 for WASD
/*
    0 - W
    1 - A
    2 - S
    3 - D
*/

void setup()
{
  size(960, 960);
  frameRate(60);  // cap frame rate
  
  nBlockWidth = width/fScale - 1; 
  nBlockHeight = height/fScale - 1;
  
  for(int i =0; i < 4; i++)
    bCurrentKeysPressed[i] = false;
    
  levelMap += "################";
  levelMap += "#..#...........#";
  levelMap += "#..#...........#";
  levelMap += "#..####........#";
  levelMap += "#..#...........#";
  levelMap += "#..............#";
  levelMap += "#..........#...#";
  levelMap += "#..........#...#";
  levelMap += "#.......####...#";
  levelMap += "####.......#...#";
  levelMap += "#..........#...#";
  levelMap += "#..........#...#";
  levelMap += "#...#..........#";
  levelMap += "#...#..........#";
  levelMap += "#...#..........#";
  levelMap += "################";
}


void draw()
{
  background(0);
  
  move();
  
  
  
  for (int x = 0; x < fScale; x++)
    {
      // For each column, calculate the projected ray angle into world space
      float fRayAngle = (fPlayerA - fFOV/2.0f) + ((float)(x*nBlockWidth) / (float)width) * fFOV;

      // Find distance to wall
      float fStepSize = 0.1f;      // Increment size for ray casting, decrease to increase                    
      float fDistanceToWall = 0.0f; //                                      resolution

      boolean bHitWall = false;    // Set when ray hits wall block
      boolean bBoundary = false;    // Set when ray hits boundary between two wall blocks

      float fEyeX = sin(fRayAngle); // Unit vector for ray in player space
      float fEyeY = cos(fRayAngle);

      // Incrementally cast ray from player, along ray angle, testing for 
      // intersection with a block
      while (!bHitWall && fDistanceToWall < fDepth)
      {
        fDistanceToWall += fStepSize;
        int nTestX = (int)(fPlayerX + fEyeX * fDistanceToWall);
        int nTestY = (int)(fPlayerY + fEyeY * fDistanceToWall);
        
        // Test if ray is out of bounds
        if (nTestX < 0 || nTestX >= nMapWidth || nTestY < 0 || nTestY >= nMapHeight)
        {
          bHitWall = true;      // Just set distance to maximum depth
          fDistanceToWall = fDepth;
        }
        else
        {
          // Ray is inbounds so test to see if the ray cell is a wall block
          if (levelMap.charAt(nTestX * nMapWidth + nTestY) == '#')
          {
            // Ray has hit wall
            bHitWall = true;

            // To highlight tile boundaries, cast a ray from each corner
            // of the tile, to the player. The more coincident this ray
            // is to the rendering ray, the closer we are to a tile 
            // boundary, which we'll shade to add detail to the walls
            ArrayList<Pair> p = new ArrayList<Pair>();
            

            // Test each corner of hit tile, storing the distance from
            // the player, and the calculated dot product of the two rays
            for (int tx = 0; tx < 2; tx++)
              for (int ty = 0; ty < 2; ty++)
              {
                // Angle of corner to eye
                float vy = (float)nTestY + ty - fPlayerY;
                float vx = (float)nTestX + tx - fPlayerX;
                float d = sqrt(vx*vx + vy*vy); 
                float dot = (fEyeX * vx / d) + (fEyeY * vy / d);
                p.add(new Pair(d, dot));
              }

            // Sort Pairs from closest to farthest
            p = sortArrayList(p);
            
            // First two/three are closest (we will never see all four)
            float fBound = 0.01;
            if (acos(p.get(0).second) < fBound) bBoundary = true;
            if (acos(p.get(1).second) < fBound) bBoundary = true;
            //if (acos(p.get(2).second) < fBound) bBoundary = true;
          }
        }
      }
    
      // Calculate distance to ceiling and floor
      int nCeiling = (int)((float)(fScale/2.0) - fScale / ((float)fDistanceToWall));       
      int nFloor = fScale - nCeiling;

      // Shader walls based on distance
      color cShade;
      if (fDistanceToWall <= fDepth / 4.0f)      cShade = color(255,255,255);  // Very close  
      else if (fDistanceToWall < fDepth / 3.0f)    cShade = color(200,200,200);
      else if (fDistanceToWall < fDepth / 2.0f)    cShade = color(150,150,150);
      else if (fDistanceToWall < fDepth)        cShade = color(100,100,100);
      else                      cShade = color(0,0,0);    // Too far away

      if (bBoundary)    cShade = color(0,0,0); // Black it out
      
      for (int y = 0; y < fScale; y++)
      {
        // Each Row
        if(y <= nCeiling)
        {
          color cCeilingShade;
          float b = -1.0f * (((float)y - fScale/2.0f) / ((float)fScale / 2.0f));
          
          if (b < 0.25)    cCeilingShade = color(35,35,0);
          else if (b < 0.5)  cCeilingShade = color(50,50,0);
          else if (b < 0.75)  cCeilingShade = color(75,75,0);
          else if (b < 0.9)  cCeilingShade = color(90,90,0);
          else        cCeilingShade = color(105,105,0);
          
          fill(cCeilingShade);
          rect(x*(nBlockWidth+1), y*(nBlockHeight +1), nBlockWidth, nBlockHeight);  
        }
        else if(y > nCeiling && y <= nFloor)
        {
          fill(cShade);
          rect(x*(nBlockWidth+1), y*(nBlockHeight +1), nBlockWidth, nBlockHeight);  
        }
        else // Floor
        {        
          // Shade floor based on distance
          float b = 1.0f - (((float)y -fScale/2.0f) / ((float)fScale / 2.0f));
          if (b < 0.25)    cShade = color(0,255,255);
          else if (b < 0.5)  cShade = color(0,200,200);
          else if (b < 0.75)  cShade = color(0,150,150);
          else if (b < 0.9)  cShade = color(0,100,100);
          else        cShade = color(255,0,0);
          
          fill(cShade);
          rect(x*(nBlockWidth+1), y*(nBlockHeight +1), nBlockWidth, nBlockHeight);  
        }
      }
    }

    // Display Map
    for (int nx = 0; nx < nMapWidth; nx++)
      for (int ny = 0; ny < nMapWidth; ny++)
      {
        if(levelMap.charAt(ny * nMapWidth + nx) == '#')
          fill(255,0,0);
        if(levelMap.charAt(ny * nMapWidth + nx) == '.')
          fill(200,0,255); 
        rect(nx*(nBlockWidth+1), ny*(nBlockHeight +1), nBlockWidth, nBlockHeight);
      }
      
      if(nBlinkCounter >= frameRate/10 && nBlinkCounter < frameRate/ 1.5) // blinks the player
      {
        fill(0,255,0);
        rect( blockRound((fPlayerY/nMapHeight) * (nMapHeight * nBlockWidth)) , blockRound((fPlayerX/nMapWidth) * (nMapWidth * nBlockWidth)), nBlockWidth, nBlockHeight);        
      }
      else if(nBlinkCounter >= frameRate/1.5)
        nBlinkCounter = 0;
        
      nBlinkCounter++;
     
} // end draw()

 // round to the nearest block
 // inconsstent due to floating point rounding
int blockRound(float value)
{ 
   return round(value / (nBlockWidth+1)) * (nBlockWidth+1);
}

void keyPressed()
{
  if(keyCode == 'w' || keyCode == 'W')  bCurrentKeysPressed[0] = true;
  if(keyCode == 'a' || keyCode == 'A')  bCurrentKeysPressed[1] = true;
  if(keyCode == 's' || keyCode == 'S')  bCurrentKeysPressed[2] = true;
  if(keyCode == 'd' || keyCode == 'D')  bCurrentKeysPressed[3] = true;
}

void keyReleased()
{
  if(keyCode == 'w' || keyCode == 'W')  bCurrentKeysPressed[0] = false;
  if(keyCode == 'a' || keyCode == 'A')  bCurrentKeysPressed[1] = false;
  if(keyCode == 's' || keyCode == 'S')  bCurrentKeysPressed[2] = false;
  if(keyCode == 'd' || keyCode == 'D')  bCurrentKeysPressed[3] = false;
}

void move()
{
  // CCW Rotation
   if(bCurrentKeysPressed[1])
    fPlayerA -= (fSpeed * 0.75f) * (1.0f/frameRate);

  // CW Rotation
   if(bCurrentKeysPressed[3])
    fPlayerA += (fSpeed * 0.75f) * (1.0f/frameRate);
    
    // Handle Forwards movement & collision
    if(bCurrentKeysPressed[0])
    {
      fPlayerX += sin(fPlayerA) * fSpeed * (1.0f/frameRate);
      fPlayerY += cos(fPlayerA) * fSpeed * (1.0f/frameRate);
      if (levelMap.charAt((int)fPlayerX * nMapWidth + (int)fPlayerY) == '#')
      {
        fPlayerX -= sin(fPlayerA) * fSpeed * (1.0f/frameRate);
        fPlayerY -= cos(fPlayerA) * fSpeed * (1.0f/frameRate);
      }      
    }

    // Handle backwards movement & collision
    if(bCurrentKeysPressed[2])
    {
      fPlayerX -= sin(fPlayerA) * fSpeed * (1.0f/frameRate);
      fPlayerY -= cos(fPlayerA) * fSpeed * (1.0f/frameRate);
      if (levelMap.charAt((int)fPlayerX * nMapWidth + (int)fPlayerY) == '#')
      {
        fPlayerX += sin(fPlayerA) * fSpeed * (1.0f/frameRate);
        fPlayerY += cos(fPlayerA) * fSpeed * (1.0f/frameRate);
      }
    }
}



// sorts arrayList from smallest to largest
ArrayList<Pair> sortArrayList(ArrayList<Pair> input)     
{
  for(int i = 0; i < input.size(); i++)
  {
    for(int j = i; j < input.size(); j++)
    {
     if(input.get(i).first < input.get(j).first)
     {
       Pair temp = input.get(i);
       input.set(i, input.get(j));
       input.set(j, temp);
     }
    }
  }
  
  return input;
} // end sortArrayList()
