int pinValues[8];

int BAUDRATE = 9600;
int samplingfreq = 200;

void setup()
{
  Serial.begin(BAUDRATE);
  
  for (int p = 0; p < 14; p++) {
    pinMode(p, INPUT);
  }
}

void loop()
{
  // read all pins in the arduino and send output via serial
  for (int p = 14; p <= 19; p++)
  {
    Serial.print(analogRead(p));
    Serial.print(" ");
  }
  Serial.println();
  delay( int(1000/samplingfreq) );
}
