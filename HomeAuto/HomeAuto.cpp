/*
XBeeRadio.h - Library for communicating with heterogenous 802.15.4 networks.
	Created by Vasileios Georgitzikis, November 23, 2010.
*/

#include "WProgram.h"
#include "HomeAuto.h"

HomeAuto::HomeAuto()
{
	init(LIGHT_PIN, LIGHT_SWITCH);
}

HomeAuto::HomeAuto(int light_pin)
{
	init(light_pin, LIGHT_SWITCH);
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


