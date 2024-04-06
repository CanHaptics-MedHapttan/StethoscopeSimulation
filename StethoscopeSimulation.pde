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
  AudioPlayer audio;
  ArrayList<Float> data;
  PVector area;
  String hapticName;
  String audioName;
}

WaveformSample[] waveformSamples;
int currentSampleIndex = 0;
/* end elements definition *********************************************************************************************/ 
boolean renderWaveForm = false;
int waveIndex = 0;
String workingDirectory = "C:\\Users\\naomi\\Documents\\GIT\\ETS\\CanHaptics\\MedHapttanProject\\StethoscopeSimulation";
String audioDirectory = workingDirectory + "\\audio";
String waveFormDataDirectory = workingDirectory + "\\waveformdata";
String wave_to_csv_script = workingDirectory + "\\wave_to_csv.py";


public String[] listFilesUsingJavaIO(String dir) {
    return Stream.of(new File(dir).listFiles())
      .filter(file -> !file.isDirectory())
      .map(File::getName)
      .collect(Collectors.toSet()).toArray(new String[0]);
}

String[] audioFiles;

void generateWaveformFiles(){
  // Get audio wave file names
  audioFiles = listFilesUsingJavaIO(audioDirectory);
  System.out.println("Wave files: " + Arrays.toString(audioFiles));

  // Generate a CSV waveform data file for each audio wave file in audio directory if they don't already exist
  System.out.println("STARTING WAVEFORM DATA GENERATION FROM WAVE FILES"); 
  String command = "python " + workingDirectory + "wave_to_csv.py";
  try {
    for (String waveFile : audioFiles) {
      String fileIn = audioDirectory + "\\" + waveFile;
      //SET AUDIO FILES HERE

      String fileOut = waveFormDataDirectory + "\\"+ waveFile.substring(0, waveFile.length() - 4) + "_sample.csv";
      if(!Files.exists(Paths.get(fileOut))){
        ProcessBuilder processBuilder = new ProcessBuilder("python", wave_to_csv_script, fileIn, fileOut);
        processBuilder.redirectErrorStream(true);

        Process process = processBuilder.start();
        BufferedReader output = new BufferedReader(new InputStreamReader(process.getInputStream()));
        String results = output.readLine();
        int exitCode = process.waitFor();
        String status = (exitCode == 0) ? "Successfully generated " + fileOut : "Waveform data file generation failed for " + waveFile + "\n" + results;
        System.out.println(status);
      }
      else{
        System.out.println("Waveform data file already exists: " + fileOut);
      }
    }
  } 
  catch (IOException e) {
    System.out.println(e.toString());
  }
  catch (InterruptedException e) {
    System.out.println(e.toString());
  }
}


void readWaveformData(){
  // Get audio waveform data file names
  String[] wavedataFiles = listFilesUsingJavaIO(waveFormDataDirectory);
  System.out.println("Wave data files: " + Arrays.toString(wavedataFiles));

  // Read wave file's csv values into a floating point array list
   try {
    for (int i = 0; i < wavedataFiles.length && i < 4; i++) {
      String fileIn = waveFormDataDirectory + "\\" + wavedataFiles[i];
      int sampleIndex = Integer.parseInt(String.valueOf(wavedataFiles[i].charAt(0)));
      //String fileIn = waveFormDataDirectory + "\\" + "heartbeat-regular-1k-fp.csv";

      Table table = loadTable(fileIn, "header");
      
      waveformSamples[sampleIndex].data = new ArrayList<Float>();
      waveformSamples[sampleIndex].hapticName = wavedataFiles[i];
      for (TableRow row : table.rows()) {
        waveformSamples[sampleIndex].data.add(row.getFloat("samples"));
        
      } 
    }
    renderWaveForm = true;
  }
  catch(Exception e){
    System.out.println(e);
  }   
}

PVector getCorrespondingArea(String fileName){
  int index = Integer.parseInt(String.valueOf(fileName.charAt(0)));
  return areas[index];
}

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
    
  areas[0] = new PVector(481,307); // position 1
  areas[1]= new PVector(535, 307); // position 2
  areas[2] = new PVector(538, 405); // position 3
  areas[3] = new PVector(594, 424); // position 4

  waveformSamples = new WaveformSample[4];
  for(int i = 0; i < waveformSamples.length; i++){
    waveformSamples[i] = new WaveformSample();
    waveformSamples[i].area = areas[i];
  }



  

  // Generate a CSV waveform data file for each audio wave file in audio directory if they don't already exist
  generateWaveformFiles();

  // Read wave file's csv values into a floating point array list
  readWaveformData();

  //aduio import
  System.out.println("IMPORTING AUDIO");
  System.out.println(Arrays.toString(audioFiles));
  minim = new Minim(this);
  
  //String[] audioFilesArray = audioFiles.toArray(new String[0]);
  for (int i = 0; i < waveformSamples.length; i++) {
    int sampleIndex = Integer.parseInt(String.valueOf(audioFiles[i].charAt(0)));
    waveformSamples[sampleIndex].audioName = audioFiles[i];
    //waveformSamples[i].audio = minim.loadFile(audioDirectory + "\\mp3\\" + audioFiles[i]);
    waveformSamples[sampleIndex].audio = minim.loadFile(audioDirectory + "\\mp3\\" + audioFiles[i].substring(0, audioFiles[i].length() - 3) + "mp3"); //TEMPORARY - MUST USE ABOVE
   // waveformSamples[i].audio = minim.loadFile(waveFormDataDirectory + "\\sample_"+ audioFilesArray[i].substring(0, waveFile.length() - 3) + "csv");
    //waveformSamples[i].area = areas[i]; //TODO : find a way to associate area with correct audio
    //waveformSamples[i].area = getCorrespondingArea(waveformSamples[i].hapticName); //TODO : find a way to associate area with correct audio
  }
       
  /* GUI setup */
  smooth();

  cp5 = new ControlP5(this);
    
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
    image(video, width/2, 0, width/2, height ); 
  
    // Display the image
    image(heartPlacementImage, 0, 0, 1000, 700 );

    imageX = deviceOrigin.x + posEE.x * pixelsPerMeter - stethoscopeImage.width / 2;
    imageY = deviceOrigin.y + posEE.y * pixelsPerMeter - stethoscopeImage.height / 2;
    image(stethoscopeImage, imageX, imageY);

    fill(255, 0, 0, 100); 
    noStroke();
    for (int i = 0; i < waveformSamples.length; i++) {
          ellipse(waveformSamples[i].area.x, waveformSamples[i].area.y, circle * 2, circle * 2);
    }
  }
}
/* end draw section ****************************************************************************************************/

int noforce = 0;
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
        
        noforce = 0;
        angles.set(widgetOne.get_device_angles());
      
        posEE.set(widgetOne.get_device_position(angles.array()));
        posEE.set(device_to_graphics(posEE)); 

        currentSampleIndex = -1; 

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
            waveformSamples[i].audio.rewind();
            audioPlaying = false;  
          }
        }

       /*  if(currentSampleIndex!=-1)
          System.out.println("STATUS : index=" +currentSampleIndex + " playing=" + audioPlaying); */
        if(noforce==1)
        {
          fEE.x=0.0;
          fEE.y=0.0;
        }
        else if(renderWaveForm && currentSampleIndex != -1){         
          // Send values of wavefile csv to Haply force rendering output
          fEE.y =  (waveformSamples[currentSampleIndex].data.get(waveIndex % (waveformSamples[currentSampleIndex].data.size()-1)) * intensityMultiplier);        
          fEE.x = 0.0;
          System.out.println("Index= " + currentSampleIndex + " Audio= " + waveformSamples[currentSampleIndex].audioName + " Haptic = " + waveformSamples[currentSampleIndex].hapticName);
          waveIndex++;        
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
       while(System.nanoTime()-starttime < looptime*1000) {
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
  arrow(xE,yE,fEE.x,fEE.y);
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

void arrow(float x1, float y1, float x2, float y2) {
  x2=x2*10.0;
  y2=y2*10.0;
  x1=x1+500;
  x2=-x2+x1;
  y2=y2+y1;

  line(x1, y1, x2, y2);
  pushMatrix();
  translate(x2, y2);
  float a = atan2(x1-x2, y2-y1);
  rotate(a);
  line(0, 0, -10, -10);
  line(0, 0, 10, -10);
  popMatrix();
} 

/* end helper functions section ****************************************************************************************/

void movieEvent(Movie m) {
  m.read();
}