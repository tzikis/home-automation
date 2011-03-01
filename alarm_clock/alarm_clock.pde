/*
Arduino Alarm Clock with iPod control and XBee remote command sending by Vasileios Georgitzikis

*/
/*
Some code is taken from the open-source clock for Arduino by(cc) by Rob Faludi, http://www.faludi.com
*/
//Includes XBee.h in order to use the xbee-arduino API, and LiquidCrystal.h to use the LCD
#include <XBee.h>
#include <LiquidCrystal.h>

//Defining the two XBees' addresses in order to send the 'Open' command only to them
//I am using 16bit addresses for the xbees, and I have set these as MY on the receiving XBee's
#define FIRST_TARGET 0x7267
#define SECOND_TARGET 0x7B8B

//The following variables are declared globally so they can be used ANYWHERE in your program

uint8_t payload[] = { 36 }; //36 is the number we use fo OPEN

//Make a Tx16Request for each node we will be sending data to
Tx16Request tx1 = Tx16Request(FIRST_TARGET, payload, sizeof(payload));
Tx16Request tx2 = Tx16Request(SECOND_TARGET, payload, sizeof(payload));

//Initialize the XBee object
XBee xbee = XBee();
//initialize the library with the numbers of the interface pins.
//These are the commonly used pins for the character LCD. For a more detailed
//guide, visit http://www.ladyada.net/learn/lcd/charlcd.html
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

//We are using the built-in LED connected on pin 13 to know
//when our program is starting.
const int ledPin  = 13;
//setPin is the pin used to increase our selection
//selectionPin is the pin used for selecting by iterating between
//hours, minutes, and days of the week
const int setPin = 6;
const int selectionPin = 7;
//AlarmPin is the Pin which enables/disables the alarm
const int alarmPin = 8;
//Finally, buzzerPin has a buzzer connected to it, in order
//to sound the alarm
const int buzzerPin = 9;

//As long as this variable is enabled, we sound the alarm
//by changing values to the buzzer to create a beep beep
//effect with random intervals and pitch
bool makeNoise = false;

//Variables used for keeping the state of our buttons (pressed, unpressed)
//We use the oldX in order to check if a button was just pressed
int selectionState = LOW;
int setState = LOW;
int oldSelState = LOW;
int oldSetState = LOW;
//When setting the time, we want to wait for 10 seconds before automatically
//leaving the setting time mode. For that, we update the selectionTimestamp,
//and when the time since selection timestamp is bigger than 10 seconds, we
//leave selection mode
unsigned long selectionTimestamp;
const int selectionWaitingSeconds = 10;

//The days of the week, in an array
String weekdays[] = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};


int second=0, minute=0, hour=0, weekday=0; // declare time variables

int alarmMinute = 0, alarmHour=0;  //declare alarm variables

//a placeholder variable used to let us know we have selected
//nothing to change, as initialized bellow
int nothing; 
int *whatToChange = &nothing;

//cursorX and cursorY are used in order to blink the cursor in the
//position of the selected value for change (e.g. minutes) on the LCD
int cursorX = 0, cursorY = 0;

//alarm state
bool alarmActive = true;
//initialize days of the week to sound the alarm (weekend is off)
int alarmWeekdays[] = {true, true, true, true, true, false, false};
void setup()
{
  //set ledPin and buzzerPin as outputs, selectionPin, setPin, and alarmPin as inputs
  pinMode(ledPin, OUTPUT);
  pinMode(setPin, INPUT);
  pinMode(selectionPin, INPUT);
  pinMode(alarmPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  
  //Let the xbee-arduino API know our baudrate is 57600
  xbee.begin(57600);
  //Initialize the LCD with the size (ours is 16x2)
  lcd.begin(16, 2);
  blinkLED(ledPin, 13, 100); // blink an LED at the start of the program, to show the code is running
}

void loop()
{
  // (static variables are initialized once and keep their values between function calls)
  //set up a local variable to hold the last time we moved forward one second
  static unsigned long lastTick = 0;
  //set up a local variable to hold the last time we refreshed the LCD

  static unsigned long lastRefresh = 0;
  //set up a local variable to hold the last time we checked the button states
  static unsigned long buttonTick = 0;

  
  // move forward one second every 1000 milliseconds
  if (millis() - lastTick >= 1000)
  {
    lastTick = millis();
    second++;
  }
  
  //We refresh the lcd 3 times per second, for the blinking and showing
  // the correct alarm status (enabled/disabled) fast when it changes
  if (millis() - lastRefresh >= 300)
  {
    lastRefresh = millis();
    //lcdOutput prints our data on the LCD
    lcdOutput();
  }
  
  //As stated above, if 10 seconds have passed without pressing anything 
  //when in selection state, leave selection state 
  if((whatToChange != &nothing) && (millis() - selectionTimestamp > selectionWaitingSeconds * 1000))
  {
    //when whatToChange points to nothing, we are not in selection state (we have selected nothing)
    whatToChange = &nothing;
  }
  
  //if the alarm is sounded, we call playSpeaker wich makes a beeping sound 
  //if the alarm is off, make sure we are silent
  if(makeNoise) playSpeaker();
  else digitalWrite(buzzerPin, LOW);
  
  // move forward one minute every 60 seconds
  if (second > 59)
  {
    minute++;
    second = 0; // reset seconds to zero
    // move forward one hour every 60 minutes
    if (minute > 59)
    {
      hour++;
      minute = 0; // reset minutes to zero
      // move forward one weekday every 24 hours
      if (hour > 23)
      {
        weekday++;
        hour = 0; // reset hours to zero
        // reset weekdays on Saturday
        if (weekday > 6)
        {
          weekday = 0;  
        }
      }
    }
  //since we moved forward one minute, check if we should sound the alarm
    checkAlarm();
  }
  
  //check buttons every 100ms
  if (millis() - buttonTick >= 100)
  {
    buttonTick = millis();
    checkButtons(); // runs a function that checks the setting buttons
  }
}

//playSpeaker is called if we should be sounding the alarm
//it changes state (high/low) every 120-130 seconds to make a beeping sound
//it also uses a random value for HIGH, in order to change pitch in each beep
void playSpeaker()
{
  static unsigned long speakerTime = 0;
  static boolean speakerHigh = false;
  static int nextTime = 130;
  //Serial.println((int)speakerHigh);
  if (millis() - speakerTime >= nextTime) {
    speakerTime = millis();
    speakerHigh = !speakerHigh;
    nextTime = random(120,130);
    if  (speakerHigh == true) {
      //Serial.print("SpeakerHigh is ");
      analogWrite(buzzerPin, random(30, 200));
    } else {
      digitalWrite(buzzerPin, LOW);
    }
  }
}

//This is a simple, albeit long method. We simply select the next
//item in the list. after hour, we select minutes, then alarm_hour,
//alarm_minutes, day, and then days of the week to set the alarm for that day
//we also set the cursor position on the LCD for each value
void selectNext()
{
  if(whatToChange == &nothing)
  {
    whatToChange = &hour;
    cursorX = 9;
    cursorY = 0;
  }
  else if(whatToChange == &hour)
  {
    whatToChange = &minute;
    cursorX = 12;
    cursorY = 0;
  }
  else if(whatToChange == &minute)
  {
    whatToChange = &alarmHour;
    cursorX = 9;
    cursorY = 1;
  }
  else if(whatToChange == &alarmHour)
  {
    whatToChange = &alarmMinute;
    cursorX = 12;
    cursorY = 1;
  }
  else if(whatToChange == &alarmMinute)
  {
    whatToChange = &weekday;
    cursorX = 0;
    cursorY = 0;
  }
  else if(whatToChange == &weekday)
  {
    whatToChange = &alarmWeekdays[0];
    cursorX = 0;
    cursorY = 1;
  }
  else if(whatToChange == &alarmWeekdays[0])
  {
    whatToChange = &alarmWeekdays[1];
    cursorX = 1;
    cursorY = 1;
  }
  else if(whatToChange == &alarmWeekdays[1])
  {
    whatToChange = &alarmWeekdays[2];
    cursorX = 2;
    cursorY = 1;
  }
  else if(whatToChange == &alarmWeekdays[2])
  {
    whatToChange = &alarmWeekdays[3];
    cursorX = 3;
    cursorY = 1;
  } 
  else if(whatToChange == &alarmWeekdays[3])
  {
    whatToChange = &alarmWeekdays[4];
    cursorX = 4;
    cursorY = 1;
  }
  else if(whatToChange == &alarmWeekdays[4])
  {
    whatToChange = &alarmWeekdays[5];
    cursorX = 5;
    cursorY = 1;
  }
  else if(whatToChange == &alarmWeekdays[5])
  {
    whatToChange = &alarmWeekdays[6];
    cursorX = 6;
    cursorY = 1;
  }
  else
    whatToChange = &nothing;
}

//Check if we should sound the alarm
void checkAlarm(void)
{
  if(alarmActive && hour == alarmHour && minute == alarmMinute && alarmWeekdays[weekday])
  {
    //if we should, then set the makeNoise flag to true, and send an 'Open' message to each
    //of our shutters, to let the light shine through
    makeNoise = true;
    xbee.send(tx1);
    if (xbee.readPacket(200))
    {
      //Do nothing, we just got a response telling us the packet was sent
    }
    delay(50);
    xbee.send(tx2);
    if (xbee.readPacket(200))
    {
      //Do nothing, we just got a response telling us the packet was sent
    }
  }
  else if( (hour* 60 + minute) - (alarmHour*60 + alarmMinute) >= 5)
  {
    //if our time is alarm_time + 5 minutes, then stop making noise
    makeNoise = false;
  }
}

void increaseShit()
{
  //we haven't selected anything, so do nothing
  if(whatToChange == &nothing) return;
  
  //set the correct limit for minutes, hours and weeks
  int limit;
  if(whatToChange == &minute ||  whatToChange == &alarmMinute)
    limit = 60;
  else if(whatToChange == &hour || whatToChange == &alarmHour)
    limit = 24;
  else if(whatToChange == &weekday)
    limit = 7;
  //in the last case, we are setting the alarm on/off for each day, so the limit is 2 (on, off)
  else if(whatToChange == &alarmWeekdays[0] || whatToChange == &alarmWeekdays[1] || whatToChange == &alarmWeekdays[2] || whatToChange == &alarmWeekdays[3]\
           || whatToChange == &alarmWeekdays[4] || whatToChange == &alarmWeekdays[5] || whatToChange == &alarmWeekdays[6])
    limit = 2;
  //increment our selection
  (*whatToChange)++;
  //if we've reached the limit, then reset
  if(*whatToChange == limit)
    *whatToChange = 0;
}

//check if any button is pressed, and the status of the alarm switch
void checkButtons()
{
  //read the state of the buttons
  selectionState = digitalRead(selectionPin);
  setState = digitalRead(setPin);  
  
  //if the selection button's state has changed from LOW to HIGH
  if(oldSelState != selectionState && selectionState == HIGH)
  {
    //if we are sounding the alarm, simply turn the alarm off
    if(!makeNoise)
    {
      //else, select the next item, and update our selection timestamp
      //to prevent us from leaving the selection state
      selectNext();
      selectionTimestamp = millis();      
    }
    makeNoise = false;
  }

  if(oldSetState != setState && setState == HIGH)
  {
    //if we are sounding the alarm, simply turn the alarm off
    if(!makeNoise)
    {
      //else, increase our selection, and update our selection timestamp
      //to prevent us from leaving the selection state
      increaseShit();
      selectionTimestamp = millis();
    }
    makeNoise = false;
  }
  //copy the current state to oldstate
  oldSelState = selectionState;
  oldSetState = setState;
  //update the alarm state
  alarmActive = digitalRead(alarmPin);
}

//we use this function to print our numbers for hours, minutes, and seconds
//on the LCD. We want to print a 2-digit number no matter what because
//we want to show 13:03 instead of 13:3. Therefore, if the number we wish
//to print is less than 10, we print a preceding zero
void printNumber(int number)
{
  if(number < 10)
    lcd.print("0");
  lcd.print(number);
}

//used to update the output on the lcd
void lcdOutput()
{
  //blinkCursor is a flag used for... you guessed it, blinking the cursor
  static bool blinkCursor = true;
  //lcd.clear();
  //set the cursor to the beggining of the screen to start printing
  lcd.setCursor(0,0);
  lcd.print(weekdays[weekday]); // picks the right word to print for the weekday
  
  //make sure we print 8 characters no matter what the day's namelength
  for(int i = 0 ; i < 8 - weekdays[weekday].length() ; i ++)
  {
    lcd.print(" ");
  }
  //print the hour, followed by a colon, then the minutes, another colon, and seconds
  printNumber(hour);
  lcd.print(":"); // a colon between the hour and the minute
  printNumber(minute);
  lcd.print(":"); // a colon between the minute and the second
  printNumber(second);
  
  //go to the second line
  lcd.setCursor(0, 1);
  
  //for each weekday, print its first letter if the alarm is active for that day, or
  //a hyphen if not
  for(int i = 0; i < 7 ; i++)
  {
    if(alarmWeekdays[i])
      lcd.print(weekdays[i].charAt(0));
    else
      lcd.print("-");
  }
  //space, the final frontier
  lcd.print(" ");
  
  //like before, print the alarm's hour, a colon, then the alarm minute
  printNumber(alarmHour);
  lcd.print(":");
  printNumber(alarmMinute);
  
  //if the alarm is active print AL, otherwise print spaces
  if(alarmActive)
  {
    lcd.print(" AL");
  }
  else
    lcd.print("   ");
  
  //put the cursor on the selected item's position
  lcd.setCursor(cursorX, cursorY);
  if(whatToChange != &nothing)
  {
    //if we are in selection mode, then if the blink the cursor
    //by reversing its status every 300ms, when we are called
    if(blinkCursor)
    {
      lcd.cursor();
      blinkCursor = false;
    }
    else
    {
      lcd.noCursor();
      blinkCursor = true;
    }
  }
  else
  {
    //if not in selection mode, make sure the cursor is off
    lcd.noCursor();
  }
}

// this utility function blinks the an LED light as many times as requested
void blinkLED(byte targetPin, int numBlinks, int blinkRate)
{
  for (int i=0; i>numBlinks; i++)
  {
    digitalWrite(targetPin, HIGH); // sets the LED on
    delay(blinkRate); // waits for a blinkRate milliseconds
    digitalWrite(targetPin, LOW); // sets the LED off
    delay(blinkRate);
  }
}

