String EVENT_PLAYER = "PLAYER";
String EVENT_BOMB = "BOMB";

int FRAME_RATE = 25;
int BOMB_TIME = 3 * FRAME_RATE; //3s avant explosion
int DEAD_TIME = 5 * FRAME_RATE; //5s après un frag

int CELL_PX = 40; //taille d'une cellule en pixel
int GRID_SIZE = 19; //nombre de case de la grille (impaire) (coord : 0 à 19)

int EXPLODING_TIME = round(0.3 * FRAME_RATE); // 0.3s durée de l'explosion

int deadWait = 0; //durée d'attente si mort
String message = ""; //message à afficher

Player selfPlayer; //joueur local
ArrayList<Player> players = new ArrayList<Player>(); //tous les joueurs

Bomb selfBomb; //Bombe du joueur local
ArrayList<Bomb> bombs = new ArrayList<Bomb>(); //toutes les bombes

class Player {
  int id = int(random(65535)); //pour le multi
  boolean alive = true;
  int col = -1;
  int row = -1;
}

class Bomb {
  int id = -1; //pour le multi
  boolean alive = false;
  int col = -1;
  int row = -1;
  int timeLeft = -1;
  boolean exploding = false;
}

void setup() {
  size(800, 800);
  background(255);  
  frameRate(FRAME_RATE); 
  CELL_PX = (height-1)/GRID_SIZE;

  selfPlayer = new Player();
  players.add(selfPlayer); //on s'ajoute dans la liste des joueurs

  selfBomb = new Bomb();
  selfBomb.id = selfPlayer.id; //Bombe du joueur local
  bombs.add(selfBomb);

  //On lance le jeu
  initSelfPlayer();
}

void initSelfPlayer() {
  //On initialise le joueur et on le remet en vie
  selfPlayer.col = 0;
  selfPlayer.row = 0;
  selfPlayer.alive = true;
  sendSelfPlayer(); //envoi websocket
}

void draw() {
  background(255);

  applyGameLogic();

  drawGrid();
  drawPlayers();
  drawBombs();
  drawMessage();
}

void applyGameLogic() {
  //dead message
  if (!selfPlayer.alive) { //si on est mort, on attend deadWait
    message = "Start in "+floor(deadWait/FRAME_RATE)+"s";
    if (deadWait-- <= 0) {
      initSelfPlayer(); //remet le joueur en vie et en 0,0
      message = "";
    }
  }

  //traite ma bombe
  applyBombLogic(selfBomb); //gere la cinematique que ma bombe : 1-decompte, 2-explosion, 3-durée explosion, 4-fin de l'explosion

  //on vérifie les bombes qui ont explosées
  for (Bomb bomb : bombs) {
    if (bomb.alive && bomb.exploding) { //une bombe qui est en train d'exploser
      //on vérifie si elle touche le joueur ou sa bombe
      if (selfPlayer.alive) {
        explodingSelfPlayer(bomb);
      }
      if (selfBomb.alive) {
        explodingSelfBomb(bomb);
      }
    }
  }
}

void applyBombLogic(Bomb bomb) {
  if (bomb.alive) {
    if (!bomb.exploding) { //pas encore explosée
      if (bomb.timeLeft > 0) { //décompte de la bombe
        bomb.timeLeft--;
      } else if (bomb.timeLeft == 0) { //explosion
        bomb.timeLeft = EXPLODING_TIME; //on reinitialise le decompte à la durée de l'explosion
        bomb.exploding = true;
        sendSelfBomb(); //websocket
      }
    } else { //bombe en cours d'explosion
      if (bomb.timeLeft > 0) { //décompte de l'explosion
        bomb.timeLeft--;
      } else if (bomb.timeLeft == 0) { //fin explosion
        bomb.timeLeft = -1;
        bomb.exploding = false; //on retire la bombe
        bomb.alive = false; //on retire la bombe
        sendSelfBomb(); //websocket
      }
    }
  }
}

void explodingSelfPlayer(Bomb explodingdBomb) {
  if (isInRange(selfPlayer.col, selfPlayer.row, explodingdBomb.col, explodingdBomb.row)) { //sur le chemin de l'explosion
    selfPlayer.alive = false;
    deadWait = DEAD_TIME; //On est mort on attend DEAD_TIME
    sendSelfPlayer();
  }
}

void explodingSelfBomb(Bomb explodingdBomb) {  
  if (!selfBomb.exploding //une bombe pas encore explosée
  && isInRange(selfBomb.col, selfBomb.row, explodingdBomb.col, explodingdBomb.row)) { //sur le chemin de l'explosion
    selfBomb.timeLeft = 0; //le bomb.exploding sera passé à true par applyBombsLogic plus tard
  }
}


boolean isInRange(int col, int row, int bombCol, int bombRow) {
  return (col%2==0 && col == bombCol) // sur la même colonne et pas de bloc
    || (row%2==0 && row == bombRow); // sur la même ligne et pas de bloc
}


void keyPressed() {
  //println(keyCode +" ("+RIGHT+","+DOWN+","+LEFT+","+UP+")");    
  if (selfPlayer.alive) { 
    //pas de gestion de collision hors blocs centraux
    if (keyCode == RIGHT && selfPlayer.col<(GRID_SIZE-1) && selfPlayer.row%2==0) {
      selfPlayer.col++;
      sendSelfPlayer();
    } else if (keyCode == DOWN && selfPlayer.row<(GRID_SIZE-1) && selfPlayer.col%2==0) {
      selfPlayer.row++;
      sendSelfPlayer();
    } else if (keyCode == LEFT && selfPlayer.col>0 && selfPlayer.row%2==0) {
      selfPlayer.col--;
      sendSelfPlayer();
    } else if (keyCode == UP && selfPlayer.row>0 && selfPlayer.col%2==0) {
      selfPlayer.row--;
      sendSelfPlayer();
    } else if (keyCode == ENTER /*&& !selfBomb.alive*/ ) {
      selfBomb.col = selfPlayer.col;
      selfBomb.row = selfPlayer.row;
      selfBomb.timeLeft = BOMB_TIME;
      selfBomb.alive = true;
      sendSelfBomb();
    }
  }
}

//********* Events Handler ***************************
void sendSelfPlayer() {
  String[] event = {
    //id, alive, col, row
    EVENT_PLAYER, str(selfPlayer.id), str(selfPlayer.alive), str(selfPlayer.col), str(selfPlayer.row)
    };
    pushEvent(event);
}

void sendSelfBomb() {
  String[] event = {
    //playerId, col, row, timeLeft, exploding
    EVENT_BOMB, str(selfBomb.id), str(selfBomb.alive), str(selfBomb.col), str(selfBomb.row), str(selfBomb.timeLeft), str(selfBomb.exploding)
    };
    pushEvent(event);
}


void receiveEvent(String[] event) { //routage et typage, fonction du type: PLAYER ou BOMB
  String eventType = event[0];
  if (eventType == EVENT_PLAYER) {
    //id, alive, x, y
    receivePlayer(int(event[1]), boolean(event[2]), int(event[3]), int(event[4]));
  } else if (eventType == EVENT_BOMB) {
    //id, alive, x, y, timeLeft, exploding
    receiveBomb(int(event[1]), boolean(event[2]), int(event[3]), int(event[4]), int(event[5]), boolean(event[6]));
  }
}

void receivePlayer(int id, boolean alive, int col, int row) {
  Player other = getPlayer(id);
  if (other == null) {//connexion d'un nouveau joueur 
    other = new Player();
    other.id = id;
    players.add(other);
  }
  other.alive = alive;
  other.col = col;
  other.row = row;
}

Player getPlayer(int playerId) {
  for (Player player : players) {
    if (player.id == playerId) {
      return player;
    }
  }
  return null; //si pas trouvé on retourne null
}


void receiveBomb(int id, boolean alive, int col, int row, int timeLeft, boolean exploding) {
  Bomb bomb = getBomb(id);
  if (bomb == null) {//reception d'une nouvelle Bomb 
    bomb = new Bomb();
    bomb.id = id;
    bombs.add(bomb);
  }
  bomb.alive = alive;
  bomb.col = col;
  bomb.row = row;
  bomb.timeLeft = timeLeft;
  bomb.exploding = exploding;
}

Bomb getBomb(int bombId) {
  for (Bomb bomb : bombs) {
    if (bomb.id == bombId) {
      return bomb;
    }
  }
  return null; //si pas trouvé on retourne null
}



//------------------------------------------------------------------------------------------
// Renderer
//------------------------------------------------------------------------------------------
void drawGrid() {
  fill(255); //fond blanc
  stroke(20);
  strokeWeight(5);
  rect(0, 0, height-2, height-2); //cadre tout autour
  noStroke();
  fill(130); //gris clair
  for (int i = 1; i < GRID_SIZE; i+=2) { //de 2 en 2 on trace les blocs
    for (int j = 1; j < GRID_SIZE; j+=2) {
      rect(i*CELL_PX, j*CELL_PX, CELL_PX, CELL_PX); //rect( positionCoinX,positionCoinY,tailleX, tailleY)
    }
  }
}

void drawMessage() {
  if (message != "") {
    fill(255, 150);
    rect(0, 0, width, height);
    fill(20); //couleur du text
    textSize(32);
    text(message, width/2, height/2);
  }
}

void drawPlayers() {  
  for (Player player : players) {
    drawPlayer(player);
  }
}

void drawPlayer(Player player) {
  if (player == selfPlayer) {
    fill(50, 50, 220); //self : bleu
  } else {
    fill(220, 20, 20);  //other : rouge
  }
  //dessine un joueur : cercle de couleur entouré de gris
  stroke(80);
  strokeWeight(2); 
  ellipse(colToCenterX(player.col), rowToCenterY(player.row), CELL_PX, CELL_PX);
  if (!player.alive) {
    line(colToCenterX(player.col)-20, rowToCenterY(player.row)-20, colToCenterX(player.col)+20, rowToCenterY(player.row)+20);
  }
}

void drawBombs() {
  for (Bomb bomb : bombs) {
    if (bomb.alive) {
      if (!bomb.exploding) {
        drawBomb(bomb);
      } else {
        drawExplosion(bomb);
      }
    }
  }
}

void drawBomb(Bomb bomb) {
  //dessine une bombe : cercle gris foncé
  fill(20); //gris foncé
  ellipse(colToCenterX(bomb.col), rowToCenterY(bomb.row), CELL_PX, CELL_PX); //default mode : CENTER
}

void drawExplosion(Bomb bomb) {
  //dessine une explosion : deux rectangles : 1 horizontal + 1 vertical (depends des blocs) 
  fill(250, 250, 20); //jaune
  if (bomb.col%2==0) {
    rect(bomb.col*CELL_PX, 0, CELL_PX, height);
  }
  if (bomb.row%2==0) {
    rect(0, bomb.row*CELL_PX, width, CELL_PX);
  }
}

int colToCenterX(int col) {
  return col*CELL_PX+CELL_PX/2;
}

int rowToCenterY(int raw) {
  return raw*CELL_PX+CELL_PX/2;
}

