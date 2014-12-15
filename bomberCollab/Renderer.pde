class Renderer {


  void drawMap() {
    noFill();
    stroke(20);
    strokeWeight(5);
    rect(0, 0, height-2, height-2);
		noStroke();
    for (int i = 1; i < MAP_SIZE; i+=2) {
      for (int j = 1; j < MAP_SIZE; j+=2) {
        fill(170);
        rect(i*SPRITE_SIZE, j*SPRITE_SIZE, SPRITE_SIZE, SPRITE_SIZE);       
      }
    }

    /*stroke(120);
     strokeWeight(2);
     for(int i = 0; i < MAP_SIZE+1; i++) {
     line(0, i*SPRITE_SIZE, height, i*SPRITE_SIZE);
     } 
     for(int i = 0; i < MAP_SIZE+1; i++) {
     line(i*SPRITE_SIZE,0, i*SPRITE_SIZE, height);
     }*/
  }

  void drawMessage() {
    fill(20);
    textSize(32);
    textAlign(CENTER, CENTER);
    textLeading(2*SPRITE_SIZE);
    text(message, SPRITE_SIZE*MAP_SIZE/2, 4*SPRITE_SIZE+SPRITE_SIZE/2);
  }
  
  void drawPlayers() {  
    for (Player other : otherPlayers.values ()) {
      fill(220, 20, 20);      
      drawAPlayer(other);
    }
    fill(50, 50, 220);
    drawAPlayer(mePlayer);
  }

  void drawAPlayer(Player player) {
    stroke(80);
    strokeWeight(2);
    int centerX = player.x*SPRITE_SIZE+SPRITE_SIZE/2;
    int centerY = player.y*SPRITE_SIZE+SPRITE_SIZE/2;
    ellipse(centerX, centerY, SPRITE_SIZE, SPRITE_SIZE);

    if (!player.alive) {
      stroke(40);
      line(centerX-SPRITE_SIZE*0.3, centerY, centerX-SPRITE_SIZE*0.1, centerY-SPRITE_SIZE*0.2);
      line(centerX-SPRITE_SIZE*0.3, centerY-SPRITE_SIZE*0.2, centerX-SPRITE_SIZE*0.1, centerY);
      line(centerX+SPRITE_SIZE*0.3, centerY, centerX+SPRITE_SIZE*0.1, centerY-SPRITE_SIZE*0.2);
      line(centerX+SPRITE_SIZE*0.3, centerY-SPRITE_SIZE*0.2, centerX+SPRITE_SIZE*0.1, centerY);
    }
  }

  void drawBombs() {
    for (Player other : otherPlayers.values ()) {
      if (!other.bomb.explode) {
        drawABomb(other.bomb);
      } else {
        drawAExplosion(other.bomb);
      }
    }
    if (!mePlayer.bomb.explode) {
      drawABomb(mePlayer.bomb);
    } else {
      drawAExplosion(mePlayer.bomb);
    }
  }

  void drawABomb(Bomb bomb) {
    stroke(80);
    strokeWeight(2);
    int centerX = bomb.x*SPRITE_SIZE+SPRITE_SIZE/2;
    int centerY = bomb.y*SPRITE_SIZE+SPRITE_SIZE/2;
    float timedCoef = bomb.timeLeft%(FRAME_RATE/2);
    fill(20);
    ellipse(centerX, centerY, 
    SPRITE_SIZE*0.9-(12f/FRAME_RATE)*timedCoef, 
    SPRITE_SIZE*0.9-(12f/FRAME_RATE)*timedCoef);
  }

  void drawAExplosion(Bomb bomb) {
    float timedCoef = (1-0.8*float(bomb.timeLeft)/EXPLODE_TIME)*0.8;  
    stroke(250, 200, 20);
    strokeWeight(4);
    fill(250, 250, 20);
    rectMode(CENTER);
    if (bomb.x%2==0) {
      rect(bomb.x*SPRITE_SIZE+SPRITE_SIZE/2, bomb.y*SPRITE_SIZE+SPRITE_SIZE/2, SPRITE_SIZE*timedCoef, SPRITE_SIZE*(1+EXPLODE_SIZE*2), SPRITE_SIZE/3);
    }
    if (bomb.y%2==0) {
      rect(bomb.x*SPRITE_SIZE+SPRITE_SIZE/2, bomb.y*SPRITE_SIZE+SPRITE_SIZE/2, SPRITE_SIZE*(1+EXPLODE_SIZE*2), SPRITE_SIZE*timedCoef, SPRITE_SIZE/3);
    }
   }
}

