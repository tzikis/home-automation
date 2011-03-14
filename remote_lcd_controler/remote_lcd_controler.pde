// (c) adafruit industries - public domain!

#include "ST7565.h"
#include <ethernet_xbee_defs.h>
#include <XBee.h>

XBee xbee = XBee();

int ledPin =  13;    // LED connected to digital pin 13

#define BACKLIGHT_LED 10
// The setup() method runs once, when the sketch starts

ST7565 glcd(9, 8, 7, 6, 5);

#define LOGO16_GLCD_HEIGHT 16 
#define LOGO16_GLCD_WIDTH  16 

static unsigned char __attribute__ ((progmem)) logo16_glcd_bmp[]={
0x30, 0xf0, 0xf0, 0xf0, 0xf0, 0x30, 0xf8, 0xbe, 0x9f, 0xff, 0xf8, 0xc0, 0xc0, 0xc0, 0x80, 0x00, 
0x20, 0x3c, 0x3f, 0x3f, 0x1f, 0x19, 0x1f, 0x7b, 0xfb, 0xfe, 0xfe, 0x07, 0x07, 0x07, 0x03, 0x00, };

int menu_pos=0;

const int buttonPin = 4;     // the number of the pushbutton pin
int buttonState = 0;         // variable for reading the pushbutton status
int buttonOldState = 0;

const int selectPin = 3;     // the number of the pushbutton pin
int selectState = 0;         // variable for reading the pushbutton status
int selectOldState = 0;

const int buttonPin2 = 2;     // the number of the pushbutton pin
int buttonState2 = 0;         // variable for reading the pushbutton status
int buttonOldState2 = 0;

long previousMillis = 0; //previousMillis stores the last time we checked for a pressed button
long interval = 50; 

char commands[10];

uint16_t targets[10];

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
  //Serial.begin(9600);

  //Serial.print(freeRam());
  
  pinMode(BACKLIGHT_LED, OUTPUT);
  digitalWrite(BACKLIGHT_LED, HIGH);

  
  glcd.st7565_init();
  glcd.st7565_command(CMD_DISPLAY_ON);
  glcd.st7565_command(CMD_SET_ALLPTS_NORMAL);
  glcd.st7565_set_brightness(0x18);

  glcd.display(); // show splashscreen
  delay(1000);
  glcd.clear();
  
  /*
  testdrawchar();
  glcd.display(); // show splashscreen
  delay(10000);
  glcd.clear();
  */
  
  display_menu();
  
  pinMode(buttonPin, INPUT);     
  pinMode(selectPin, INPUT);     
  pinMode(buttonPin2, INPUT);    
  xbee.begin(57600);
}


void loop()                     
{

    
  unsigned long currentMillis = millis();
  if(currentMillis - previousMillis > interval)
  {
    // save the last time you blinked the LED 
    previousMillis = currentMillis;   
    //Read the buttons
    buttonState = digitalRead(buttonPin);
    selectState = digitalRead(selectPin);
    buttonState2 = digitalRead(buttonPin2);
    
    // check if the pushbutton is pressed.
    // if it is, the buttonState is HIGH:
    if (buttonState == HIGH && buttonOldState == LOW)
    {
      menu_pos++;
      if(menu_pos>7) menu_pos = 7;
      glcd.clear();
      display_menu();

    }
    else if (buttonState2 == HIGH && buttonOldState2 == LOW)
    {
      menu_pos--;
      if(menu_pos<0) menu_pos = 0;
      glcd.clear();
      display_menu();

    }
    else if (selectState == HIGH && selectOldState == LOW)
    {
      //Serial.print(commands[menu_pos]);
      uint8_t payload[] = { 0 };
      payload[0] = commands[menu_pos];
      Tx16Request tx = Tx16Request(targets[menu_pos], payload, sizeof(payload));
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
          
      flash_menu();
    } 
    
    buttonOldState = buttonState;
    selectOldState = selectState;
    buttonOldState2 = buttonState2;
  }

}

void display_menu(void)
{
  commands[0] = OPEN;
  commands[1] = CLOSE;
  commands[2] = HALT;
  
  commands[3] = OPEN;
  commands[4] = CLOSE;
  commands[5] = HALT;
  
  commands[6] = OPEN;
  commands[7] = CLOSE;
  
  #define FIRST_TARGET 0x7267
  #define SECOND_TARGET 0x7B8B
  #define THIRD_TARGET 0x2b69
  
  targets[0] = FIRST_TARGET;
  targets[1] = FIRST_TARGET;
  targets[2] = FIRST_TARGET;
  
  targets[3] = SECOND_TARGET;
  targets[4] = SECOND_TARGET;
  targets[5] = SECOND_TARGET; 

  targets[6] = THIRD_TARGET;
  targets[7] = THIRD_TARGET;  
  
  // draw a string at location (0,0)
  glcd.drawstring(6, 0, "Shutter 1 - Open");
  glcd.drawstring(6, 1, "Shutter 1 - Close");
  glcd.drawstring(6, 2, "Shutter 1 - Stop");
  
  glcd.drawstring(6, 3, "Shutter 2 - Open");
  glcd.drawstring(6, 4, "Shutter 2 - Close");
  glcd.drawstring(6, 5, "Shutter 2 - Stop");      
  glcd.drawstring(6, 6, "Bath Light - Open");
  glcd.drawstring(6, 7, "Bath Light - Close");      
  glcd.drawchar(0, menu_pos, SEL_STAR);
  
  glcd.display();  
}

void flash_menu(void)
{
  glcd.drawchar(0, menu_pos,SEL_BLK);
  glcd.display();
  delay(100);
  glcd.drawchar(0, menu_pos,SEL_STAR);
  glcd.display();
  delay(100);
  glcd.drawchar(0, menu_pos,SEL_BLK);
  glcd.display();
  delay(100);
  glcd.drawchar(0, menu_pos,SEL_STAR);
  glcd.display();
  delay(100);

}

// this handy function will return the number of bytes currently free in RAM, great for debugging!   
int freeRam(void)
{
  extern int  __bss_end; 
  extern int  *__brkval; 
  int free_memory; 
  if((int)__brkval == 0) {
    free_memory = ((int)&free_memory) - ((int)&__bss_end); 
  }
  else {
    free_memory = ((int)&free_memory) - ((int)__brkval); 
  }
  return free_memory; 
} 

void testdrawline() {
  for (uint8_t i=0; i<128; i+=4) {
    glcd.drawline(0, 0, i, 63, BLACK);
  }
  for (uint8_t i=0; i<64; i+=4) {
    glcd.drawline(0, 0, 127, i, BLACK);
  }

  glcd.display();
  delay(1000);

  for (uint8_t i=0; i<128; i+=4) {
    glcd.drawline(i, 63, 0, 0, WHITE);
  }
  for (uint8_t i=0; i<64; i+=4) {
    glcd.drawline(127, i, 0, 0, WHITE);
  }
}
