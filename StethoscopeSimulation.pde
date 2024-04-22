/**
 **********************************************************************************************************************
 * @file       StethoscopeSimulation.pde
 * @author     Sara Badr, Naomi Catwell, Anay Karve, Soonuk Kwon
 * @version    V1.0.0
 * @date       31-March-2024
 * @brief      Waveform rendering of heartbeat
 */
 
/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import java.util.*; 
import java.io.*;
import java.util.stream.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import controlP5.*;
import java.util.ArrayList;
import ddf.minim.*;
import processing.video.*;
import processing.sound.*;
import gifAnimation.*;
/* end library imports *************************************************************************************************/  


/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 



/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                     = false;
/* end device block definition *****************************************************************************************/



/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
/* end framerate definition ********************************************************************************************/ 


/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerMeter                      = 4000.0;
float             radsPerDegree                       = 0.01745;

/* pantagraph link parameters in meters */
float             l                                   = 0.07;
float             L                                   = 0.09;


/* end effector radius in meters */
float             rEE                                 = 0.006;


/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);
PVector           oldangles                              = new PVector(0, 0);
PVector           diff                              = new PVector(0, 0);


/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0); 

/* device graphical position */
PVector           deviceOrigin                        = new PVector(0, 0);

/* World boundaries reference */
final int         worldPixelWidth                     = 1000;
final int         worldPixelHeight                    = 650;

float x_m,y_m;

// for changing update rate
int iter = 0;

// checking everything run in less than 1ms
long timetaken= 0;

// set loop time in usec (note from Antoine, 500 is about the limit of my computer max CPU usage)
int looptime = 500;
int heartRate = 5;

float xr = 0;
float yr = 0;

/* graphical elements */
PFont f;
PShape pGraph, joint, endEffector;
PImage stethoscopeImage;
PImage heartPlacementImage;
Gif heartbeatImage;

int circleRadius = 15;
float imageX = 0;
float imageY = 0;

/* Haptic rendering elements */
private class WaveformSample {
  SoundFile audio;
  PVector area;
  PVector circle;
  Waveform waveform;
  float intensityMultiplier;
}

WaveformSample[] waveformSamples;
int currentSampleIndex = 0;
int waveIndex = 0;
boolean renderWaveForm = true;
int samples = 100;
/* end elements definition *********************************************************************************************/ 


/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  /* screen size definition */
  size(1440, 700);

// Load the images
  stethoscopeImage = loadImage("images/stethoscope.png");
  stethoscopeImage.resize(75, 0);

  heartbeatImage = new Gif(this, "images/heartbeatAnimation.gif");
  heartbeatImage.play();
  
  heartPlacementImage = loadImage("images/HeartPlacementsGraphic.png");

  // Ausculation points on heart image
  PVector[] areas = new PVector[4];
  areas[0] = new PVector(481,307); // position 1
  areas[1]= new PVector(535, 307); // position 2
  areas[2] = new PVector(538, 405); // position 3
  areas[3] = new PVector(594, 424); // position 4

  // Circular highlight points on heartbeat video
  PVector[] circles = new PVector[4];
  circles[0] = new PVector(1275, 245); // circle 1
  circles[1]= new PVector(1225, 180); // circle 2
  circles[2] = new PVector(1165, 300); // circle 3
  circles[3] = new PVector(1305, 300); // circle 4

  waveformSamples = new WaveformSample[4];
  for(int i = 0; i < waveformSamples.length; i++){
    waveformSamples[i] = new WaveformSample();
    waveformSamples[i].area = areas[i];
    waveformSamples[i].circle = circles[i];
    waveformSamples[i].waveform = new  Waveform(this, samples);
  } 

  waveformSamples[0].audio = new SoundFile(this, "0-aortic_valve.wav");
  waveformSamples[1].audio = new SoundFile(this, "1-pulmonary_valve.wav");
  waveformSamples[2].audio = new SoundFile(this, "2-tricuspid_valve.wav");
  waveformSamples[3].audio = new SoundFile(this, "3-mitral_valve.wav");

  waveformSamples[0].intensityMultiplier = 2;
  waveformSamples[1].intensityMultiplier = 1.5;
  waveformSamples[2].intensityMultiplier = 1.2;
  waveformSamples[3].intensityMultiplier = 1;

  smooth();

  /* device setup */
  
  /**  
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
   */ 
  try{
    haplyBoard          = new Board(this, "COM6", 0);
    widgetOne           = new Device(widgetOneID, haplyBoard);
    pantograph          = new Pantograph();
    
    widgetOne.set_mechanism(pantograph);
    
    widgetOne.add_actuator(1, CCW, 2);
    widgetOne.add_actuator(2, CW, 1);
  
    widgetOne.add_encoder(1, CCW, 241, 10752, 2);
    widgetOne.add_encoder(2, CW, -61, 10752, 1);
    
    widgetOne.device_set_parameters();    
  }
  catch(Exception e)
  {
    System.out.println("HAPLY DEVICE IS NOT CONNECTED!\n" + e);
  }   
  
  /* visual elements setup */
  background(0);
  deviceOrigin.add(worldPixelWidth/2, 0);
  
  /* create pantagraph graphics */
  create_pantagraph();

  /* setup framerate speed */
  frameRate(baseFrameRate);
  f = createFont("Arial",16,true); // STEP 2 Create Font
  
  /* setup simulation thread to run at 1kHz */ 
  thread("SimulationThread");
}
/* end setup section ***************************************************************************************************/


/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if(renderingForce == false){
    background(255); 

    // Display the heartbeat animation
    image(heartbeatImage, 900, -150, 700, 900);

    // Display the asculation points images
    image(heartPlacementImage, 0, 0, 1000, 700);

    imageX = deviceOrigin.x + posEE.x * pixelsPerMeter - stethoscopeImage.width / 2;
    imageY = deviceOrigin.y + posEE.y * pixelsPerMeter - stethoscopeImage.height / 2;
    image(stethoscopeImage, imageX, imageY);

    // Display the ausculation points highlights
    fill(255, 0, 0, 100); 
    noStroke();
    for (int i = 0; i < waveformSamples.length; i++) {
      ellipse(waveformSamples[i].area.x, waveformSamples[i].area.y, circleRadius * 2, circleRadius * 2);
    } 

    // Display the corresponding circular highlight on the heartbeeat animation
    noFill();
    stroke(0, 200, 0);
    if(currentSampleIndex != -1){
      ellipse(waveformSamples[currentSampleIndex].circle.x, waveformSamples[currentSampleIndex].circle.y, circleRadius * 6, circleRadius * 6);
    }
  }
}
/* end draw section ****************************************************************************************************/

long timetook = 0;
long looptiming = 0;

/* simulation section **************************************************************************************************/
public void SimulationThread(){
while(1==1) {
    long starttime = System.nanoTime();
    long timesincelastloop=starttime-timetaken;
    iter+= 1;
    // we check the loop is running at the desired speed (with 10% tolerance)
    if(timesincelastloop >= looptime*1000*1.1) {
      float freq = 1.0/timesincelastloop*1000000.0;      
    }
    else if(iter >= 1000) {
      float freq = 1000.0/(starttime-looptiming)*1000000.0;
       iter=0;
       looptiming=starttime;
    }

    timetaken=starttime;    
    renderingForce = true;
    if(haplyBoard != null) {
      if(haplyBoard.data_available()){
        /* GET END-EFFECTOR STATE (TASK SPACE) */
        widgetOne.device_read_data();
        
        angles.set(widgetOne.get_device_angles());
      
        posEE.set(widgetOne.get_device_position(angles.array()));
        posEE.set(device_to_graphics(posEE)); 

        currentSampleIndex = -1; 

        // Check if we are at a given ausculation point. If so, store the corresponding currentSampleIndex and play the corresponding audio
        for (int i = 0; i < waveformSamples.length; i++) {          
          if (dist(imageX + stethoscopeImage.width / 2, imageY + stethoscopeImage.height / 2, waveformSamples[i].area.x, waveformSamples[i].area.y) < 15) {
            currentSampleIndex = i;
            if (!waveformSamples[i].audio.isPlaying()) {          
              waveformSamples[i].audio.loop();    
            }
          }
          else if(waveformSamples[i].audio.isPlaying()){    
            waveformSamples[i].audio.jump(0.0);
            waveformSamples[i].audio.pause();
          }
        }
        
        // Render the waveform corresponding to the previously stores currentSampleIndex
        if(renderWaveForm && currentSampleIndex != -1){         
          waveformSamples[currentSampleIndex].waveform.input(waveformSamples[currentSampleIndex].audio);
          waveformSamples[currentSampleIndex].waveform.analyze();          

          float waveformValue = waveformSamples[currentSampleIndex].waveform.data[waveIndex%(samples-1)];

          fEE.y = map(waveformValue, -0.5, 1, -4, 4) * waveformSamples[currentSampleIndex].intensityMultiplier;
          fEE.x = 0.0;

          waveIndex++;      
        }
        else
        {
          fEE.x=0.0;
          fEE.y=0.0;
        }
        widgetOne.set_device_torques(graphics_to_device(fEE).array());      
      }

      widgetOne.device_write_torques();
    }
    
    renderingForce = false;
    long timetook=System.nanoTime()-timetaken;
    if(timetook >= 1000000) {
    }
    else {
       while(System.nanoTime()-starttime < looptime*10000) {
      //NOP
      } 
    }    
  }
}

/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/
void create_pantagraph(){
  float lAni = pixelsPerMeter * l;
  float LAni = pixelsPerMeter * L;
  float rEEAni = pixelsPerMeter * rEE;
  
  pGraph = createShape();
  pGraph.beginShape();
  pGraph.fill(255);
  pGraph.stroke(0);
  pGraph.strokeWeight(2);
  
  pGraph.vertex(deviceOrigin.x, deviceOrigin.y);
  pGraph.vertex(deviceOrigin.x, deviceOrigin.y);
  pGraph.vertex(deviceOrigin.x, deviceOrigin.y);
  pGraph.vertex(deviceOrigin.x, deviceOrigin.y);
  pGraph.endShape(CLOSE);
  
  joint = createShape(ELLIPSE, deviceOrigin.x, deviceOrigin.y, rEEAni, rEEAni);
  joint.setStroke(color(0));
  
  endEffector = createShape(ELLIPSE, deviceOrigin.x, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
  endEffector.setStroke(color(0));
  strokeWeight(5);  
}


void update_animation(float th1, float th2, float xE, float yE){
  background(255);
  pushMatrix();
  float lAni = pixelsPerMeter * l;
  float LAni = pixelsPerMeter * L;
  
  xE = pixelsPerMeter * xE;
  yE = pixelsPerMeter * yE;
  
  th1 = 3.14 - th1;
  th2 = 3.14 - th2;
    
  pGraph.setVertex(1, deviceOrigin.x + lAni*cos(th1), deviceOrigin.y + lAni*sin(th1));
  pGraph.setVertex(3, deviceOrigin.x + lAni*cos(th2), deviceOrigin.y + lAni*sin(th2));
  pGraph.setVertex(2, deviceOrigin.x + xE, deviceOrigin.y + yE);
  
  shape(pGraph);
  shape(joint);
  float[] coord;
  
  
  translate(xE, yE);
  shape(endEffector);
  popMatrix();
  textFont(f,16);
  fill(0);

  x_m = xr*300+500;       
  y_m = yr*300+350;

  pushMatrix();
  translate(x_m, y_m);
  popMatrix();  
}


PVector device_to_graphics(PVector deviceFrame){
  return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
}


PVector graphics_to_device(PVector graphicsFrame){
  return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
}

/* end helper functions section ****************************************************************************************/