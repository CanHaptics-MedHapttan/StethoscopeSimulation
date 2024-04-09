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
/* end library imports *************************************************************************************************/  


/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 

ControlP5 cp5;
Movie video;
PImage heartPlacementImage;

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
int intensityMultiplier = 4;

/* graphical elements */
PShape pGraph, joint, endEffector;
PFont f;
PImage stethoscopeImage;
PImage heart;

Minim minim;
boolean audioPlaying = false;
AudioPlayer audio1;
AudioPlayer audio2;
AudioPlayer audio3;
AudioPlayer audio4;

private class WaveformSample {
  SoundFile audio;
  ArrayList<Float> data;
  PVector area;
  String hapticName;
  String audioName;
}

WaveformSample[] waveformSamples;
int currentSampleIndex = 0;
/* end elements definition *********************************************************************************************/ 
boolean renderWaveForm = true;
int waveIndex = 0;
String workingDirectory = "C:\\Users\\naomi\\Documents\\GIT\\ETS\\CanHaptics\\MedHapttanProject\\StethoscopeSimulation";
String audioDirectory = workingDirectory + "\\audio";
String waveFormDataDirectory = workingDirectory + "\\waveformdata";
String wave_to_csv_script = workingDirectory + "\\wave_to_csv.py";


String[] audioFiles;

SoundFile sample;
Waveform waveform;

int samples = 1000;


/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  /* screen size definition */
  size(1440, 700);


  stethoscopeImage = loadImage("images/stethoscope.png");
  stethoscopeImage.resize(75, 0);

  // Load the video
  video = new Movie(this, "heartbeatVideo.mp4");
  video.loop();

  // Load the image
  heartPlacementImage = loadImage("images/HeartPlacementsGraphic.png");
    
  //sample = new SoundFile(this, "0-aortic_valve.wav");
  //sample.loop();

  waveform = new Waveform(this, samples);
  waveform.input(sample);

  areas[0] = new PVector(481,307); // position 1
  areas[1]= new PVector(535, 307); // position 2
  areas[2] = new PVector(538, 405); // position 3
  areas[3] = new PVector(594, 424); // position 4

  waveformSamples = new WaveformSample[4];
  for(int i = 0; i < waveformSamples.length; i++){
    waveformSamples[i] = new WaveformSample();
    waveformSamples[i].area = areas[i];    
  } 

  waveformSamples[0].audio = new SoundFile(this, "0-aortic_valve.wav");
  waveformSamples[1].audio = new SoundFile(this, "1-pulmonary_valve.wav");
  waveformSamples[2].audio = new SoundFile(this, "2-tricuspid_valve.wav");
  waveformSamples[3].audio = new SoundFile(this, "3-mitral_valve.wav");

  smooth();

  /* cp5 = new ControlP5(this);
    
  cp5.addTextlabel("Intensity multiplier")
      .setText("Intensity multiplier")
      .setPosition(0,250)
      .setColorValue(color(255,0,0))
      .setFont(createFont("Georgia",20))
      ;  
    cp5.addSlider("intensityMultiplier") 
      .setPosition(0,275)
      .setSize(200,20)
      .setRange(0,10)
      .setValue(4)
      ;

    cp5.addTextlabel("Loop time")
      .setText("Loop time")
      .setPosition(0,420)
      .setColorValue(color(255,0,0))
      .setFont(createFont("Georgia",20))
      ;  
    cp5.addSlider("looptime")
      .setPosition(10,450)
      .setSize(200,20)
      .setRange(250,4000)
      .setValue(500)
      .setNumberOfTickMarks(16)
      .setSliderMode(Slider.FLEXIBLE)
      ;
 */


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


PVector[] areas = new PVector[4];
int circle = 15;
float imageX = 0;
float imageY = 0;

/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if(renderingForce == false){
    background(255); 

    //image(heart, 0, 0);
    // Display the video
    image(video, 1000, -150, 440, 1000); 
  
    // Display the image
    image(heartPlacementImage, 0, 0, 1000, 700);

    imageX = deviceOrigin.x + posEE.x * pixelsPerMeter - stethoscopeImage.width / 2;
    imageY = deviceOrigin.y + posEE.y * pixelsPerMeter - stethoscopeImage.height / 2;
    image(stethoscopeImage, imageX, imageY);

    fill(255, 0, 0, 100); 
    noStroke();
   for (int i = 0; i < waveformSamples.length; i++) {
          ellipse(waveformSamples[i].area.x, waveformSamples[i].area.y, circle * 2, circle * 2);
    } 
  }
  
  /* waveform.analyze();
  for(int i = 0; i < 100; i++)
  {
    println(map(waveform.data[i], -1, 1, -1, 1));
  } */

}
/* end draw section ****************************************************************************************************/

int noforce = 0;
long timetook = 0;
long looptiming = 0;

float minv = Float.MAX_VALUE;
float maxv = Float.MIN_VALUE;
int directionMultiplier = -1;
boolean fileGenerated = true;

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
        
        noforce = 0;
        angles.set(widgetOne.get_device_angles());
      
        posEE.set(widgetOne.get_device_position(angles.array()));
        posEE.set(device_to_graphics(posEE)); 

        //currentSampleIndex = -1; 

        for (int i = 0; i < waveformSamples.length; i++) {
         // ellipse(waveformSamples[i].area.x, waveformSamples[i].area.y, circle * 2, circle * 2);

          if (dist(imageX + stethoscopeImage.width / 2, imageY + stethoscopeImage.height / 2, waveformSamples[i].area.x, waveformSamples[i].area.y) < 50) {
            if (!audioPlaying) {          
              waveformSamples[i].audio.play();    
              audioPlaying = true;   
              currentSampleIndex = i;
            }
          }
          else {      
            waveformSamples[i].audio.pause();
            //waveformSamples[i].audio.jump(0.0);
            audioPlaying = false;  
          }
        } 
        if(noforce==1)
        {
          fEE.x=0.0;
          fEE.y=0.0;
        }
        else if(renderWaveForm){         
          // Send values of wavefile csv to Haply force rendering output
          waveform.analyze();

          if(!fileGenerated){
            Table table = new Table();  
            table.addColumn("sample");
                      
            for(int i = 0; i < waveform.data.length; i++)
            {
              TableRow newRow = table.addRow();
              newRow.setFloat("sample", waveform.data[i]);
              //rintln(map(waveform.data[i], -1, 1, -1, 1));
              //println(map(waveform.data[i], -1, 1, -1, 1));
            } 
            saveTable(table, "data/WAVE_DATA.csv");
          }
          

          float y = 0; //map(waveform.data[currentSampleIndex%(100-1)], -0.9423218, 0.93618774, -1, 1) * intensityMultiplier;
          //println(y);
          if(waveform.data[currentSampleIndex%(100-1)] < -0.8 || waveform.data[currentSampleIndex%(100-1)] > 0.8){
            y = 1;  
          } 
          //if(waveform.data[currentSampleIndex%(100-1)] > 0.5) y = 1;
          directionMultiplier *= -1;
          fEE.y = directionMultiplier * y * intensityMultiplier;
          fEE.x = 0.0;
          currentSampleIndex++;
          println(currentSampleIndex);
          if(currentSampleIndex>=100) {println("min= " + minv+ "max= " + maxv);}
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

void movieEvent(Movie m) {
  m.read();
}