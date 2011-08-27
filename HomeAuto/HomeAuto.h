/*
  	XBeeRadio.h - Library for communicating with heterogenous 802.15.4 networks.
	Created by Vasileios Georgitzikis, November 23, 2010.
	Last edit: August 27, 2011
*/

#ifndef HomeAuto_h
#define HomeAuto_h

#include <ethernet_xbee_defs.h>
#include "WProgram.h"

class HomeAuto
{
public:
	//the period we use for checking the status of the light switch
	const static int period = 100;
	//the period we use when broadcasting our status. currently 1 min.
	const static unsigned broadcastPeriod = 60000;
	//the period we use when using an external sensor, in order to check
	//for a status change, and broadcast it
	const static unsigned changeCheckPeriod = 1000;
	//the default pins for our switch, and the relay
	const static int NO_SWITCH = 0;
	const static int LIGHT_PIN = 2;
	const static long DEFAULT_BAUDRATE = 57600;
	HomeAuto();
	HomeAuto(int light_pin);
	HomeAuto(int light_pin, int light_switch);
	void setup(void);
	void setup(long baudrate);
	void check(void);
	void check(bool external_status);
private:
	bool checking_externally;
	bool external_light_status;
	int light_pin;
	int light_switch;
	int lastSwitchState;
	bool lightState;
	void init(int light_pin, int light_switch);
	void setLight(bool value);
	void sampleButton(void);
	void broadcastState(void);
	void checkForMessages(void);
	void do_setup(long baudrate);
	void do_check();
};


class Shutters
{
public:
	static const int time_to_light = 30000;

	//the period we use when broadcasting our status. currently 1 min.
	const static unsigned broadcastPeriod = 60000;

	const static long DEFAULT_BAUDRATE = 57600;
	
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

	int FSM_State;

	int ourState;

	// set pin numbers:
	int buttonPin;     // the number of the pushbutton pin
	int buttonPin2;     // the number of the 2nd pushbutton pin
	int ledPin;      // the number of the LED pin
	int ledPin2;      // the number of the 2nd LED pin

	void setup(void);
	void setup(long baudrate);
	void check(void);
	Shutters(int light_pin1, int light_pin2, int light_switch1, int light_switch2);
private:
	void init(int light_pin1, int light_pin2, int light_switch1, int light_switch2);
	void handleFSM(int currentButtonState);
	int checkForButtons(void);
	void checkForMessages(void);
	//let the world know our current state
	void broadcastState(void);
	void do_setup(long baudrate);
};
#endif


