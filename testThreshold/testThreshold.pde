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

int[] numPixelsInLed = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
long[] ledIntensity = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int[] ledPower = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255};
long targetIntensity = 99999999;

void setup() {
  printArray(Serial.list());
  String portName = Serial.list()[32];
  myPort = new Serial(this, portName, 9600);

  size(640, 480);
  video = new Capture(this, width, height);
  video.start();  
  noStroke();
  smooth();
  delay(1000);
}

void draw() {
  if (video.available()) {
    clearDisplay();
    delay(300);
    video.read();
    image(video, 0, 0, width, height); // Draw the webcam video onto the screen
    saveFrame("data/no_leds.jpg");

    if (runNumber != 0) {
      if (ledIntensity[ledNum] > targetIntensity) {
        ledPower[ledNum] -= pow(0.8, runNumber)*100+1;
      }
      if (ledIntensity[ledNum] < targetIntensity) {
        ledPower[ledNum] += pow(0.8, runNumber)*50+1;
      }

      if (ledPower[ledNum] > 255) {
        ledPower[ledNum] = 255;
      }
      if (ledPower[ledNum] < 0) {
        ledPower[ledNum]= 0;
      }
    }

    setLedState(ledNum, ledPower[ledNum]);
    delay(200);
    video.read();
    image(video, 0, 0, width, height); // Draw the webcam video onto the screen
    delay(10);

    while (myPort.available() > 0) {
      int inByte = myPort.read();
      //print(char(inByte));
    }

    String fileName = "data/";

    fileName+= str(ledNum);
    fileName += "_led.jpg";

    saveFrame(fileName);

    String orgfileName = "data/org";
    orgfileName+= str(ledNum);
    orgfileName += "_led.jpg";

    if (runNumber == 0) {
      saveFrame(orgfileName);
    }

    PImage noLedImg = loadImage("data/no_leds.jpg");
    PImage ledImg = loadImage(fileName);
    PImage orgledImg = loadImage(orgfileName);

    noLedImg.loadPixels();
    ledImg.loadPixels();
    orgledImg.loadPixels();

    background (0);
    loadPixels(); 

    ledIntensity[ledNum] = 0;
    numPixelsInLed[ledNum] = 0;

    for (int x = 0; x<width; x++) {
      for (int y = 0; y<height; y++) {
        PxPGetPixelDark(x, y, noLedImg.pixels, width);
        PxPGetPixelDarkLed(x, y, ledImg.pixels, width);
        PxPGetPixelDarkOrg(x, y, orgledImg.pixels, width);

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

    if (targetIntensity > ledIntensity[ledNum] && runNumber == 0) {
      targetIntensity = ledIntensity[ledNum];
    }

    print(ledPower[ledNum]);
    print(',');
    println(ledIntensity[ledNum]);
    updatePixels();
    ledNum++;
    if (ledNum == 12) {
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

void setLedState(int pixNum, int intensity) {
  myPort.write('#');
  myPort.write((pixNum%1000)/100+48);
  myPort.write((pixNum%100)/10+48);
  myPort.write(pixNum%10+48);
  myPort.write(',');
  myPort.write((intensity%1000)/100+48);
  myPort.write((intensity%100)/10+48);
  myPort.write(intensity%10+48);
  myPort.write('\r');
  myPort.write('\n');
}

void clearDisplay() {
  myPort.write('0');
  myPort.write('\r');
  myPort.write('\n');
}

void lightUpAll() {
  myPort.write('1');
  myPort.write('\r');
  myPort.write('\n');
}

void lightUpEven() {
  clearDisplay();
  for (int i=0; i<numLed; i++) {
    setLedState(i, ledPower[i]);
    delay(20);
  }
}

void PxPGetPixelDarkOrg(int x, int y, int[] pixelArray, int pixelsWidth) {
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

void PxPGetPixelDarkLed(int x, int y, int[] pixelArray, int pixelsWidth) {
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