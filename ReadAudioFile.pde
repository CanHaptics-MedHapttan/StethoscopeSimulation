PImage img;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.UnsupportedAudioFileException;
import java.io.File;
import java.io.IOException;

import javax.sound.sampled.*;
import java.io.*;

import org.gicentre.utils.stat.*; 
import javax.sound.sampled.AudioFormat.Encoding;

XYChart lineChart;


void setup() {
  size(1200,800);
  textFont(createFont("Arial",10),10);
 
  


  try{

    String filePath = "C:\\Users\\naomi\\Documents\\GIT\\ETS\\CanHaptics\\Project\\ReadAudioFile\\heartbeat_regular.wav";
    File audioFile = new File(filePath);
            
    // Open the audio file
    AudioInputStream audioInputStream = AudioSystem.getAudioInputStream(audioFile);
    
    // Get audio format information
    AudioFormat format = audioInputStream.getFormat();
    int numChannels = format.getChannels();
    int frameSize = format.getFrameSize();
    int bufferSize = 1024 * numChannels * frameSize;
    
    // Create a buffer to read the audio data
    byte[] buffer = new byte[bufferSize];
    
    // Create an array to store the waveform values
    //waveformValues = new int[(int) (audioInputStream.getFrameLength() * numChannels)];
    //waveformIndices = new int[waveformValues.length];
    waveformValues = getWavAmplitudes(audioFile);
    test = processAmplitudes(waveformValues);

    /* // Read audio data into the buffer
    int bytesRead;
    int totalBytesRead = 0;
    while ((bytesRead = audioInputStream.read(buffer)) != -1) {
        // Convert bytes to integers (assuming 16-bit PCM audio)
        for (int i = 0; i < bytesRead; i += frameSize) {
            for (int channel = 0; channel < numChannels; channel++) {
                // Calculate the index in the waveformValues array
                int index = totalBytesRead / frameSize * numChannels + channel;
                // Convert bytes to an integer value
                int value = 0;
                for (int j = 0; j < frameSize; j++) {
                    value |= (buffer[i + j] & 0xFF) << (8 * j);
                }
                // Store the value in the waveformValues array
                waveformIndices[index] = index;
                waveformValues[index] = value;
            }
            totalBytesRead += frameSize;
        }
    }
    
    // Close the audio input stream
    audioInputStream.close();
     */
    // Now you have the waveform values in the array
    // Do whatever you want with the waveformValues array

    // Both x and y data set here.  
  /* lineChart = new XYChart(this);
  lineChart.setData(waveformIndices,waveformValues);
   
  // Axis formatting and labels.
  lineChart.showXAxis(true); 
  lineChart.showYAxis(true); 
  lineChart.setMinY(0);
     
  lineChart.setYFormat("$###,###");  // Monetary value in $US
  lineChart.setXFormat("0000");      // Year
   
  // Symbol colours
  lineChart.setPointColour(color(180,50,50,100));
  lineChart.setPointSize(5);
  lineChart.setLineWidth(2); */
  }
  catch(UnsupportedAudioFileException | IOException ex){
    ex.printStackTrace();

  }
  readWaveForm = true;
          
}

int[] waveformIndices;
int[] waveformValues;
float[] test;
boolean readWaveForm = false;
int waveIndex = 0;

void draw() {
  //image(img, 0, 0);
  //image(img, 0, 0, width/2, height/2);
  if(readWaveForm){
    //println(waveformValues[waveIndex]);
    println(test[waveIndex]);
    
    waveIndex++;
  }

  /* background(255);
  textSize(9);
  lineChart.draw(15,15,width-30,height-30);
   
  // Draw a title over the top of the chart.
  fill(120);
  textSize(20);
  text("Income per person, United Kingdom", 70,30);
  textSize(11);
  text("Gross domestic product measured in inflation-corrected $US", 
        70,45); */
  
}

private static final double WAVEFORM_HEIGHT_COEFFICIENT = 1.3; // This fits the waveform to the swing node height


private int[] getWavAmplitudes(File file) throws UnsupportedAudioFileException , IOException {
				System.out.println("Calculting WAV amplitudes");
				
				//Get Audio input stream
				try (AudioInputStream input = AudioSystem.getAudioInputStream(file)) {
					AudioFormat baseFormat = input.getFormat();
					
					//Encoding
					Encoding encoding = AudioFormat.Encoding.PCM_UNSIGNED;
					float sampleRate = baseFormat.getSampleRate();
					int numChannels = baseFormat.getChannels();
					
					AudioFormat decodedFormat = new AudioFormat(encoding, sampleRate, 16, numChannels, numChannels * 2, sampleRate, false);
					int available = input.available();
					
					//Get the PCM Decoded Audio Input Stream
					try (AudioInputStream pcmDecodedInput = AudioSystem.getAudioInputStream(decodedFormat, input)) {
						final int BUFFER_SIZE = 4096; //this is actually bytes
						
						//Create a buffer
						byte[] buffer = new byte[BUFFER_SIZE];
						
						//Now get the average to a smaller array
						int maximumArrayLength = 100000;
						int[] finalAmplitudes = new int[maximumArrayLength];
						int samplesPerPixel = available / maximumArrayLength;
						
						//Variables to calculate finalAmplitudes array
						int currentSampleCounter = 0;
						int arrayCellPosition = 0;
						float currentCellValue = 0.0f;
						
						//Variables for the loop
						int arrayCellValue = 0;
						
						//Read all the available data on chunks
						while (pcmDecodedInput.readNBytes(buffer, 0, BUFFER_SIZE) > 0)
							for (int i = 0; i < buffer.length - 1; i += 2) {
								
								//Calculate the value
								arrayCellValue = (int) ( ( ( ( ( buffer[i + 1] << 8 ) | buffer[i] & 0xff ) << 16 ) / 32767 ) * WAVEFORM_HEIGHT_COEFFICIENT );
								
								//Tricker
								if (currentSampleCounter != samplesPerPixel) {
									++currentSampleCounter;
									currentCellValue += Math.abs(arrayCellValue);
								} else {
									//Avoid ArrayIndexOutOfBoundsException
									if (arrayCellPosition != maximumArrayLength)
										finalAmplitudes[arrayCellPosition] = finalAmplitudes[arrayCellPosition + 1] = (int) currentCellValue / samplesPerPixel;
									
									//Fix the variables
									currentSampleCounter = 0;
									currentCellValue = 0;
									arrayCellPosition += 2;
								}
							}
						
						return finalAmplitudes;
					} catch (Exception ex) {
						ex.printStackTrace();
					}
				} catch (Exception ex) {
					ex.printStackTrace();
					
				}
				
				//You don't want this to reach here...
				return new int[1];
			}


      private float[] processAmplitudes(int[] sourcePcmData) {
				System.out.println("Processing WAV amplitudes");
				
				//The width of the resulting waveform panel
				int width = 2000;//waveVisualization.width;
				float[] waveData = new float[width];
				int samplesPerPixel = sourcePcmData.length / width;
				
				//Calculate
				float nValue;
				for (int w = 0; w < width; w++) {
					
					//For performance keep it here
					int c = w * samplesPerPixel;
					nValue = 0.0f;
					
					//Keep going
					for (int s = 0; s < samplesPerPixel; s++) {
						nValue += ( Math.abs(sourcePcmData[c + s]) / 65536.0f );
					}
					
					//Set WaveData
					waveData[w] = nValue / samplesPerPixel;
				}
				
				System.out.println("Finished Processing amplitudes");
				return waveData;
			}