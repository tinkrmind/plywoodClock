void setLedPower(int pixNum, int intensity) {
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
    setLedPower(i, ledPower[i]);
    delay(200);
  }
}