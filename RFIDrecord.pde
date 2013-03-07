//Inessah Selditz: Code for Fall 2011 ICM and Pcomp final

//rfid_v2- getting the minim code in the rfid code
//v5: adding second mp3; 0.0002 seems to be the trigger level- calibrated the record 
//got trigger level
//got gradient background png in
//v8 gradient rotate
//v9 got random (r,g,b,a) values in triangles

PImage a; // Declare variable "a" of type PImage
PImage b; 
PImage c; // background 
PImage d; //clouds

Flock flock;
import processing.serial.*;
Serial myPort; // Create object from Serial classB
int val; // Data received from the serial port
String tagID = "";
int state = -1;

import ddf.minim.*;
Minim minim;
AudioInput in;
AudioPlayer player;
AudioPlayer player2;
boolean playing = false;
int rAngle = 30;
float curr_angle = 0;

//Cube array
float[][] distances;
float maxDistance;
int spacer = 45;

//-----------------------setup-----------------------//

void setup() 
{
  // Cube array
  maxDistance = dist(width/2, height/2, width, height);
  distances = new float[width][height];
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float dist = dist(width/2, height/2, x, y);
      distances[x][y] = dist/maxDistance * 255;
    }
  }
  // noLoop();  // Run once and stop

  size(1000, 1000, P3D);
  smooth();
  frameRate(30);

  flock = new Flock();
  for (int i = 0; i < 90; i++) {
    // first number = max speed, second number = max force
    //flock.addBoid(new Boid(new PVector(width/2,height/2), 8.0, 0.5));
    flock.addBoid(new Boid(new PVector(width/2, height/2), 8.0, 0.5));
  }

  // Load the images into the program  
  a = loadImage("mask_v4.png"); 
  b = loadImage("Label_v6.png");
  c = loadImage("Record2.png");
  d = loadImage("cloud1.png");
  c.resize(width, height);
  c.updatePixels();

  minim = new Minim(this);
  minim.debugOn();
  player = minim.loadFile("Record_player_loop.mp3", 2048);
  player2 = minim.loadFile("make.mp3", 2048);

  in = minim.getLineIn(Minim.STEREO, 512);
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  myPort.buffer(16);
}

//-----------------------draw-----------------------//
boolean spike = false;

void draw()
{
  background(255, 55, 102);
  pushMatrix();
  translate(width/2, height/2);
  rotate(radians(rAngle));
  imageMode(CENTER);
  if (state == 1) {
    image(c, 0, 0);  //Background gradient image
    fill(255, 55, 102);
    noStroke(); 
    ellipse(0, 0, 314, 314);
  }

  if (state == 2) {
    image(d, 0, 0);  //Background cloud image
    fill(231, 255, 0);
    noStroke(); 
    ellipse(0, 0, 314, 314);
  }

  float sampleTotal = 0;
  for (int i = 0; i < in.bufferSize() - 1; i++)
  {
    sampleTotal+=abs(in.right.get(i));
  }

  //KEEP print line
  //println("sampleTotal: " + sampleTotal);
  float sampleAverage = sampleTotal/512;
  //println("average buffer: " + sampleAverage);
  //println(sampleAverage + " " + playing);
  //println("spike? " + spike);
  //previous sampleAverage = .0003, but changed it to 0.003 for circular tags and new record player

  if (sampleAverage>0.0060 && !spike) { //was 0.0016
    playing = !playing;
    spike = true;
    player.pause();
    player2.pause();
    player.rewind();
    player2.rewind();
  } 
  //  else {
  //    spike = false;
  //  }
  popMatrix();

  //Record 1: graphics
  if ((state == 1) && playing) {//0.0002 seems to be the trigger level
    //graphics go here
    rAngle+=3;
    flock.run();
    //graphics end here
    if (!player.isPlaying()) {
      player.play();
    }
  }
  // Pop matrix goes down here for flock to rotate
  //popMatrix();

  //Record 2: graphics
  if ((state == 2) && playing) {
    rAngle+=3;
    player2.play();
    if (!player.isPlaying()) {
      player2.play();
      pushMatrix();
      translate(0, 0);
      for (int y = 0; y < height; y += spacer) {
        for (int x = 0; x < width; x += spacer) {
          stroke(distances[x][y]);
          rect(x + spacer/2, y + spacer/2, 10, 10);
        }
      }
      popMatrix();
    }
  }

  //-----------------------png graphics-----------------------//
  pushMatrix();
  translate(width/2, height/2);
  rotate(radians(rAngle));
  imageMode(CENTER);
  //Mask- black png
  //Controls the speed of rotation for label and gradient, could be +5;
  //Label- ellipse
  //  fill(255, 55, 102);

  //  float r = map(sampleAverage, 0, 0.001, 100, 200);
  //  ellipseMode(CENTER);
  //  fill(255, 175, 102);
  //  ellipse (0, 0, r*3, r*3);

  //LINE IN- Animation 
  //Label- text png
  imageMode(CENTER);
  image(b, 0, 0);
  popMatrix();

  //Mask png
  imageMode(CORNER);
  image(a, 0, 0);
}


//-----------------------end-----------------------//

void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  player.close();
  player2.close();//
  minim.stop();
  super.stop();
}

void serialEvent(Serial myPort) {
  //println("HELLO");
  //get the serial input buffer in a string
  String inputString = myPort.readString();
  //filter out the tag ID from the string
  //println("RAW: " + inputString);
  tagID = parseString(inputString);
  //println("TAG: " + tagID);

  //-----------------------declare tag #'s-----------------------//
  if (tagID.equals("010CE136C1")) {
    state = 1;
  }

  else if (tagID.equals("010CE136EB")) {
    state = 2;
  }
  //println(tagID);
}

//-----------------------end declare tag #'s-----------------------//

String parseString(String thisString) {
  String tagString= ""; //string to put te--- tag ID into
  //first character of the input
  char firstChar = thisString.charAt(0);
  //last character of the input
  char lastChar = thisString.charAt(thisString.length() -1);
  //if the first char is STX (0x)2) and the last char is ETX (0x03)
  //then put the next ten bytes into the tag string
  if ((firstChar == 0x02) && (lastChar ==0x03)) {
    tagString = thisString.substring(1, 11);
  }
  return tagString;
}

