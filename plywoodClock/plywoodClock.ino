// Plywood Clock
// Author: tinkrmind
// Attribution 4.0 International (CC BY 4.0). You are free to:
// Share — copy and redistribute the material in any medium or format
// Adapt — remix, transform, and build upon the material for any purpose, even commercially.

#include <Wire.h>
#include "RTClib.h"

RTC_DS3231 rtc;

#include "Adafruit_NeoPixel.h"
#ifdef __AVR__
#include <avr/power.h>
#endif

#define PIN 6
Adafruit_NeoPixel strip = Adafruit_NeoPixel(60, PIN, NEO_GRB + NEO_KHZ800);

int hourPixel = 0;
int minutePixel = 0;

unsigned long lastRtcCheck;

String inputString = "";         // a string to hold incoming data
boolean stringComplete = false;  // whether the string is complete

int level[24] = {0, 2, 0, 3, 2, 4,
                 3, 3, 3, 5, 1, 0,
                 3, 5, 3, 3, 4, 3,
                 3, 5, 3, 3, 2, 3
                };

void setup () {

#ifndef ESP8266
  while (!Serial); // for Leonardo/Micro/Zero
#endif
  // This is for Trinket 5V 16MHz, you can remove these three lines if you are not using a Trinket
#if defined (__AVR_ATtiny85__)
  if (F_CPU == 16000000) clock_prescale_set(clock_div_1);
#endif
  // End of trinket special code

  Serial.begin(9600);
  strip.begin();
  strip.show(); // Initialize all pixels to 'off'

  if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
    while (1);
  }

  pinMode(2, INPUT_PULLUP);

  //  rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  if (rtc.lostPower()) {
    Serial.println("RTC lost power, lets set the time!");
    // following line sets the RTC to the date & time this sketch was compiled
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    // This line sets the RTC with an explicit date & time, for example to set
    // January 21, 2014 at 3am you would call:
    // rtc.adjust(DateTime(2014, 1, 21, 3, 0, 0));
  }

  //  lightUpEven();


  //  while (1);
  lastRtcCheck = 0;
}

void loop () {
  //  if (millis() - lastRtcCheck > 2000) {
  //    DateTime now = rtc.now();
  //
  //    Serial.print(now.hour(), DEC);
  //    Serial.print(':');
  //    Serial.print(now.minute(), DEC);
  //    Serial.print(':');
  //    Serial.print(now.second(), DEC);
  //    Serial.println();
  //
  //    showTime();
  //
  //    lastRtcCheck = millis();
  //  }

  if (!digitalRead(2)) {
    lightUpEven();
  }

  if (stringComplete) {
    Serial.println(inputString);

    if (inputString[0] == 'c') {
      Serial.println("Showing time");
      showTime();
      strip.show();
    }

    if (inputString[0] == '1') {
      Serial.println("Switching on all LEDs");
      lightUp(strip.Color(255, 255, 255));
      strip.show();
    }

    if (inputString[0] == '0') {
      Serial.println("Clearing strip");
      clear();
      strip.show();
    }

    if (inputString[0] == '#') {
      String temp;
      temp = inputString.substring(1);
      int pixNum = temp.toInt();
      Serial.println(inputString.indexOf(','));
      temp = inputString.substring(inputString.indexOf(',') + 1);
      int intensity = temp.toInt();
      Serial.print("Setting ");
      Serial.print(pixNum);
      Serial.print(" to level ");
      Serial.println(intensity);

      strip.setPixelColor(pixNum, strip.Color(intensity, intensity, intensity));

      strip.show();
    }

    if (inputString[0] == '$') {
      String temp;
      
      temp = inputString.substring(1);
      int pixNum = temp.toInt();
      Serial.println(inputString.indexOf(','));
      
      int rIndex = inputString.indexOf(',', 1) + 1;
      temp = inputString.substring(rIndex);
      int rIntensity = temp.toInt();

      int gIndex = inputString.indexOf(',', rIndex) + 1;
      temp = inputString.substring(gIndex);
      int gIntensity = temp.toInt();

      int bIndex = inputString.indexOf(',', gIndex) + 1;
      temp = inputString.substring(bIndex);
      int bIntensity = temp.toInt();
      
      Serial.print("Setting ");
      Serial.print(pixNum);
      Serial.print(" R to ");
      Serial.print(rIntensity);
      Serial.print(" G to ");
      Serial.print(gIntensity);
      Serial.print(" B to ");
      Serial.println(bIntensity);

      strip.setPixelColor(pixNum, strip.Color(rIntensity, gIntensity, bIntensity));
      strip.show();
    }

    inputString = "";
    stringComplete = false;
  }

  //  delay(1000);
}

void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    inputString += inChar;
    if (inChar == '\n') {
      stringComplete = true;
    }
    delay(1);
  }
}

void clear() {
  for (uint16_t i = 0; i < strip.numPixels(); i++) {
    strip.setPixelColor(i, strip.Color(0, 0, 0));
  }
}

void showTime() {
  DateTime now = rtc.now();

  hourPixel = now.hour() % 12;
  minutePixel = round(float(now.minute()) / 5.0) % 12 + 12;

  clear();
  strip.setPixelColor(hourPixel, strip.Color(40 + 40 * level[hourPixel], 30 + 30 * level[hourPixel], 20 + 20 * level[hourPixel]));
  strip.setPixelColor(minutePixel, strip.Color(40 + 40 * level[minutePixel], 30 + 30 * level[minutePixel], 20 + 20 * level[minutePixel]));
  //  lightUp(strip.Color(255, 255, 255));
  strip.show();
}

void lightUp(uint32_t color) {
  for (uint16_t i = 0; i < strip.numPixels(); i++) {
    strip.setPixelColor(i, color);
  }
  strip.show();
}

void lightUpEven() {
  for (uint16_t i = 0; i < strip.numPixels(); i++) {
    strip.setPixelColor(i, strip.Color(40 + 40 * level[i], 30 + 30 * level[i], 20 + 20 * level[i]));
  }
  strip.show();
}
