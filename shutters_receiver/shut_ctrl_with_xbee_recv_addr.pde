#include <ethernet_xbee_defs.h>

/*
  Button
 
 Turns on and off a light emitting diode(LED) connected to digital  
 pin 13, when pressing a pushbutton attached to pin 7. 
 
 
 The circuit:
 * 1st LED + Relay control pin attached to pin 12
 * 2nd LED + Relay control pin attached to pin 11
 * pushbutton attached to pin 2 from +5V
 * 10K resistor attached to pin 2 from ground

 * 2nd pushbutton attached to pin 7 from +5V
 * 2nd 10K resistor attached to pin 7 from ground

 created 2005
 by DojoDave <http://www.0j0.org>
 modified 17 Jun 2009
 by Tom Igoe

  modified 14 Sept 2010
 by Vasileios Georgitzikis
 
 This example code is in the public domain.
 
 http://www.arduino.cc/en/Tutorial/Button
 */

// constants won't change. They're used here to 
// set pin numbers:
const int buttonPin = 2;     // the number of the pushbutton pin
const int buttonPin2 = 7;     // the number of the 2nd pushbutton pin
const int ledPin =  12;      // the number of the LED pin
const int ledPin2 =  11;      // the number of the 2nd LED pin

const int time_to_light = 30000;

// variables will change:
int buttonState = 0;         // variable for reading the pushbutton status
int buttonState2 = 0;         // variable for reading the 2nd pushbutton status

long buttonCheckInterval = 100;  // interval at which to check for button press (milliseconds)
long buttonDecideInterval = 500; // interval at which to decide if we are holding the button (milliseconds)

//The following variables will be used to check wether the intervals have passed
long previousMillis = 0;
long previousMillis2 =0;

//We use two variables for each button, in order to check if it is pressed-and-held
int button1_pressed = 0;
int button1_pressed_old = 0;

int button2_pressed = 0;
int button2_pressed_old = 0;

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

void setup() {
  // initialize the LED pins as an outputs:
  pinMode(ledPin, OUTPUT);      
  pinMode(ledPin2, OUTPUT);      
  // initialize the pushbutton pins as an inputs:
  pinMode(buttonPin, INPUT);     
  pinMode(buttonPin2, INPUT);   

  //XBee shit from now on
  Serial.begin(57600);
}

void loop(){
  // read the state of the pushbutton values:
  buttonState = digitalRead(buttonPin);
  buttonState2 = digitalRead(buttonPin2);
  
  if(FSM_State == 0)
  {
    //We are waiting for button presses, so we disable the LEDs and shutters.
    digitalWrite(ledPin, LOW);
    digitalWrite(ledPin2, LOW);
    
    
    //If the interval has passed
    unsigned long currentMillis = millis();
    if(currentMillis - previousMillis > buttonCheckInterval)
    {
       previousMillis = currentMillis;
       //If we press the button for less than 200ms, button1_pressed is set to 1, otherwise, it's set to 2
         if (buttonState == HIGH)
         {
           if(button1_pressed_old == 0) button1_pressed=1;
           else button1_pressed=2;
         }
         
         //The same for the second button
         
         if (buttonState2 == HIGH)
         {
           if(button2_pressed_old == 0) button2_pressed=1;
           else button2_pressed=2;
         }
    }
    
    //Check if it's time to decide wether we have a momentary press, a press-and-hold, or nothing
      if(currentMillis - previousMillis2 > buttonCheckInterval*5)
    {
       previousMillis2 = currentMillis;   
       
       //if button1_pressed is 2, then we have pressed and held the button, and go to state 1
       //. If 1, then we pressed it for less than 200ms (momentarily), and go to state 2.
       if(button1_pressed == 2) FSM_State = 1; //digitalWrite(ledPin, HIGH);
       else if(button1_pressed_old == 1) FSM_State = 2;
       button1_pressed_old = button1_pressed;
       button1_pressed = 0;
       
       //Do the same for button2
       if(button2_pressed == 2) FSM_State = 3; //digitalWrite(ledPin, HIGH);
       else if(button2_pressed_old == 1) FSM_State = 4;
       button2_pressed_old = button2_pressed;
       button2_pressed = 0;
    }
  }
  else if(FSM_State == 1)
  {
    //Check if we still hold the button every 100ms. If so, keep powering the LED and shutters.
    //Otherwise, go to state 0 (idle)
    unsigned long currentMillis = millis();
    if(currentMillis - previousMillis > buttonCheckInterval)
    {
       previousMillis = currentMillis;   
       buttonState = digitalRead(buttonPin);
      if(buttonState == HIGH) 
      {
        digitalWrite(ledPin, HIGH);
        digitalWrite(ledPin2, LOW);
      }
      else
      {
        digitalWrite(ledPin, LOW);
        FSM_State = 0;
      }
    }
  }
    else if(FSM_State == 2)
  {
    digitalWrite(ledPin, HIGH);
    digitalWrite(ledPin2, LOW);
    unsigned long currentMillis = millis();
    
    //In case the 2nd button is pressed, go to state 5
    if(currentMillis - previousMillis > buttonCheckInterval)
    {
       previousMillis = currentMillis;   
       buttonState2 = digitalRead(buttonPin2);
      if(buttonState2 == HIGH) FSM_State = 5;
    }
    //If we reached our count to 30, go to state 0
    if(currentMillis - previousMillis2 > time_to_light)
    {
       previousMillis2 = currentMillis;   
       digitalWrite(ledPin, LOW);
       FSM_State = 0;
    }
  }
  //The same as state 1, for the second button
    else if(FSM_State == 3)
  {
    unsigned long currentMillis = millis();
    if(currentMillis - previousMillis > buttonCheckInterval)
    {
       previousMillis = currentMillis;   
       buttonState2 = digitalRead(buttonPin2);
      if(buttonState2 == HIGH) 
      {
        digitalWrite(ledPin2, HIGH);
        digitalWrite(ledPin, LOW);
      }
      else
      {
        digitalWrite(ledPin2, LOW);
        FSM_State = 0;
      }
    }
  }
  //The same as state 2, for the second button
    else if(FSM_State == 4)
  {
    digitalWrite(ledPin2, HIGH);
    digitalWrite(ledPin, LOW);
    unsigned long currentMillis = millis();
    
    if(currentMillis - previousMillis > buttonCheckInterval)
    {
       previousMillis = currentMillis;   
       buttonState = digitalRead(buttonPin);
      if(buttonState == HIGH) FSM_State = 5;
    }
    
    if(currentMillis - previousMillis2 > time_to_light)
    {
       previousMillis2 = currentMillis;   
       digitalWrite(ledPin2, LOW);
       FSM_State = 0;
    }
  }
  //This state exists so that we can have enough time to release the button if we want to
  //momentarily press the button to go from 2 or 4 to 0.
  else if(FSM_State == 5)
  {
    unsigned long currentMillis = millis();
    if(currentMillis - previousMillis > (buttonCheckInterval * 3))
    {
      previousMillis = currentMillis;   
      FSM_State = 0;
    }
  }
  
    if (Serial.available())
    {
      char bla = (char) Serial.read();
      if(bla == OPEN) FSM_State = 2;
      else if(bla == CLOSE) FSM_State = 4;
      else if(bla == HALT) FSM_State = 0;
  }
  delay(100);
}

