#include <ethernet_xbee_defs.h>

// constants won't change. They're used here to 
// set pin numbers:
const int buttonPin = 2;     // the number of the pushbutton pin
const int buttonPin2 = 7;     // the number of the 2nd pushbutton pin
const int ledPin =  12;      // the number of the LED pin
const int ledPin2 =  11;      // the number of the 2nd LED pin

const int time_to_light = 30000;

//the period we use when broadcasting our status. currently 1 min.
const unsigned broadcastPeriod = 60000;

//This variable holds the state of our FSM. There are 6 states:
// 0 - If we press-and-hold button 1, go to state 1.
//     If we momentarily pressed the 1st button, go to state 2
//     If we press-and-hold button 2, go to state 3.
//     If we momentarily pressed the 1st button, go to state 4

// 1 - While here, keep opening the shutters.
//     If we are release the first button, go back to state 0 (stop openning the shutters)

// 2 - While here, count to 30 and keep opening the shutters
//     On the count to 30, go to state 0
//     If we momentarilly pressed, or press-and-hold the 2nd button, go to state 5

// 3 & 4 - The equivalent of 1 and 2, for closing the shutters

// 5 - Wait for a while, and go to 0. This is because, sometimes when we momentarily press the button while on 5,
//     if we went straight to 0, the program could believe the button is momentarily pressed and move to 2 or 4

// Notice that we can go from 2 to 3 if press-and-hold the 2nd button, because it will go
//from 2, to 5, then to 0, then to 3. It will just take a bit longer than expected (less than a second)

int FSM_State =0;

int ourState = STATE_UNDEF;

void setup()
{
  // initialize the LED pins as an outputs:
  pinMode(ledPin, OUTPUT);      
  pinMode(ledPin2, OUTPUT);      
  // initialize the pushbutton pins as an inputs:
  pinMode(buttonPin, INPUT);     
  pinMode(buttonPin2, INPUT);   

  //XBee shit from now on
  Serial.begin(57600);
  Serial.print(STARTING, BYTE);
}

void loop()
{
  
  checkForMessages();
  
  int buttonState = checkForButtons();
  
//  if(buttonState != 0)
//    Serial.print("Button State: ");
//    Serial.println(buttonState, DEC);

  handleFSM(buttonState);
  
  delay(50);
  
  
  static unsigned long broadcastTimestamp = 0;
  if(millis() - broadcastTimestamp > broadcastPeriod)
  {
    //if it's time to broadcast our state, do so
    broadcastTimestamp = millis();
    broadcastState();
  }


}

void handleFSM(int currentButtonState)
{
    static int FSM = 0;
//  static int oldFSM = 0;

  if(FSM == 0)
  {
    digitalWrite(ledPin, LOW);
    digitalWrite(ledPin2, LOW);
    FSM = currentButtonState;
  }
  else if(FSM == 1)
  {
    digitalWrite(ledPin, HIGH);
    digitalWrite(ledPin2, LOW);
    ourState = STATE_UNDEF;
    FSM = currentButtonState;
  }
  else if(FSM == 2)
  {
    digitalWrite(ledPin, LOW);
    digitalWrite(ledPin2, HIGH);
    ourState = STATE_UNDEF;
    FSM = currentButtonState;    
  }
  else if(FSM == 3)
  {    
    digitalWrite(ledPin, HIGH);
    digitalWrite(ledPin2, LOW);
    if(currentButtonState == 2 || currentButtonState == 4) FSM = 5;
    
    static unsigned long startingTimestamp = 0;
    if(startingTimestamp == 0) startingTimestamp = millis();
    if(millis() - startingTimestamp > time_to_light)
    {
      startingTimestamp = 0;
      ourState = STATE_ON;
      broadcastState();
      FSM = 5;
    }

  }
  else if(FSM == 4)
  {
    digitalWrite(ledPin, LOW);
    digitalWrite(ledPin2, HIGH);
    if(currentButtonState == 1 || currentButtonState == 3) FSM = 5;
    
    static unsigned long startingTimestamp = 0;
    if(startingTimestamp == 0) startingTimestamp = millis();
    if(millis() - startingTimestamp > time_to_light)
    {
      startingTimestamp = 0;
      ourState = STATE_OFF;
      broadcastState();
      FSM = 5;
    }

  }
  else if(FSM == 5)
  {
    digitalWrite(ledPin, LOW);
    digitalWrite(ledPin2, LOW);
    delay(150);    
    FSM = 0;
  } 
//  if(oldFSM != FSM)
//  {
//    Serial.print("FSM: ");
//    Serial.println(FSM, DEC);
//  }
//  oldFSM = FSM;
}

int checkForButtons(void)
{
  //The following variables will be used to check wether the intervals have passed
  static unsigned long timestamp = 0, holdTimestamp =0;
  const unsigned long buttonCheckInterval = 100;  // interval at which to check for button press (milliseconds)
  const unsigned long decisionInterval = 500;
  static unsigned long buttonDecideInterval = decisionInterval; // interval at which to decide if we are holding the button (milliseconds)  
  
  static int returnValue = 0;
      
  if(millis() - timestamp > buttonCheckInterval)
  {

    static int buttonState = 0, oldButtonState = 0, holdButtonState = 0; // variable for reading the pushbutton status
    static int buttonState2 = 0, oldButtonState2 = 0, holdButtonState2 = 0; // variable for reading the 2nd pushbutton status
    
    // read the state of the pushbutton values:
    buttonState = digitalRead(buttonPin);
    buttonState2 = digitalRead(buttonPin2);
    
    if(buttonState == HIGH) holdButtonState++;
    if(buttonState2 == HIGH) holdButtonState2++;
    
    
    if(buttonState == LOW)
    {
      if(oldButtonState == HIGH && holdButtonState < 2)
        returnValue = 3;
      else if(returnValue == 3)
        returnValue = 0;
      holdButtonState = 0;
    }
    
    if(buttonState2 == LOW)
    {
      if(oldButtonState2 == HIGH && holdButtonState2 < 2) 
        returnValue = 4;
      else if(returnValue == 4)
        returnValue = 0;
      holdButtonState2 = 0;
    }
    
    if(millis() - holdTimestamp > buttonDecideInterval)
    {
      if(holdButtonState > 1)
      {
        returnValue = 1;
      }
      else if(holdButtonState2 > 1)
      {
        returnValue = 2;
      }
      else if(returnValue == 1 || returnValue == 2)
        returnValue = 0;
      
      holdTimestamp = millis();
    }
    
    oldButtonState = buttonState;
    oldButtonState2 = buttonState2;
    
    timestamp = millis();
  }
//  if(returnValue != 0) delay(50);
  return returnValue;
}

void checkForMessages(void)
{
  if (Serial.available())
  {
    char bla = (char) Serial.read();
    if(bla == OPEN) FSM_State = 2;
    else if(bla == CLOSE) FSM_State = 4;
    else if(bla == HALT) FSM_State = 0;
  }
}

//let the world know our current state
void broadcastState(void)
{
  Serial.print(ourState, BYTE);
}
