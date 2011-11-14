/*
  	XBeeRadio.h - Library for communicating with heterogenous 802.15.4 networks.
	Created by Vasileios Georgitzikis, November 23, 2010.
	Last edit: August 27, 2011
*/

#ifndef HomeAuto_h
#define HomeAuto_h

#include <ethernet_xbee_defs.h>
#include "WProgram.h"

#define BROADCAST_STATE(X,Y) broadcastMessage('R', X, Y)
#define BROADCAST_NAME(X,Y) broadcastMessage('N', X, Y)

typedef struct pins
{
	uint8_t numOfPins;
	uint8_t pinsUsed[5];
} pins;


class Sensor
{
public:
	Sensor();
	Sensor(char name[]);
	char* name;
	virtual pins usedPins();
	virtual void setup();
	virtual void check(void);
	virtual char* getState();
	virtual void setState(char* newState);
	virtual void enablePullups(void);
	bool mustBroadcast;
protected:
	void init(char name[]);	
	bool pullups;

};

class Light: public Sensor
{
public:
	Light(uint8_t pin);
	Light(uint8_t pin, uint8_t pin2);
	Light(char name[], uint8_t pin);
	Light(char name[], uint8_t pin, uint8_t pin2);
	virtual pins usedPins();
	virtual void setup();
	virtual void check(void);
	virtual char* getState();
	virtual void setState(char* newState);
protected:
	const static int period = 100;
	const static int NO_SWITCH = 0;
	uint8_t lightPin;
	int light_switch;
	int lastSwitchState;
	bool lightState;
	void init(char name[], uint8_t pin, uint8_t pin2);
	void setLight(bool value);
	void sampleButton(void);
};

class Shutters: public Sensor
{
public:
	static const int time_to_light = 30000;
	// set pin numbers:
	int buttonPin, buttonPin2;     // the numbers of the pushbutton pins
	int ledPin, ledPin2;      // the numbers of the LED pins
	/**
	// This variable holds the state of our FSM. There are 6 states:
	// 0 - If we press-and-hold button 1, go to state 1.
	//     If we momentarily pressed the 1st button, go to state 2
	//     If we press-and-hold button 2, go to state 3.
	//     If we momentarily pressed the 1st button, go to state 4
	// 
	// 1 - While here, keep opening the shutters.
	//     If we are release the first button, go back to state 0 (stop openning the shutters)
	// 
	// 2 - While here, count to 30 and keep opening the shutters
	//     On the count to 30, go to state 0
	//     If we momentarilly pressed, or press-and-hold the 2nd button, go to state 5
	// 
	// 3 & 4 - The equivalent of 1 and 2, for closing the shutters
	// 
	// 5 - Wait for a while, and go to 0. This is because, sometimes when we momentarily press the button while on 5,
	//     if we went straight to 0, the program could believe the button is momentarily pressed and move to 2 or 4
	// 
	// Notice that we can go from 2 to 3 if press-and-hold the 2nd button, because it will go
	// from 2, to 5, then to 0, then to 3. It will just take a bit longer than expected (less than a second)
	**/
	int FSM_State;
	int ourState;	
	int flipButton;
	Shutters(int light_pin1, int light_pin2, int light_switch1, int light_switch2);
	Shutters(char name[], int light_pin1, int light_pin2, int light_switch1, int light_switch2);
	virtual pins usedPins();
	virtual void setup(void);
	virtual void check(void);
	virtual char* getState();
	virtual void setState(char* newState);
protected:
	void init(char name[], int light_pin1, int light_pin2, int light_switch1, int light_switch2);
	void handleFSM(int currentButtonState);
	int checkForButtons(void);
	void checkForMessages(void);
};


class HomeAuto
{
public:
	//the period we use when broadcasting our status. currently 1 min.
	const static unsigned broadcastPeriod = 60000;
	//the default pins for our switch, and the relay
	const static long DEFAULT_BAUDRATE = 57600;
	char* name;
	HomeAuto();
	HomeAuto(char name[]);
	void setup(void);
	void setup(long baudrate);
	void check(void);
	void addSensor(Sensor* newSensor);
private:
	void broadcastAll();
	void broadcastMessage(char header, uint8_t number, char* state);
	void checkForMessages(void);
	void init(char name[]);
	int sensorsOffset;
	Sensor* sensors[5];
};

#endif


