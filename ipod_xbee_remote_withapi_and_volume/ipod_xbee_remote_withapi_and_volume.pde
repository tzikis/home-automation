#include <XBee.h>

XBee xbee = XBee();

const int buttonPin = 5;
const int upButtonPin = 7;
const int downButtonPin = 6;
// variables will change:
int buttonState = 0, upButtonState = 0, downButtonState = 0;         // variable for reading the pushbutton status
int oldButtonState = 0, oldUpButtonState = 0, oldDownButtonState = 0;

#define ARRAY_LEN(array) (sizeof(array) / sizeof(array[0]))
static const byte ipod_on[] = {0x02, 0x00, 0x00, 0x00, 0x08};
static const byte play[] = {0x02, 0x00, 0x01};
static const byte button_released[] = {0x02, 0x00, 0x00};
static const byte vol_up[] = {0x02, 0x00, 0x02};
static const byte vol_down[] = {0x02, 0x00, 0x04};

void setup()
{
  xbee.begin(19200);
  pinMode(buttonPin, INPUT);
  digitalWrite(buttonPin, HIGH);
  pinMode(upButtonPin, INPUT);
  digitalWrite(upButtonPin, HIGH);
  pinMode(downButtonPin, INPUT);
  digitalWrite(downButtonPin, HIGH);

}

void loop()
{
  // read the state of the pushbutton value:
  buttonState = digitalRead(buttonPin);
  upButtonState = digitalRead(upButtonPin);
  downButtonState = digitalRead(downButtonPin);
  // check if the pushbutton is pressed.
  if (buttonState == LOW && buttonState != oldButtonState)
  {
    sendCommandWithLength(ARRAY_LEN(ipod_on), ipod_on);
    sendCommandWithLength(ARRAY_LEN(button_released), button_released);
    sendCommandWithLength(ARRAY_LEN(play), play);    
    sendCommandWithLength(ARRAY_LEN(button_released), button_released);
  }
  else if (upButtonState == LOW && upButtonState != oldUpButtonState)
  {
    sendCommandWithLength(ARRAY_LEN(ipod_on), ipod_on);
    sendCommandWithLength(ARRAY_LEN(button_released), button_released);
    sendCommandWithLength(ARRAY_LEN(vol_up), vol_up);    
    sendCommandWithLength(ARRAY_LEN(button_released), button_released);
  }
  else if (downButtonState == LOW && downButtonState != oldDownButtonState)
  {
    sendCommandWithLength(ARRAY_LEN(ipod_on), ipod_on);
    sendCommandWithLength(ARRAY_LEN(button_released), button_released);
    sendCommandWithLength(ARRAY_LEN(vol_down), vol_down);    
    sendCommandWithLength(ARRAY_LEN(button_released), button_released);
  }
  
  oldButtonState = buttonState;
  oldUpButtonState = upButtonState;
  oldDownButtonState = downButtonState;
}

byte* sendCommandWithLength(size_t length, const byte *pData)
{
    byte* buffer;
    buffer = (byte*) malloc(sizeof(byte) * (length + 4));
    buffer[0] = 0xFF;
    buffer[1] = 0x55;
    buffer[2] = length;
    int checksum = length;

    for (size_t i = 0; i < length; i++)
    {
        buffer[i+3] = pData[i];
        checksum +=pData[i];
    }
    buffer[length+3] = (0x100 - checksum) & 0xFF;
    
//    for(int i = 0; i < length + 4; i++)
//      Serial.print(buffer[i]);

    Tx16Request txRequest = Tx16Request(0xFFFF, buffer, length+4);
    xbee.send(txRequest);
    if (xbee.readPacket(200))
    {
      //Do nothing, we just got a response telling us the packet was sent
    }
    delay(50);
    
}


