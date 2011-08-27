#include <XBee.h>

XBee xbee = XBee();

const int buttonPin = 5;
// variables will change:
int buttonState = 0;         // variable for reading the pushbutton status
int oldButtonState = 0;

#define ARRAY_LEN(array) (sizeof(array) / sizeof(array[0]))
static const byte ipod_on[] = {0x02, 0x00, 0x00, 0x00, 0x08};
static const byte play[] = {0x02, 0x00, 0x01};
static const byte button_released[] = {0x02, 0x00, 0x00};

void setup()
{
  xbee.begin(19200);
  pinMode(buttonPin, INPUT);

}

void loop()
{
  // read the state of the pushbutton value:
  buttonState = digitalRead(buttonPin);
  // check if the pushbutton is pressed.
  if (buttonState == HIGH && buttonState != oldButtonState)
  {
    sendCommandWithLength(ARRAY_LEN(ipod_on), ipod_on);
    sendCommandWithLength(ARRAY_LEN(button_released), button_released);
    sendCommandWithLength(ARRAY_LEN(play), play);    
    sendCommandWithLength(ARRAY_LEN(button_released), button_released);
  }
  oldButtonState = buttonState;

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


