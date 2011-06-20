/*
  XBeeRadio.h - Library for communicating with heterogenous 802.15.4 networks.
  Created by Vasileios Georgitzikis, November 23, 2010.
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
	const static int LIGHT_SWITCH = 0;
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

#endif


