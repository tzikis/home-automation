//include the definitions for the messages we will be sending
#include <ethernet_xbee_defs.h>


//the period we use for checking the status of the light switch
const int period = 100;
//the period we use when broadcasting our status. currently 1 min.
const unsigned broadcastPeriod = 60000;
//the pins for our switch, and the relay
const int lightSwitch = 4;
const int lightPin = 2;

//the starting states are LOW
int lastSwitchState = LOW;
bool lightState = LOW;

void setup()
{
  //set the pins as input and output
  pinMode(lightPin, OUTPUT);
  pinMode(lightSwitch, INPUT);
  //check the light switch, and set it as the starting state
  //We do not care what state the light switch is in. We simply want
  //to check for changes in it state, so as to change the state of the
  //light accordingly. AKA if the light is on, and the lightSwitch is off
  //and changes to on, we turn the light off. This is done because the
  //two states are irrelevant, as the light can also be turned on and off
  //by the XBee remote.
  lastSwitchState = digitalRead(lightSwitch);
  
  //Start the serial and inform everyone we are turned on
  Serial.begin(57600);
  Serial.print(STARTING, BYTE);
}

//Set the light to the value we are given
void setLight(bool value)
{
  //update the state, turn the pin on or off accordingly,
  //and let everyone in the network know we have changed state
  lightState = value;
  digitalWrite(lightPin, lightState);
  broadcastState();
}

void sampleButton(void)
{
  //check the current state
  int currentSwitchState = digitalRead(lightSwitch);
  if(currentSwitchState != lastSwitchState)
  {
    //if the state has changed, reverse the light's state
    lastSwitchState = currentSwitchState;
    setLight(!lightState);
  }
}

//let the world know our current state
void broadcastState(void)
{
  if(lightState)
    Serial.print(STATE_ON, BYTE);
  else
    Serial.print(STATE_OFF, BYTE);
}

//this is our listener function
void checkForMessages(void)
{
    if (int avail_bytes = Serial.available())
    {
      for(int i=0; i< avail_bytes; i++)
      {
        //if we have input, and that input is either OPEN or CLOSE,
        //then do so accordingly
        char bla = (char) Serial.read();
        if(bla == OPEN) setLight(HIGH);
        else if(bla == CLOSE) setLight(LOW);
      }
    }
}

void loop()                     
{
  //initialize timestamp variables
  static unsigned long timestamp = 0;
  static unsigned long broadcastTimestamp = 0;
  
  if(millis() - timestamp > period)
  {
    //if it's time to check the button, do so
    sampleButton();
    timestamp=millis();
  }
  
  if(millis() - broadcastTimestamp > broadcastPeriod)
  {
    //if it's time to broadcast our state, do so
    broadcastTimestamp = millis();
    broadcastState();
  }
  
  //check for messages from our neighboors
  checkForMessages();
}
