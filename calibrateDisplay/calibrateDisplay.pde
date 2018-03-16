import processing.video.*;
import processing.serial.*;
Serial myPort;     

Capture video;

final int numLed = 24;
int ledNum =0;

// you must have these global varables to use the PxPGetPixelDark()
int rDark, gDark, bDark, aDark;          
int rLed, gLed, bLed, aLed;
int rOrg, gOrg, bOrg, aOrg;
int rTemp, gTemp, bTemp, aTemp;
PImage ourImage;

int runNumber = 0;
int acceptableError = 3;

int[] done;
int[] numPixelsInLed;
long[] ledIntensity;
int[] ledPower;
long targetIntensity = 99999999;

void setup() {
  done = new int[numLed];
  numPixelsInLed = new int[numLed];
  ledIntensity = new long[numLed];
  ledPower = new int[numLed];
  for (int i=0; i<numLed; i++) {
    ledPower[i] = 255;
  }
  printArray(Serial.list());
  String portName = Serial.list()[32];
  myPort = new Serial(this, portName, 115200);

  size(640, 480);
  video = new Capture(this, width, height, Capture.list()[0]);
  video.start();  
  noStroke();
  smooth();
  delay(1000); // Wait for serial port to open
}

void draw() {
  if (video.available()) {
    if (done[ledNum] == 0) {
      clearDisplay();
      delay(1000);
      video.read();
      image(video, 0, 0, width, height); // Draw the webcam video onto the screen
      saveFrame("data/no_leds.jpg");

      if (runNumber != 0) {
        if ((ledIntensity[ledNum] - targetIntensity)*100/targetIntensity > acceptableError) {
          ledPower[ledNum] -= pow(0.75, runNumber)*100+1;
        }
        if ((targetIntensity - ledIntensity[ledNum])*100/targetIntensity > acceptableError) {
          ledPower[ledNum] += pow(0.75, runNumber)*100+1;
        }
        if (abs(targetIntensity - ledIntensity[ledNum])*100/targetIntensity <= acceptableError) {
          done[ledNum] = 1;
          print("Led ");
          print(ledNum);
          print(" done");
        }

        if (ledPower[ledNum] > 255) {
          ledPower[ledNum] = 255;
        }
        if (ledPower[ledNum] < 0) {
          ledPower[ledNum]= 0;
        }
      }

      setLedPower(ledNum, ledPower[ledNum]);
      delay(1000);
      video.read();
      image(video, 0, 0, width, height); // Draw the webcam video onto the screen
      delay(10);

      while (myPort.available() > 0) {
        int inByte = myPort.read();
        //print(char(inByte));
      }

      String imageName = "data/";

      imageName+= str(ledNum);
      imageName += "_led.jpg";

      saveFrame(imageName);

      String originalImageName = "data/org";
      originalImageName+= str(ledNum);
      originalImageName += ".jpg";

      if (runNumber == 0) {
        saveFrame(originalImageName);
      }

      PImage noLedImg = loadImage("data/no_leds.jpg");
      PImage ledImg = loadImage(imageName);
      PImage originalImg = loadImage(originalImageName);

      noLedImg.loadPixels();
      ledImg.loadPixels();
      originalImg.loadPixels();

      background (0);
      loadPixels(); 

      ledIntensity[ledNum] = 0;
      numPixelsInLed[ledNum] = 0;

      for (int x = 0; x<width; x++) {
        for (int y = 0; y<height; y++) {
          PxPGetPixelDark(x, y, noLedImg.pixels, width);
          PxPGetPixelLed(x, y, ledImg.pixels, width);
          PxPGetPixelOrg(x, y, originalImg.pixels, width);

          if ((rOrg+gOrg/2+bOrg/3)-(rDark+gDark/2+bDark/3)  > 75) {               
            ledIntensity[ledNum] = ledIntensity[ledNum] +(rLed+gLed/2+bLed/3) -(rDark+gDark/2+bDark/3);
            rTemp=255;
            gTemp=255;
            bTemp=255;                                     
            numPixelsInLed[ledNum]++;
          } else {                                  
            rTemp= 0;
            gTemp=0;
            bTemp=0;
          }                                              

          PxPSetPixel(x, y, rTemp, gTemp, bTemp, 255, pixels, width);
        }
      }

      ledIntensity[ledNum] /= numPixelsInLed[ledNum];

      if (targetIntensity > ledIntensity[ledNum] && runNumber == 0) {
        targetIntensity = ledIntensity[ledNum];
      }
      updatePixels();
    }

    print(ledNum);
    print(',');
    print(ledPower[ledNum]);
    print(',');
    println(ledIntensity[ledNum]);

    ledNum++;
    if (ledNum == numLed) {
      int donezo = 0;
      for (int i=0; i<numLed; i++) {
        donezo += done[i];
      }

      if (donezo == numLed) {
        println("DONE");
        for (int i=0; i<numLed; i++) {
          print(i);
          print(" \t ");
          println(ledPower[i]);
        }

        print("int level[");
        print(ledNum);
        print("] = {");
        for (int i=0; i<numLed-1; i++) {
          print(ledPower[i]);
          print(',');
        }
        print(ledPower[numLed - 1]);
        println("};");

        lightUpEven();        
        while (true);
      }

      print("Target intensity: ");
      if (runNumber == 0) {
        targetIntensity -= 1;
      }
      println(targetIntensity);
      ledNum = 0;
      runNumber++;
    }
  }
}



void PxPGetPixelOrg(int x, int y, int[] pixelArray, int pixelsWidth) {
  int thisPixel=pixelArray[x+y*pixelsWidth];     // getting the colors as an int from the pixels[]
  aOrg = (thisPixel >> 24) & 0xFF;                  // we need to shift and mask to get each component alone
  rOrg = (thisPixel >> 16) & 0xFF;                  // this is faster than calling red(), green() , blue()
  gOrg = (thisPixel >> 8) & 0xFF;   
  bOrg = thisPixel & 0xFF;
}

void PxPGetPixelDark(int x, int y, int[] pixelArray, int pixelsWidth) {
  int thisPixel=pixelArray[x+y*pixelsWidth];     // getting the colors as an int from the pixels[]
  aDark = (thisPixel >> 24) & 0xFF;                  // we need to shift and mask to get each component alone
  rDark = (thisPixel >> 16) & 0xFF;                  // this is faster than calling red(), green() , blue()
  gDark = (thisPixel >> 8) & 0xFF;   
  bDark = thisPixel & 0xFF;
}

void PxPGetPixelLed(int x, int y, int[] pixelArray, int pixelsWidth) {
  int thisPixel=pixelArray[x+y*pixelsWidth];     // getting the colors as an int from the pixels[]
  aLed = (thisPixel >> 24) & 0xFF;                  // we need to shift and mask to get each component alone
  rLed = (thisPixel >> 16) & 0xFF;                  // this is faster than calling red(), green() , blue()
  gLed = (thisPixel >> 8) & 0xFF;   
  bLed = thisPixel & 0xFF;
}

void PxPSetPixel(int x, int y, int r, int g, int b, int a, int[] pixelArray, int pixelsWidth) {
  a =(a << 24);                       
  r = r << 16;                                // We are packing all 4 composents into one int
  g = g << 8;                                 // so we need to shift them to their places
  color argb = a | r | g | b;                 // binary "or" operation adds them all into one int
  pixelArray[x+y*pixelsWidth]= argb;          // finaly we set the int with te colors into the pixels[]
}

//0    37
//1    49
//2    37
//3    68
//4    51
//5    229
//6    68
//7    109
//8    102
//9    255
//10    51
//11    46
//12    68
//13    236
//14    84
//15    84
//16    109
//17    87
//18    144
//19    199
//20    77
//21    112
//22    68
//23    77