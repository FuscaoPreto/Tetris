int mapWidth = 12;
int mapHeight = 21;
int[] map = new int[mapWidth * mapHeight];
int tileWidth = 32;
int tileHeight = 32;

color[] targetBgColors = 
{ 
    color(38, 35, 137),
    color(165, 64, 53),
    color(110, 0, 69)
};

color backgroundColor = targetBgColors[0];
color[] tileColors = new color[mapWidth * mapHeight];
int targetColorIndex = 0;
boolean changeTargetNextFrame = false;
boolean waitedSomeFrames = false;
int bgChangeFrameCounter = 0;

PVector[] bubbles = new PVector[20];
float[] bubbleSpeed = new float[bubbles.length];
PVector[] bubblesNoise = new PVector[bubbles.length];


void createMap() 
{
    targetColorIndex = int(random(0, targetBgColors.length));
    
    //Borda
    for(int y = 0; y < mapHeight; y++) 
    {
        
        for(int x = 0; x < mapWidth; x++)
        {
                
            if(x == 0 || x == mapWidth - 1 || y == mapHeight - 1) 
            {
                map[y * mapWidth + x] = 1;
                continue;
            }
            
            map[y * mapWidth + x] = 0;
        }
        
    }
    
    //Cor dos tijolos
    for(int y = 0; y < mapHeight; y++) 
    {
        
        for(int x = 0; x < mapWidth; x++)
        {
            tileColors[y * mapWidth + x] = color(0, 0, 0, 255);
        }
        
    }
    
    //Bolhas
    for(int i = 0; i < bubbles.length; i++) 
    {
        bubbles[i] = new PVector(random(resX, resX + resX), random(resY, resY + resY), random(-100, -40));
        bubbleSpeed[i] = random(1.0, 4.0);
        bubblesNoise[i] = new PVector(random(-100, 100), random(-100, 100));
    }
    
}

void drawVignette()
{
    pushMatrix();
    translate(resX/2, resY/2);
    fillShape.setTexture(vignette);
    shape(fillShape);
    popMatrix();
}

void drawBubbles()
{   
    
    if(initialPause || gameOver) return;
    
    pushMatrix();
    ambientLight(255, 255, 255);
    lightSpecular(255, 255, 255);
    directionalLight(0, 0, 0, -1, 0, 0.5);
    directionalLight(0, 0, 0, 1, 0, 0.5);
    lightSpecular(255, 0, 0);
    directionalLight(0, 0, 0, -0.25, 0.5, -0.5);
    lightSpecular(255, 0, 0);
    directionalLight(0, 0, 0, 0.5, -0.75, -0.5);
    lightSpecular(0, 255, 0);
    directionalLight(0, 0, 0, 1, 0.25, 0.5);
    directionalLight(0, 0, 0, -1, 0.25, 0.5);
    bubbleShape.setStroke(0);
    bubbleShape.setFill(color(red(backgroundColor), green(backgroundColor), blue(backgroundColor), 50));
    bubbleShape.setShininess(300);
    bubbleShape.setAmbient(0);
    bubbleShape.setSpecular(color(255, 255, 255));
    
    for(int i = 0; i < bubbles.length; i++) 
    {
        pushMatrix();
        
        if(bubbles[i].x < -70 || bubbles[i].y < -70)
        {
            bubbles[i].set(random(resX, resX + resX), random(resY, resY + resY), random(-100, -40));
        }
        
        translate(bubbles[i].x, bubbles[i].y, bubbles[i].z);
        shape(bubbleShape);
        bubbles[i] = bubbles[i].add(-abs(noise(bubblesNoise[i].x) * bubbleSpeed[i]), -abs(noise(bubblesNoise[i].y) * bubbleSpeed[i]));
        popMatrix();
        bubblesNoise[i].x += random(0.001, 0.05);
        bubblesNoise[i].y += random(0.05, 0.1);
    }
    
    popMatrix();
}

void drawBackground()
{   
    background(backgroundColor);
    gradualChangeTo(targetBgColors[targetColorIndex]);
}
    
void drawForeground()
{
    pushMatrix();
    translate(resX/2 - ((tileWidth * mapWidth) / 2), 68);
    translate(tileWidth/2, tileHeight/2);
    
    for(int y = 0; y < mapHeight; y++) 
    {
        
        for(int x = 0; x < mapWidth; x++) 
        {
            
            if(map[y * mapWidth + x] == 0) 
            {
                mapFillerShape.setStroke(color(0, 0, 0, 255));
                mapFillerShape.setFill(color(100, 100, 100, 100));
                shape(mapFillerShape);
            } 
            else 
            {
                push();
                boxShape.setStroke(color(0, 0, 0, 255));
                boxShape.setStrokeWeight(4);
                
                if(map[y * mapWidth + x] == 1) 
                {
                    boxShape.setFill(color(0, 0, 0, 255));
                } 
                else
                {
                    boxShape.setFill(tileColors[y * mapWidth + x]);
                }
                
                if(blocksToRemove.size() > 0) 
                {
                    
                    for(int j = 0; j < blocksToRemove.size(); j++)
                    {
                        
                        if((y * mapWidth + x) == blocksToRemove.get(j)) 
                        {
                            color curTileColor = tileColors[y * mapWidth + x];
                            curTileColor += (cos(curTileColor) * 3.14 * (2.71 - curTileColor) + (curTileColor * 4.66)) * 0.0001; 

                            boxShape.setFill(curTileColor);
                            tileColors[y * mapWidth + x] = curTileColor;
                        }
                        
                    }
                    
                }
                
                shape(boxShape);
                pop();
            }
            
            translate(tileWidth, 0);
        }
        
        translate(0, tileHeight);
        translate(-(tileWidth * mapWidth), 0);
    }
    
    popMatrix();
}

void gradualChangeTo(color targetColor)
{
    int changeSpeed = 10;
    int dr = 0;
    int dg = 0;
    int db = 0;
    
    if(changeTargetNextFrame) 
    {
        targetColorIndex = int(random(0, targetBgColors.length));
        changeTargetNextFrame = false;
    } 
    else if(waitedSomeFrames)
    {
        dr = (red(targetColor) > red(backgroundColor)) ? 1 : (red(targetColor) == red(backgroundColor) ? 0 : -1);
        dg = (green(targetColor) > green(backgroundColor)) ? 1 : (green(targetColor) == green(backgroundColor) ? 0 : -1);
        db = (blue(targetColor) > blue(backgroundColor)) ? 1 : (blue(targetColor) == blue(backgroundColor) ? 0 : -1);
        
        if(backgroundColor == targetColor)
        {
            changeTargetNextFrame = true;
        }
        
        backgroundColor = color(red(backgroundColor) + dr, green(backgroundColor) + dg, blue(backgroundColor) + db);
        
        waitedSomeFrames = false;
        bgChangeFrameCounter = 0;
    } 
    else
    {
        
        if(bgChangeFrameCounter > changeSpeed) 
        {
            waitedSomeFrames = true;
        } 
        else 
        {
            bgChangeFrameCounter++;
        }
        
    }
  
}

void drawPauseScreen()
{
    pushMatrix();
    translate(resX/2 - ((tileWidth) / 2), resY / 2 - (tileHeight * 3), 50);
    translate(tileWidth/2, tileHeight/2);
    shape(pauseTextBgShape);
    text("Press space to start", 0, 0, 51);
    popMatrix();
}

void drawGameOverScreen()
{
    pushMatrix();
    translate(resX/2 - ((tileWidth) / 2), resY / 2 - (tileHeight * 3), 50);
    translate(tileWidth/2, tileHeight/2);
    shape(pauseTextBgShape);
    push();
    fill(200, 0, 0);
    textSize(30);
    text("GAME OVER!", 0, -10, 51);
    fill(255, 255, 255);
    textSize(15);
    text("Aperte Espaco para continuar", -2, 30, 51);
    pop();
    popMatrix();
}

void drawInterface() 
{
    pushMatrix();
    
    translate(resX/2 - (tileWidth * 9), 72);
    translate(tileWidth/2, tileHeight/2);
    shape(scoreTextBgShape);
    
    push();
    text("Pontos", 20, -5, 51);
    textAlign(RIGHT);
    textSize(20);
    text("" + score, 80, 28, 51);
    pop();
    
    popMatrix();
    
    pushMatrix();
    
    translate(resX/2 + (tileWidth * 8), 72);
    translate(tileWidth/2, tileHeight/2);
    shape(timerTextBgShape);
    
    push();
    text("Tempo", -20, -5, 51);
    textSize(20);
    textAlign(LEFT);
    text("" + secondsSinceStart, -80, 28, 51);
    pop();
    
    popMatrix();
}
    
void drawIcon(PImage icon) {
    if(initialPause || gameOver) return;

    // Defina o tamanho desejado para os ícones
    float iconWidth = 64;
    float iconHeight = 64;

    for(int i = 0; i < bubbles.length; i++) {
        pushMatrix();

        if(bubbles[i].x < -70 || bubbles[i].y < -70) {
            bubbles[i].set(random(resX, resX + resX), random(resY, resY + resY), random(-100, -40));
        }

        translate(bubbles[i].x, bubbles[i].y, bubbles[i].z);
        image(icon, 0, 0, iconWidth, iconHeight); // Desenhe o ícone na posição atual com o tamanho especificado
        bubbles[i] = bubbles[i].add(-abs(noise(bubblesNoise[i].x) * bubbleSpeed[i]), -abs(noise(bubblesNoise[i].y) * bubbleSpeed[i]));

        popMatrix();
        bubblesNoise[i].x += random(0.001, 0.05);
        bubblesNoise[i].y += random(0.05, 0.1);
    }
}
