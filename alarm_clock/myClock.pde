/*
Arduino Alarm Clock with iPod control and XBee remote command sending by Vasileios Georgitzikis

*/
/*
Some code is taken from the open-source clock for Arduino by(cc) by Rob Faludi, http://www.faludi.com
*/
#include <XBee.h>
#include <LiquidCrystal.h>

#define FIRST_TARGET 0x7267
#define SECOND_TARGET 0x7B8B

uint8_t payload[] = { 36 }; //36 is the number we use fo OPEN
Tx16Request tx1 = Tx16Request(FIRST_TARGET, payload, sizeof(payload));
Tx16Request tx2 = Tx16Request(SECOND_TARGET, payload, sizeof(payload));

XBee xbee = XBee();
// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

const int ledPin  = 13;
const int setPin = 6;
const int selectionPin = 7;
const int alarmPin = 8;

const int buzzerPin = 9;

bool makeNoise = false;

int selectionState = LOW;
int setState = LOW;
int oldSelState = LOW;
int oldSetState = LOW;
unsigned long selectionTimestamp;
const int selectionWaitingSeconds = 10;

String weekdays[] = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};

// include the library code:


int second=0, minute=0, hour=0, weekday=0; // declare time variables
// these time variables are declared globally so they can be used ANYWHERE in your program

int alarmMinute = 0, alarmHour=0;

int nothing;
int *whatToChange = &nothing;
int cursorX = 0, cursorY = 0;

bool alarmActive = true;
int alarmWeekdays[] = {true, true, true, true, true, false, false};
void setup()
{
  pinMode(ledPin, OUTPUT);
  pinMode(setPin, INPUT);
  pinMode(selectionPin, INPUT);
  pinMode(alarmPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  
  xbee.begin(57600);
  //Serial.begin(9600);
  lcd.begin(16, 2);
  blinkLED(ledPin, 13, 100); // blink an LED at the start of the program, to show the code is running
}

void loop() {

  static unsigned long lastTick = 0;
  static unsigned long lastRefresh = 0;
  static unsigned long buttonTick = 0;
  // set up a local variable to hold the last time we moved forward one second
  // (static variables are initialized once and keep their values between function calls)
  
  // move forward one second every 1000 milliseconds
  if (millis() - lastTick >= 1000)
  {
    lastTick = millis();
    second++;
  }
  
  if (millis() - lastRefresh >= 300)
  {
    lastRefresh = millis();
    lcdOutput();
  }
  
  if((whatToChange != &nothing) && (millis() - selectionTimestamp > selectionWaitingSeconds * 1000))
  {
    whatToChange = &nothing;
  }
  
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
    checkAlarm();
  }
  
  if (millis() - buttonTick >= 100)
  {
    buttonTick = millis();
    checkButtons(); // runs a function that checks the setting buttons
  }
}

void playSpeaker() {
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

void checkAlarm(void)
{
  //Serial.println("Checking Alarm");
  if(alarmActive && hour == alarmHour && minute == alarmMinute && alarmWeekdays[weekday])
  {
    //Serial.println("Starting Alarm");
    //analogWrite(buzzerPin, 125);
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
    //Serial.println("Stopping Alarm");
    //digitalWrite(buzzerPin, LOW);
    makeNoise = false;
  }
}

void increaseShit()
{
  if(whatToChange == &nothing) return;
  
  int limit;
  if(whatToChange == &minute ||  whatToChange == &alarmMinute)
    limit = 60;
  else if(whatToChange == &hour || whatToChange == &alarmHour)
    limit = 24;
  else if(whatToChange == &weekday)
    limit = 7;
  else if(whatToChange == &alarmWeekdays[0] || whatToChange == &alarmWeekdays[1] || whatToChange == &alarmWeekdays[2] || whatToChange == &alarmWeekdays[3]\
           || whatToChange == &alarmWeekdays[4] || whatToChange == &alarmWeekdays[5] || whatToChange == &alarmWeekdays[6])
    limit = 2;
  (*whatToChange)++;
  if(*whatToChange == limit)
    *whatToChange = 0;
}

void checkButtons()
{
  selectionState = digitalRead(selectionPin);
  setState = digitalRead(setPin);  
  
  if(oldSelState != selectionState && selectionState == HIGH)
  {
    //Serial.println("Selection Pin Pressed");
    if(!makeNoise)
    {
      selectNext();
      selectionTimestamp = millis();      
    }
    makeNoise = false;
  }

  if(oldSetState != setState && setState == HIGH)
  {
    //Serial.println("Set Pin Pressed");
    if(!makeNoise)
    {
      increaseShit();
      selectionTimestamp = millis();
    }
    makeNoise = false;
  }
  oldSelState = selectionState;
  oldSetState = setState;
  
  alarmActive = digitalRead(alarmPin);
}

void printNumber(int number)
{
  if(number < 10)
    lcd.print("0");
  lcd.print(number);
}

void lcdOutput()
{
  
  static bool blinkCursor = true;
  // this function creates a clock you can read through the serial port
  // your clock project will have a MUCH more interesting way of displaying the time
  // get creative!
  
  //lcd.clear();
  lcd.setCursor(0,0);
  lcd.print(weekdays[weekday]); // picks the right word to print for the weekday
  
  for(int i = 0 ; i < 8 - weekdays[weekday].length() ; i ++)
  {
    lcd.print(" ");
  }
  printNumber(hour);
  lcd.print(":"); // a colon between the hour and the minute
  printNumber(minute);
  lcd.print(":"); // a colon between the minute and the second
  printNumber(second);
  
    //lcd.noCursor();
    //lcd.cursor();
  
  lcd.setCursor(0, 1);
  for(int i = 0; i < 7 ; i++)
  {
    if(alarmWeekdays[i])
      lcd.print(weekdays[i].charAt(0));
    else
      lcd.print("-");
  }
  lcd.print(" ");
  printNumber(alarmHour);
  lcd.print(":");
  printNumber(alarmMinute);
  if(alarmActive)
  {
    lcd.print(" AL");
  }
  else
    lcd.print("   ");
  
  lcd.setCursor(cursorX, cursorY);
  if(whatToChange != &nothing)
  {
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

