import processing.sound.*;

/* 
* Thanks to Javidx9 for his tutorial on programming Tetris, it was of great help - https://www.youtube.com/watch?v=8OK8_tHeCIA
*
* Sources for sound effects, music and textures: 
* Berusky 2 OST - Action Puzzle Game Soundtrack - https://opengameart.org/content/berusky-ii-ost-action-puzzle-game-soundtrack-23-tracks

* Thanks to MATTIX for these sound effects: 
* Click1.wav - https://freesound.org/people/MATTIX/sounds/348022/
* Click2.wav - https://freesound.org/people/MATTIX/sounds/349873/

* Source for the textures (which are currently disabled) - https://opengameart.org/content/8-bit-tetris
*/

String[] tetrominoes = new String[7];
int resX = 800;
int resY = 800;
int score = 0;
int secondsSinceStart = 1; // Seconds since pressing spacebar
float secondCounter = 0;
float pushDownTimer = 0;
float pushDownDelay = 1000; // Time between automatic pushdown of the falling piece
boolean gameOver = false;
boolean initialPause = true;
int minutsSinceStart = 0;
// menu
boolean menu = true;
boolean game = false;
boolean history = false;
boolean credits = false;

// Dificuldades
int facilDelay = 1000;
int medioDelay = 500;
int dificilDelay = 250;
int impossivelDelay = 100;
boolean isDifficultySelected = false;
int selectedDifficulty = -1; // -1 significa que nenhuma dificuldade foi selecionada
boolean instructions = false;

// PShape objects are used to render each different thing on screen
PShape boxShape;
PShape fillShape;
PShape mapFillerShape;
PShape bubbleShape;
PShape pauseTextBgShape;
PShape scoreTextBgShape;
PShape timerTextBgShape;
PImage icon;
PImage caveira;
PImage x;
PImage fogo;
PImage vignette;
PFont font;
PImage backgroundImage; // Variável global para a imagem de fundo

ArrayList<Integer> blocksToRemove = new ArrayList<Integer>();
float blockDissolveTimer = 0;

Sound sound;
SoundFile bgm;
SoundFile click1;
SoundFile click2;

void settings()
{
    size(resX, resY, P3D);
    PJOGL.setIcon("icon.png"); // Window icon for the game
    
}

void setup()
{        
    // Define the shape of the tetrominoes
    // Each X marks a tile of the shape
    tetrominoes[0] =  "--X-"; // First assignment needs to be "=" to replace the initial null value
    tetrominoes[0] += "--X-";
    tetrominoes[0] += "--X-";
    tetrominoes[0] += "--X-";
    
    tetrominoes[1] =  "--X-";
    tetrominoes[1] += "-XX-";
    tetrominoes[1] += "-X--";
    tetrominoes[1] += "----";
    
    tetrominoes[2] =  "-X--";
    tetrominoes[2] += "-XX-";
    tetrominoes[2] += "--X-";
    tetrominoes[2] += "----";
    
    tetrominoes[3] =  "----";
    tetrominoes[3] += "-XX-";
    tetrominoes[3] += "-XX-";
    tetrominoes[3] += "----";
    
    tetrominoes[4] =  "--X-";
    tetrominoes[4] += "-XX-";
    tetrominoes[4] += "--X-";
    tetrominoes[4] += "----";
    
    tetrominoes[5] =  "----";
    tetrominoes[5] += "-XX-";
    tetrominoes[5] += "--X-";
    tetrominoes[5] += "--X-";
    
    tetrominoes[6] =  "----";
    tetrominoes[6] += "-XX-";
    tetrominoes[6] += "-X--";
    tetrominoes[6] += "-X--";

    frameRate(60);
    ((PGraphicsOpenGL)g).textureSampling(3);

    // carregando a imagem de fundo

    backgroundImage = loadImage("data/tetris.png");

    // I'm using a bunch of shape objects because for some reason rect() doesn't work properly
    shapeMode(CORNER);
    boxShape = createShape(BOX, 32, 32, 1);
    fillShape = createShape(BOX, resX, resY, 1);
    mapFillerShape = createShape(BOX, 32, 32, 1);
    bubbleShape = createShape(SPHERE, 30);
    pauseTextBgShape = createShape(BOX, 200, 200, 1);
    scoreTextBgShape = createShape(BOX, 150, 40, 1);
    timerTextBgShape = createShape(BOX, 150, 40, 1);
    
    boxShape.setSpecular(color(0, 0, 0));
    boxShape.setAmbient(color(255, 255, 255));
    boxShape.setShininess(0);
    boxShape.setEmissive(0);
    
    pauseTextBgShape.setFill(color(0, 0, 0));
    pauseTextBgShape.setSpecular(color(0, 0, 0));
    pauseTextBgShape.setAmbient(color(0, 0, 0));
    pauseTextBgShape.setStroke(color(255, 255, 255));
    
    scoreTextBgShape.setFill(color(0, 0, 0));
    scoreTextBgShape.setSpecular(color(0, 0, 0));
    scoreTextBgShape.setAmbient(color(0, 0, 0));
    scoreTextBgShape.setStroke(color(255, 255, 255));
    
    timerTextBgShape.setFill(color(0, 0, 0));
    timerTextBgShape.setSpecular(color(0, 0, 0));
    timerTextBgShape.setAmbient(color(0, 0, 0));
    timerTextBgShape.setStroke(color(255, 255, 255));
    
    font = loadFont("Digital-7Mono-18.vlw");
    textFont(font);
    textAlign(CENTER, CENTER);
    
    fogo = loadImage("fire.png");
    caveira = loadImage("skull.png");
    x = loadImage("x.png");
    vignette = loadImage("vignette.png"); // For darkening the edges of the screen

    
    //textureMode(REPEAT);
    //sphereDetail(15);
    
    bgm = new SoundFile(this, "bgm.wav");
    click1 = new SoundFile(this, "click1.wav");
    click2 = new SoundFile(this, "click2.wav");
    
    // Some audio mixing so we don't blow anyone's ears up
    bgm.amp(0.1);
    click1.amp(0.8);
    click2.amp(0.4);
    sound = new Sound(this);
    sound.volume(0.7);
    
    createMap();
    getNewPiece();
}

void draw() {   
    if(menu)
        drawMainMenu();
    else if(game) {
        if(!isDifficultySelected)
            drawDifficultyMenu();
        else {
            update();
            drawBackground();

            if(pushDownDelay > medioDelay)
                drawBubbles();
            else if(pushDownDelay > dificilDelay)
                drawIcon(x);
            else if(pushDownDelay > impossivelDelay)
                drawIcon(fogo);
            else
                drawIcon(caveira);

            drawVignette();
            drawForeground();
            drawGhostPiece();
            drawFallingPiece();
            drawInterface();

            if(initialPause) 
                drawPauseScreen();
            if(gameOver) 
                drawGameOverScreen();
        }
    } 
    
    else if (history)
        drawHistoryMenu();
    else if (credits)
        drawCreditsMenu();
}

// Main gameplay logic loop - push the current piece down, check inputs and remove full rows if they exist
void update()
{
    //println(frameRate);
    
    if(!gameOver) 
    {
        
        if(!initialPause) 
        {
        
            if(millis() - secondCounter >= 1000)
            {
                secondsSinceStart++;
                secondCounter = millis();
            }
            
            // Remove rows of blocks if there are any to be removed
            if(blocksToRemove.size() > 0) 
            {
                dissolveBlocks();
                pushDownTimer = millis();
                return; // Pause until blocks have been removed
            }
            
            checkInputs();
            
            // If the falling piece wasn't manually pushed down by the player, push it down automatically after a delay
            // pushDownTimer is manipulated to control when or if the piece should be pushed down automatically
            if(millis() - pushDownTimer > pushDownDelay) 
            {
                
                if(checkIfPieceFits(currPieceX, currPieceY + 1, rotationState))
                {
                    currPieceY++;
                }
                else
                {
                    lockCurrPieceToMap(); 
                }
                
                pushDownTimer = millis();
            }
            
        }
        
    } 
    
}

// Checks for 10 blocks on each row
void checkForRows() 
{
    
    for(int y = 0; y < mapHeight - 1; y++)
    {
        int piecesInRow = 0;
        
        for(int x = 1; x < mapWidth - 1; x++)
        {
            
            if(map[y * mapWidth + x] != 0) piecesInRow++;
            
        }
        
        if(piecesInRow == 10) 
        {
            if(!click1.isPlaying()) click1.play();
            score += 100;
            
            for(int i = 1; i < mapWidth - 1; i++) 
            {
                blocksToRemove.add(y * mapWidth + i);
                blockDissolveTimer = millis();
            }
            
        }
        
    }

}

// Removes rows of blocks and moves all the tiles above down N amount of steps
// The basic logic:
// 1. Find the height for each row we need to remove
// 2. Start by removing the lowest row we need to remove
// 3. Displace all blocks above the rows we remove
// 4. How much we displace the blocks needs to be increased by 1 for each removed row below it
void dissolveBlocks() 
{
    int dissolveTime = 200;
    
    if(millis() - blockDissolveTimer > dissolveTime) 
    {
        int startHeight = (blocksToRemove.get(blocksToRemove.size() - 1) + 1) / mapWidth;

        ArrayList<Integer> rowsToRemoveHeights = new ArrayList<Integer>();
        
        for(int i = 0; i < blocksToRemove.size() / 10; i++) 
        {
            rowsToRemoveHeights.add((blocksToRemove.get(10 * i) + 1) / mapWidth);
        }
        
        int numRowsToDisplace = 0;
        
        for(int y = startHeight; y >= 0; y--)
        {
            boolean doDisplace = true;
            
            for(int j = 0; j < rowsToRemoveHeights.size(); j++) 
            {

                if(y == rowsToRemoveHeights.get(j)) 
                {
                    numRowsToDisplace++;
                    doDisplace = false;
                }
                
            }
            
            for(int x = 1; x < mapWidth - 1; x++)
            {
                
                if(doDisplace) 
                { 
                    map[(y + numRowsToDisplace) * mapWidth + x] = map[y * mapWidth + x];
                    tileColors[(y + numRowsToDisplace) * mapWidth + x] = tileColors[y * mapWidth + x];
                }
                
                map[y * mapWidth + x] = 0;
                tileColors[y * mapWidth + x] = color(0, 0, 0, 255);
            }
            
        }
        
        blocksToRemove.clear();
    }
    
}

// Locks the current piece as part of the map and checks the game over condition
void lockCurrPieceToMap() 
{
    click2.play();
    
    int blocksThatFit = 0;
    
    for(int y = 0; y < 4; y++) 
    {
    
        for(int x = 0; x < 4; x++) 
        {
            int pieceIndex = rotate(x, y, rotationState);
            
            if(tetrominoes[currPieceType].charAt(pieceIndex) == 'X') 
            {
                int mapIndex = (currPieceY + y) * mapWidth + (currPieceX + x);
                
                if(mapIndex >= 0) 
                {
                    map[mapIndex] = currPieceType + 2;
                    tileColors[mapIndex] = currPieceColor;
                    blocksThatFit++;
                }
                
            }
    
        }
    
    }
    
    if(blocksThatFit != 4)
    {
        gameOver = true;
    }
    
    if(!gameOver) 
    {
        checkForRows();
        updateGameSpeed();
        getNewPiece();
    }
    
}

// Check if the piece fits in the position it's trying to move into
boolean checkIfPieceFits(int movingToX, int movingToY, int rotation) 
{
    for(int y = 0; y < 4; y++) 
    {

        for(int x = 0; x < 4; x++) 
        {
            int pieceIndex = rotate(x, y, rotation);
            
            int mapIndex = (movingToY + y) * mapWidth + (movingToX + x);       
                  
            if(movingToX + x <= 0 || movingToX + x >= mapWidth - 1) 
            {  
                
                if(tetrominoes[currPieceType].charAt(pieceIndex) == 'X')
                {
                    return false;
                }
                
            }
               
            if(movingToX + x >= 0 && movingToX + x < mapWidth) 
            {
                
                if(movingToY + y >= 0 && movingToY + y < mapHeight) 
                {
    
                    if(tetrominoes[currPieceType].charAt(pieceIndex) == 'X' && map[mapIndex] != 0) 
                    {
                        return false;
                    }
                    
                }
                
            }
            
        }
        
    }
    
    return true;
}

// Instantly place the current piece at the lowest point directly below it
void placePieceDownInstantly() 
{
    int lastFitY = 0;
    
    for(int y = 0; y < mapHeight + 2; y++) 
    {
        
        if(checkIfPieceFits(currPieceX, currPieceY + y, rotationState))
        {
            lastFitY = currPieceY + y;
        }
        else
        {
            currPieceY = lastFitY;
            lockCurrPieceToMap();
            break;
        }
        
    }
    
}

// Changes speed of automatic pushdown according to time elapsed, somewhat in tune with the music
void updateGameSpeed()
{
 if(secondsSinceStart % 60 == 0)
 {
     pushDownDelay = pushDownDelay * 0.8;
 }   
}

// Thanks to Javidx9 for this algorithm - https://www.youtube.com/watch?v=8OK8_tHeCIA
int rotate(int rx, int ry, int rState) 
{
    
    switch(rState)
    {
        case 0:
            return ry * 4 + rx;
        case 1:
            return 12 + ry - (rx * 4);
        case 2:
            return 15 - (ry * 4) - rx;
        case 3:
            return 3 - ry + (rx * 4);
    }
    
    return 0;
}

void resetGameState() 
{
    createMap();
    getNewPiece();
    gameOver = false;
    initialPause = true;
    bgm.stop();
    secondsSinceStart = 0;
    secondCounter = millis();
    pushDownDelay = 1000;
    score = 0;
    isDifficultySelected = false; // Redefine a seleção de dificuldade
    game = false;
    menu = true;
}
void drawMainMenu() {
    pushMatrix();
    
    background(0);
     image(backgroundImage, 0, 0, width, height); // imagem de fundo do menu
    fill(255);
    // titulo
    textSize(50);
    textAlign(LEFT, TOP);
    text("TETRIS", 50, 65);
    // opcoes
    translate(700, 200);
    textSize(30);
    textAlign(CENTER, CENTER); 
    int mouseOverOption = getMouseOverOption(mouseY);
    for (int i = 0; i < 5; i++) {
        if (mouseOverOption == i) {
            fill(255, 0, 0); // Cor do seletor
            rectMode(CENTER);
            rect(0, 25 + (i * 50), 200, 40);
        }
        fill(255); // Cor do texto
        text(i == 0 ? "JOGAR" : i == 1 ? "HISTORIA" : i == 2 ? "CREDITOS" : i == 3 ? "Tutorial" : "SAIR", 0, 25 + (i * 50));    }
    popMatrix();
}

int getMouseOverOption(int mouseY) {
    // Ajuste nas condições para refletir a nova posição do texto e do retângulo
    if (mouseY >= 200 && mouseY < 250) return 0;
    else if (mouseY >= 250 && mouseY < 300) return 1;
    else if (mouseY >= 300 && mouseY < 350) return 2;
    else if (mouseY >= 350 && mouseY < 400) return 3;
    return -1;
}

void mousePressed() {
    if(menu) {
        if(mouseX > 500 && mouseX < 800) {
            if(mouseY > 200 && mouseY < 250) {
                menu = false;
                game = true;
                isDifficultySelected = false; // Garante que a seleção de dificuldade seja redefinida
            } 
            else if (mouseY >= 250 && mouseY < 280) {
                menu = false;
                history = true;
                game = false;
                //isDifficultySelected = false; // Garante que a seleção de dificuldade seja redefinida
            } 
            else if (mouseY >= 300 && mouseY < 330) {
                menu = false;
                credits = true;
                game = false;
                //isDifficultySelected = false; // Garante que a seleção de dificuldade seja redefinida
            }
            // Dentro de mousePressed(), adicione uma condição para verificar se a opção de instruções foi selecionada
            if (mouseY >= 350 && mouseY < 400) {
            instructions = true;
            menu = false;
} 
            else if (mouseY >= 400 && mouseY < 450) 
                exit();
        }
    }

    if(game) {
        selectDifficulty(mouseY);
    }
    if(instructions){
        drawInstructionsMenu();
    }

    if(history) {
        if(mouseX > width/2 - 50 && mouseX < width/2 + 50 && mouseY > height - 130 && mouseY < height - 90) {
            history = false;
            menu = true;
        }
    }

    if(credits) {
        if(mouseX > width/2 - 50 && mouseX < width/2 + 50 && mouseY > height - 100 && mouseY < height - 60) {
            credits = false;
            menu = true;
        }
    }
    // Dentro de mousePressed(), adicione uma condição para o botão "Voltar" no menu de instruções
    if (instructions && mouseX > width / 2 - 50 && mouseX < width / 2 + 50 && mouseY > height - 110 - 20 && mouseY < height - 110 + 20) {
    instructions = false;
    menu = true;
}
    if(isDifficultySelected) {
        // Calcula a posição central do botão "Voltar" no menu de dificuldades
        float btnX = width / 2 - 50; // Centro menos metade da largura do botão
        float btnY = height / 2 + 300 - 20; // Centro mais deslocamento para baixo menos metade da altura do botão

        // Verifica se o clique do mouse está dentro da área do botão "Voltar"
        if(mouseX > btnX && mouseX < btnX + 100 && mouseY > btnY && mouseY < btnY + 40) {
            isDifficultySelected = false;
            menu = true;
        }
    }
}

void drawDifficultyMenu() {
    pushMatrix();

    background(0);
    fill(255);
    textSize(32);
    textAlign(CENTER, CENTER);
    text("Selecione a Dificuldade:", width / 2, height / 3);
    
    // Desenha o seletor dinâmico
    translate(width / 2, height / 2);

    int mouseOverDifficulty = getMouseOverDifficulty(mouseY);
    for (int i = 0; i < 4; i++) {
        if (mouseOverDifficulty == i || selectedDifficulty == i) {
            fill(selectedDifficulty == i ? color(0, 255, 0) : color(255, 0, 0)); // Verde se selecionado, vermelho se apenas sobre
            rectMode(CENTER);
            rect(0, 0 + (i * 40), 290, 40);
        }
        fill(255); // Cor do texto
        if (i == 0) text("Facil - Bolhas", 0, 0);
        else if (i == 1) text("Medio - X", 0, 40);
        else if (i == 2)text("Dificil - Fogo", 0, 80);
        else text("Impossivel - Caveira", 0, 120);
    }
    // Botão de voltar
    translate(0, 300);
    // Verifica se o mouse está sobre o botão "Voltar"
    if(mouseX > width / 2 - 50 && mouseX < width / 2 + 50 && mouseY > height / 2 + 300 - 20 && mouseY < height / 2 + 300 + 20) {
        fill(255, 0, 0); // Cor do botão quando o mouse está sobre
    } else {
        fill(0); // Cor do botão quando o mouse não está sobre (cinza, por exemplo)
    }
    rectMode(CENTER);
    rect(0, 0, 100, 40); // Desenha o botão
    fill(255); // Cor do texto
    textAlign(CENTER, CENTER);
    text("Voltar", 0, 0); // Texto do botão
    popMatrix();
}

int getMouseOverDifficulty(int mouseY) {
    if (mouseY >= height / 2 && mouseY < height / 2 + 40) return 0;
    else if (mouseY >= height / 2 + 40 && mouseY < height / 2 + 80) return 1;
    else if (mouseY >= height / 2 + 80 && mouseY < height / 2 + 120) return 2;
    else if (mouseY >= height / 2 + 120) return 3;
    return -1;
}

void selectDifficulty(int mouseY) {
    int difficulty = getMouseOverDifficulty(mouseY);
    if (difficulty == 0) pushDownDelay = facilDelay;
    else if (difficulty == 1) pushDownDelay = medioDelay;
    else if (difficulty == 2) pushDownDelay = dificilDelay;
    else if(difficulty == 3) pushDownDelay = impossivelDelay;
    else return;
    selectedDifficulty = difficulty; // Atualiza a dificuldade selecionada
    isDifficultySelected = true;
}

void drawCreditsMenu() {
    pushMatrix();

    background(0);
    fill(255);
    textSize(25);
    textAlign(CENTER, CENTER);
    translate(width / 2, height / 4);
    text("Créditos", 0, 0);
    
    // Lista de nomes e RAs
    String[] nomes = {"Igor de Souza Bertelli", "Otavio Pereira Cardoso", "Carlos Eduardo de Lima Campos", "Felipe gaboardi Tralli"};
    String[] ras = {"RA 202121613", "RA 202318690", "RA 202235654", "RA 202104643"};
    
    for (int i = 0; i < nomes.length; i++) {
        text(nomes[i] + " - " + ras[i], 0, 70 + i * 30);
    }
    
    // Botão de voltar
    translate(0, 500);

    fill(255, 0, 0); // Cor do botão
    rectMode(CENTER);
    rect(0, 0, 100, 40); // Desenha o botão

    fill(255); // Cor do texto
    textAlign(CENTER, CENTER);
    text("Voltar", 0, 0); // Texto do botão

    popMatrix();
}

void drawHistoryMenu() {
    pushMatrix();

    background(0);
    fill(255);
    
    // titulo
    textSize(40);
    textAlign(CENTER, CENTER);
    text("Historia", width/2, 50);
    
    // texto
    textSize(25);
    textAlign(LEFT, TOP);
    String[] historia = {" No mundo pixelado de Tetrion, os Tetrominos, blocos magicos, viviam em harmonia ate que a Entropia, uma forca maligna, comecou a corrompe-los. "
                    + "Tetrion, um jovem Tetrite com a habilidade rara de manipular Tetrominos, foi escolhido para restaurar a ordem. ",
                    " Guiado pelo Sabio Bloco, Tetrion enfrentou desafios cada vez mais dificeis, onde os Tetrominos caiam mais rapido e de forma desordenada. "
                    + "Ele encontrou aliados valiosos, como Tetronius e Tetralina, que ajudaram com sabedoria e invenções. ",
                    " A cada linha completa de blocos, Tetrion liberava poderes magicos que purificavam os Tetrominos corrompidos. Apos muitos niveis desafiadores, ele confrontou a Entropia em uma batalha final epica. "
                    + "Usando todas as suas habilidades e a ajuda dos amigos, Tetrion organizou os Tetrominos perfeitamente, derrotando a Entropia e restaurando a paz. ",
                    " Tetrion foi aclamado como heroi, e a paz voltou a reinar em Tetrion. "
                    + "Sua historia se tornou uma lenda, inspirando futuras gerações a lutar pelo equilibrio e pela ordem no mundo pixelado."};
    
    float margin = 40;
    float x = margin;
    float y = 120;
    float maxWidth = width - 2 * margin;

    // escreve texto
    for(int i = 0; i < historia.length; i++) {
        String[] words = historia[i].split(" ");
        String line = "";

        for(String word : words) {
            String testLine = line + word + " ";
            
            if(textWidth(testLine) > maxWidth) {
                text(line, x, y);
                line = word + " ";
                y += 25;
            }
            else 
                line = testLine;
        }

        text(line, x, y); // escreve ultima linha

        x = margin; // reseta linha
        y += 35; // pula linha
    }

    // Botão de voltar
    translate(width/2, height - 110);

    fill(255, 0, 0); // Cor do botão
    rectMode(CENTER);
    rect(0, 0, 100, 40); // Desenha o botão

    fill(255); // Cor do texto
    textAlign(CENTER, CENTER);
    text("Voltar", 0, 0); // Texto do botão

    popMatrix();
}


void drawInstructionsMenu() {
    pushMatrix();

    background(0);
    fill(255);
    
    // titulo
    textSize(40);
    textAlign(CENTER, CENTER);
    text("Tutorial", width/2, 50);
    
    // texto
    textSize(25);
    textAlign(LEFT, TOP);
    String[] historia = {"A - Move o bloco para esquerda "
                    + "D - Move o bloco para direita ",
                    "S - Faz com que o bloco caia mais rápido "
                    + "Espaco - Faz com que o bloco caia instantaneamente",
                    "Tecla de seta para esquerda e direita rotacionam o bloco"
                    + "Tecla de esquerda rotaciona no sentido horario",
                    "Tecla da direita rotaciona no sentido anti-horario "
                    + "ESC - Fecha o jogo."};
    
    float margin = 40;
    float x = margin;
    float y = 120;
    float maxWidth = width - 2 * margin;

    // escreve texto
    for(int i = 0; i < historia.length; i++) {
        String[] words = historia[i].split(" ");
        String line = "";

        for(String word : words) {
            String testLine = line + word + " ";
            
            if(textWidth(testLine) > maxWidth) {
                text(line, x, y);
                line = word + " ";
                y += 25;
            }
            else 
                line = testLine;
        }

        text(line, x, y); // escreve ultima linha

        x = margin; // reseta linha
        y += 35; // pula linha
    }

    // Botão de voltar
    translate(width/2, height - 110);

    fill(255, 0, 0); // Cor do botão
    rectMode(CENTER);
    rect(0, 0, 100, 40); // Desenha o botão

    fill(255); // Cor do texto
    textAlign(CENTER, CENTER);
    text("Voltar", 0, 0); // Texto do botão

    popMatrix();
}
