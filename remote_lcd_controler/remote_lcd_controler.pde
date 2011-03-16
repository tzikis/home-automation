// (c) adafruit industries - public domain!

//Include the graphic LCD's library, our message definition library, and the XBee library
#include "ST7565.h"
#include <ethernet_xbee_defs.h>
#include <XBee.h>

#include "tzikis_blackwhite_glcd.h"

//create our xbee object
XBee xbee = XBee();

int ledPin =  13;    // LED connected to digital pin 13

#define BACKLIGHT_LED 10
// The setup() method runs once, when the sketch starts

//setup our LCD's pins
ST7565 glcd(9, 8, 7, 6, 5);

int menu_pos=0;

const int buttonPin = 4;     // the number of the pushbutton pin
const int selectPin = 3;     // the number of the pushbutton pin
const int buttonPin2 = 2;     // the number of the pushbutton pin

//Defining XBee addresses. We're using 3
#define FIRST_TARGET 0x7267
#define SECOND_TARGET 0x7B8B
#define THIRD_TARGET 0x2b69

//menu size
const int menu_size = 8;

//we are using a structure for each menu item, which holds the menu's string,
//the target xbee, and related the command we're supposed to send when selecting it
struct menu_item
{
  char* menu_string;
  uint16_t target;
  char command;
};

////We're initializing the commands, targets, and strings for all menu items
struct menu_item menu_items[] =
{
  {"Shutter 1 - Open", FIRST_TARGET, OPEN},
  {"Shutter 1 - Close", FIRST_TARGET, CLOSE},
  {"Shutter 1 - Stop", FIRST_TARGET, HALT},
  {"Shutter 2 - Open", SECOND_TARGET, OPEN},
  {"Shutter 2 - Close", SECOND_TARGET, CLOSE},
  {"Shutter 2 - Stop", SECOND_TARGET, HALT},
  {"Bath Light - Open", THIRD_TARGET, OPEN},
  {"Bath Light - Close", THIRD_TARGET, CLOSE}//,
//  {"Shutter 1 - Open", FIRST_TARGET, OPEN},
//  {"Shutter 1 - Close", FIRST_TARGET, CLOSE},
//  {"Shutter 1 - Stop", FIRST_TARGET, HALT}
};  

//select the symbol we'll be using for our selector by defining the appropriate macro.
//ARROW for an arrow, STAR for a star, and.... nothing for a surprise :P
#define ARROW

#ifdef STAR
  #define SEL_STAR '*'
  #define SEL_BLK  ' '
#else
  #ifdef ARROW
    #define SEL_STAR 16
    #define SEL_BLK  ' '
  #else
    #define SEL_STAR 7
    #define SEL_BLK  9
  #endif
#endif


void setup()   {                
  //Serial.print(freeRam());
  
  //set our buttons as inputs
  pinMode(buttonPin, INPUT);     
  pinMode(selectPin, INPUT);     
  pinMode(buttonPin2, INPUT);    
 
  //enable the backlight
  pinMode(BACKLIGHT_LED, OUTPUT);
  digitalWrite(BACKLIGHT_LED, HIGH);
  
  //initialise our lcd
  glcd.st7565_init();
  glcd.st7565_command(CMD_DISPLAY_ON);
  glcd.st7565_command(CMD_SET_ALLPTS_NORMAL);
  glcd.st7565_set_brightness(0x18);

  //show adafruit's splashscreen, cause it's cool :P
  glcd.display(); // show splashscreen
  delay(300);
  //clear the splashscreen
  glcd.clear();
  
  //show my splashscreen, cause its WAY COOLER!
  delay(100);
  glcd.drawbitmap(0, 0, tzikis_blackwhite_glcd_bmp, TZIKIS_BLACKWHITE_GLCD_WIDTH, TZIKIS_BLACKWHITE_GLCD_HEIGHT, BLACK);
  glcd.display();
  
  //let it be there for a sec
  delay(1000);
  
  //display our menu
  display_menu();
  
  //start our XBee
  xbee.begin(57600);
}


void loop()                     
{
    //check our buttons
    int pressedButton = checkButtons();
    //if up or down was pressed, move the cursor. if select was pressed
    //send our message and flash our menu
    if(pressedButton == 1)
    {
      if(menu_pos<menu_size-1) menu_pos++;
      display_menu();
    }
    else if(pressedButton ==2)
    {
      if(menu_pos>0) menu_pos--;
      display_menu();
    }
    else if(pressedButton == 3)
    {
      sendMessage(menu_items[menu_pos].target,menu_items[menu_pos].command);
      flash_menu(200, 2);
    }
}

//check the state of the buttons
int checkButtons(void)
{
  //these variables carry the state, and the previous state of each of our three buttons (up, down, select)
  static int buttonState = 0, buttonOldState = 0;
  static int buttonState2 = 0, buttonOldState2 = 0;
  static int selectState = 0, selectOldState = 0;
  
  //the response we'll be returning
  int response = 0;

  //timestamp stores the last time we checked for a pressed button
  static unsigned long timestamp = 0;
  //the interval for checking the state of the buttons
  const unsigned long interval = 50; 
  if(millis() - timestamp > interval)
  {
    // save the last time you blinked the LED 
    timestamp = millis();   
    //Read the buttons
    buttonState = digitalRead(buttonPin);
    selectState = digitalRead(selectPin);
    buttonState2 = digitalRead(buttonPin2);
    
    // check if the pushbutton was just pressed
    if (buttonState == HIGH && buttonOldState == LOW)
      response = 1;
    else if (buttonState2 == HIGH && buttonOldState2 == LOW)
      response = 2;
    else if (selectState == HIGH && selectOldState == LOW)
      response = 3;
    
    //update the old state
    buttonOldState = buttonState;
    selectOldState = selectState;
    buttonOldState2 = buttonState2;
  }
  //return our response (0 if none was pressed, 1 for down, 2 for up, 3 for select)
  return response;
}

//display our menu
void display_menu(void)
{
  //first, clear the screen
  glcd.clear();
  
  //this is voodoo. no need to understand it
  int page = (menu_pos/8);
  for(int i = page*8; (menu_size - menu_pos < 8) && (menu_size/8 == page) ? i < menu_size : i < 8*(page+1) ; i++)
  {
    glcd.drawstring(6, i - page*8, menu_items[i - page*8].menu_string);    
  }
  
  //if we have more than one pages, show them to the user!
  if(menu_size > 8)
  {
    //draw a circle on the top right for each page, and fill the circle for the page we're in
    for(int i = 0; i <= menu_size/8; i++)
    {
      if(i == page) //glcd.drawchar(122, i, 7);
        glcd.fillcircle(124, 3*(2*i+1), 2, BLACK);
      else //glcd.drawchar(122, i, 9);
        glcd.drawcircle(124, 3*(2*i+1), 2, BLACK);
      }
  }
  //draw the selection character on the right line
  glcd.drawchar(0, menu_pos%8, SEL_STAR);
  
  //display our screen
  glcd.display();  
}


//flash our menu selector, for delayTime miliseconds,
//and times times :)
void flash_menu(int delayTime, int times)
{
  for(int i = 0; i < times ; i++)
  {
    glcd.drawchar(0, menu_pos,SEL_BLK);
    glcd.display();
    delay(delayTime/times/2);
    glcd.drawchar(0, menu_pos,SEL_STAR);
    glcd.display();
    delay(delayTime/times/2);
  }
}

//send our message, which contains 'what', to 'where'
void sendMessage(int where, int what)
{
      uint8_t payload[] = { what };
      Tx16Request tx = Tx16Request(where, payload, sizeof(payload));
      TxStatusResponse txStatus = TxStatusResponse();
      xbee.send(tx);
      if (xbee.readPacket(5000))
      {
        // got a response!
        // should be a znet tx status            	
    	if (xbee.getResponse().getApiId() == TX_STATUS_RESPONSE)
        {
    	   xbee.getResponse().getZBTxStatusResponse(txStatus);
    		
    	   // get the delivery status, the fifth byte
           if (txStatus.getStatus() == SUCCESS)
           {
            	// success.  time to celebrate
             	//flashLed(statusLed, 5, 50);
           }
           else
           {
            	// the remote XBee did not receive our packet. is it powered on?
             	//flashLed(errorLed, 3, 500);
           }
        }      
      }
}

//this was here from the example, but it's useful sometimes. you can safely ignore it
// this handy function will return the number of bytes currently free in RAM, great for debugging!   

//int freeRam(void)
//{
//  extern int  __bss_end; 
//  extern int  *__brkval; 
//  int free_memory; 
//  if((int)__brkval == 0) {
//    free_memory = ((int)&free_memory) - ((int)&__bss_end); 
//  }
//  else {
//    free_memory = ((int)&free_memory) - ((int)__brkval); 
//  }
//  return free_memory; 
//} 


//this was here from the example, but it's a cool idea for visualization. you can safely ignore it

//void testdrawline() {
//  for (uint8_t i=0; i<128; i+=4) {
//    glcd.drawline(0, 0, i, 63, BLACK);
//  }
//  for (uint8_t i=0; i<64; i+=4) {
//    glcd.drawline(0, 0, 127, i, BLACK);
//  }
//
//  glcd.display();
//  delay(1000);
//
//  for (uint8_t i=0; i<128; i+=4) {
//    glcd.drawline(i, 63, 0, 0, WHITE);
//  }
//  for (uint8_t i=0; i<64; i+=4) {
//    glcd.drawline(127, i, 0, 0, WHITE);
//  }
//}
