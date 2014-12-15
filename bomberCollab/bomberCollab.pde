String EVENT_PLAYER_INFO = "PLAYER";
String EVENT_BOMB = "BOMB";

int FRAME_RATE = 25;
int BOMBE_TIME = 3 * FRAME_RATE;
int MAP_SIZE = 19;
int EXPLODE_SIZE = 9;
int EXPLODE_TIME = round(0.3 * FRAME_RATE);

int DEAD_TIME = 9 * FRAME_RATE;
int deadWait = 0;
int SPRITE_SIZE;

Renderer renderer = new Renderer();

Player mePlayer = new Player();
HashMap<Integer, Player> otherPlayers = new HashMap<Integer, Player>();

void setup() {
  size(1000, 800);
  background(255);  
  frameRate(FRAME_RATE); 
  SPRITE_SIZE = (height-1)/MAP_SIZE;
}

void startGame() {
  do { 
    mePlayer.x = floor(random(MAP_SIZE));
    mePlayer.y = floor(random(MAP_SIZE));
  } 
  while (mePlayer.x%2 == 1 && mePlayer.y%2 == 1);
  mePlayer.alive = true;
  pushPlayerInfo(mePlayer);
}

void draw() {
  background(255);

  applyGameLogic();
  
  renderer.drawMap();
  renderer.drawPlayers();
  renderer.drawBombs();
  renderer.drawMessage();
}

void applyGameLogic() {
  //dead message
  if (!mePlayer.alive && !typeName) {
    message = "Start in "+floor(deadWait/FRAME_RATE)+"s";
    if (deadWait-- <= 0) {
      startGame();
      message = "";
    }
  }
	//other Bombs
  for (Player other : otherPlayers.values ()) {
    applyBombsLogic(other.bomb, false);
  }
  //mine bomb
  applyBombsLogic(mePlayer.bomb, true);
}

void applyBombsLogic(Bomb bomb, boolean isMePlayer) {
  if (bomb.timeLeft > 0 && !bomb.explode) {
    bomb.timeLeft--;
  } else if (bomb.timeLeft == 0 && !bomb.explode) { //pas encore explosé
    bomb.timeLeft = EXPLODE_TIME;
    bomb.explode = true;
    if (isMePlayer) {
      pushBombInfo(bomb);
    }
  } else if(bomb.timeLeft > 0 && bomb.explode) {
     explodePlayersAndBombs(bomb);
     bomb.timeLeft--;
  } else if (bomb.timeLeft == 0 && bomb.explode) { //fin explosion
    bomb.timeLeft = -1;    
  } 
}

void explodePlayersAndBombs(Bomb bomb) {
  explodeAPlayerAndBombs(mePlayer, bomb, true);  
  for (Player player : otherPlayers.values ()) {
    explodeAPlayerAndBombs(player, bomb, false);
  }
}

void explodeAPlayerAndBombs(Player player, Bomb bomb, boolean isMePlayer) {
  if (player.alive && isInRange(player.x, player.y, bomb.x, bomb.y, EXPLODE_SIZE)) {
    player.alive = false;
    if (isMePlayer) {
      deadWait = DEAD_TIME;
      pushPlayerInfo(mePlayer);
    }
  }
  Bomb otherBomb = player.bomb;
  if (!otherBomb.explode && isInRange(otherBomb.x, otherBomb.y, bomb.x, bomb.y, EXPLODE_SIZE)) {
      otherBomb.timeLeft = 0; //le bomb.explode sera passé à true par applyBombsLogic plus tard
  }
}


boolean isInRange(int x, int y, int bombX, int bombY, int size) {
  return (x%2==0 && x == bombX && abs(y - bombY) <= size)
    || (y%2==0 && y == bombY && abs(x - bombX) <= size);
}


void keyPressed() {
    //println(keyCode +" ("+RIGHT+","+DOWN+","+LEFT+","+UP+")");    
    if (mePlayer.alive) {
      //pas de gestion de collision hors blocs centraux
      if (keyCode == right && mePlayer.x<(MAP_SIZE-1) && mePlayer.y%2==0) {
        mePlayer.x++;
        pushPlayerInfo(mePlayer);
      } else if (keyCode == DOWN && mePlayer.y<(MAP_SIZE-1) && mePlayer.x%2==0) {
        mePlayer.y++;
        pushPlayerInfo(mePlayer);
      } else if (keyCode == left && mePlayer.x>0 && mePlayer.y%2==0) {
        mePlayer.x--;
        pushPlayerInfo(mePlayer && mePlayer.y>0 && mePlayer.x%2==0);
      } else if (keyCode == UP) {
        mePlayer.y--;
        pushPlayerInfo(mePlayer);
      } else if (keyCode == ENTER && mePlayer.bomb.timeLeft == -1 ) {
        Bomb bomb = mePlayer.bomb;
        bomb.x = mePlayer.x;
        bomb.y = mePlayer.y;
        bomb.timeLeft = BOMBE_TIME;
        pushBombInfo(bomb);
      }
    }
}

//********* Events Handler ***************************
void pushPlayerInfo(Player player) {
  String[] event = {
    //id, alive, x, y
    EVENT_PLAYER_INFO, str(player.id), str(player.alive),str(player.x), str(player.y))
    };
    pushEvent(event);
}

void pushBombInfo(Bomb bomb) {
  String[] event = {
    //playerId, x, y, timeLeft, explode
    EVENT_BOMB, str(bomb.playerId), str(bomb.x), str(bomb.y), str(bomb.timeLeft), str(bomb.explode)
    };
    pushEvent(event);
}


void receiveEvent(String[] event) {
  String eventType = event[0];
  if (eventType == EVENT_PLAYER_INFO) {
    //id, alive, x, y
    receivePlayerInfo(int(event[1]), Boolean(event[2]), int(event[3]), int(event[4]));
  } else if (eventType == EVENT_BOMB) {
    //playerId, x, y, timeLeft, explode
    receiveBombInfo(int(event[1]), int(event[2]), int(event[3]), int(event[4]), Boolean(event[5]));
  }
}

void receivePlayerInfo(int id, Boolean alive, int x, int y) {
  Player other = otherPlayers.get(id);
  if (other == null) {
    other = new Player();
    other.id = id;
    otherPlayers.put(other.id, other);
  }
  other.alive = alive;
  other.x = x;
  other.y = y;
}

void receiveBombInfo(int playerId, int x, int y, int timeLeft, boolean explode) {
  Player other = otherPlayers.get(playerId);
  if (other == null) {
    other = new Player();
    other.id = playerId;
    other.alive = true;
    other.x = x;
    other.y = y;
    otherPlayers.put(other.id, other);
  }
  Bomb bomb = other.bomb;
  bomb.x = x;
  bomb.y = y;
  bomb.timeLeft = timeLeft;
  bomb.explode = explode;
}

class Player {
  int id = int(random(65535));
  boolean alive = true;
  int x = -1;
  int y = -1; 
  Bomb bomb = new Bomb();
}

class Bomb {
  int x = -1;
  int y = -1;
  int timeLeft = -1;
  boolean explode = false;
}




