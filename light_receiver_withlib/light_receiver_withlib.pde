#include <HomeAuto.h>

HomeAuto wtf = HomeAuto(2,4);
//include the definitions for the messages we will be sending
#include <ethernet_xbee_defs.h>

void setup()
{
  pinMode(7, INPUT);
  digitalWrite(7, HIGH);
  wtf.setup(57600);
}

void loop()                     
{
  bool state = digitalRead(7);
  wtf.check(state);
}
