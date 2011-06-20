#include <HomeAuto.h>

HomeAuto wtf = HomeAuto(2,4);
//include the definitions for the messages we will be sending
#include <ethernet_xbee_defs.h>

int sensorPin = A0;    // select the input pin for the potentiometer
void setup()
{
  wtf.setup(57600);
}

void loop()                     
{
  bool state = checkSensor();
  wtf.check(state);              
}


bool checkSensor(void)
{
  // read the value from the sensor:
  static int maxValue = 0;
  static int minValue = 1023;
  static bool return_value = false;
  int sensorValue = analogRead(sensorPin);
  if(sensorValue > maxValue)
    maxValue = sensorValue;  
  if(sensorValue < minValue)
    minValue = sensorValue;
  // turn the ledPin on
  

  static unsigned long timestamp = 0;
  if(millis() - timestamp > 1000)
  {
    return_value = (maxValue - minValue > 20) ? true : false;
//    Serial.print("Max Value: ");
//    Serial.println(maxValue);
//    Serial.print("Min Value: ");
//    Serial.println(minValue);
//    Serial.print("Diff: ");
//    Serial.println(maxValue - minValue);
    maxValue = 0;
    minValue = 1023;
    timestamp = millis();
  }
  // wait 10 milliseconds before the next loop
  // for the analog-to-digital converter to settle
  // after the last reading:
  delay(10);  
  
  if(return_value)
  {
//    Serial.println("Light ON");
    return true;
  }
  else
  {
//    Serial.println("Light OFF");
    return false;
  }
}
