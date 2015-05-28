int BAUDRATE = 115200;      // speed of serial port
int samplingfreq    = 200;  // readings per second

void setup()
{
  Serial.begin(BAUDRATE);
}

void loop()
{
  // read all pins in the arduino and send output via serial
  for (int p = 0; p < 14; p++)
  {
    Serial.print(digitalRead(p));
    Serial.println(" ");
  }
  Serial.print('\r');
  delay( int(1000/samplingfreq) );
}
