/*
XBeeRadio.h - Library for communicating with heterogenous 802.15.4 networks.
	Created by Vasileios Georgitzikis, November 23, 2010.
*/

#include "WProgram.h"
#include "HomeAuto.h"

HomeAuto::HomeAuto()
{
	init(LIGHT_PIN, NO_SWITCH);
}

HomeAuto::HomeAuto(int light_pin)
{
	init(light_pin, NO_SWITCH);
}

HomeAuto::HomeAuto(int light_pin, int light_switch)
{
	init(light_pin, light_switch);
}

void HomeAuto::init(int light_pin, int light_switch)
{
	this->light_pin = light_pin;
	this->light_switch = light_switch;
	//the starting states are LOW
	lastSwitchState = LOW;
	lightState = LOW;    	
}

void HomeAuto::setup(void)
{
	do_setup(DEFAULT_BAUDRATE);
}

void HomeAuto::setup(long baudrate)
{
	do_setup(baudrate);
}

void HomeAuto::do_setup(long baudrate)
{
	//set thepins as input and output
	pinMode(light_pin, OUTPUT);
	if(light_switch > 1)
	{
		pinMode(light_switch, INPUT);
		//check the light switch, and set it as the starting state
		//We do not care what state the light switch is in. We simply want
		//to check for changes in it state, so as to change the state of the
		//light accordingly. AKA if the light is on, and the lightSwitch is off
		//and changes to on, we turn the light off. This is done because the
		//two states are irrelevant, as the light can also be turned on and off
		//by the XBee remote.
		lastSwitchState = digitalRead(light_switch);
	}

	//Start the serial and inform everyone we are turned on
	Serial.begin(baudrate);
	Serial.print(STARTING, BYTE);
}

void HomeAuto::check(void)
{
	checking_externally = false;
	external_light_status = lightState;
	do_check();
}

void HomeAuto::check(bool external_status)
{
	checking_externally = true;
	external_light_status = external_status;
	do_check();
}

void HomeAuto::do_check()
{
	//initialize timestamp variables
	static unsigned long timestamp = 0;
	static unsigned long broadcastTimestamp = 0;
	static unsigned long changeCheckTimestamp = 0;
	static bool old_light_status = 0;

	if(light_switch > 1 && millis() - timestamp > period)
	{
		//if it's time to check the button, do so
		sampleButton();
		timestamp=millis();
	}
	
	if(millis() - changeCheckTimestamp > changeCheckPeriod)
	{
		if(old_light_status != external_light_status)
		{
			old_light_status = external_light_status;
			broadcastState();				
		}
		changeCheckTimestamp = millis();
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

//Set the light to the value we are given
void HomeAuto::setLight(bool value)
{
	//update the state, turn the pin on or off accordingly,
	//and let everyone in the network know we have changed state
	digitalWrite(light_pin, value);	
	lightState = value;
	// Serial.print("Light is ");
	// Serial.println(lightState, DEC);
	// broadcastState();
}

void HomeAuto::sampleButton(void)
{
  //check the current state
  int currentSwitchState = digitalRead(light_switch);
  if(currentSwitchState != lastSwitchState)
  {
    //if the state has changed, reverse the light's state
    lastSwitchState = currentSwitchState;
    setLight(!lightState);
  }
}

//let the world know our current state
void HomeAuto::broadcastState(void)
{
	int status_report = checking_externally ? external_light_status : lightState;
	
	if(status_report)
		Serial.print(STATE_ON, BYTE);
	else
		Serial.print(STATE_OFF, BYTE);
}

//this is our listener function
void HomeAuto::checkForMessages(void)
{
    if (int avail_bytes = Serial.available())
    {
      for(int i=0; i< avail_bytes; i++)
      {
        //if we have input, and that input is either OPEN or CLOSE,
        //then do so accordingly
        char bla = (char) Serial.read();
		int newState = -1;
		if(bla == OPEN) newState = 1;
        else if(bla == CLOSE) newState = 0;
		
		if(newState != -1)
		{
			if(lightState xor external_light_status)
				setLight(!newState);
			else
				setLight(newState);		
		}
      }
    }
}

Shutters::Shutters(int light_pin1, int light_pin2, int light_switch1, int light_switch2)
{
	init(light_pin1, light_pin2, light_switch1, light_switch2);
}


void Shutters::setup(void)
{
	do_setup(DEFAULT_BAUDRATE);
}
void Shutters::setup(long baudrate)
{
	do_setup(baudrate);
}
void Shutters::check(void)
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

void Shutters::init(int light_pin1, int light_pin2, int light_switch1, int light_switch2)
{
	ledPin = light_pin1;
	ledPin2 = light_pin2;
	buttonPin = light_switch1;
	buttonPin2 = light_switch2;
}

void Shutters::handleFSM(int currentButtonState)
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


int Shutters::checkForButtons(void)
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

void Shutters::checkForMessages(void)
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
void Shutters::broadcastState(void)
{
  Serial.print(ourState, BYTE);
}

void Shutters::do_setup(long baudrate)
{
	
	FSM_State = 0;
	ourState = STATE_UNDEF;
	// initialize the LED pins as an outputs:
  pinMode(ledPin, OUTPUT);      
  pinMode(ledPin2, OUTPUT);      
  // initialize the pushbutton pins as an inputs:
  pinMode(buttonPin, INPUT);     
  pinMode(buttonPin2, INPUT);   

  //XBee shit from now on
  Serial.begin(baudrate);
  Serial.print(STARTING, BYTE);
}
