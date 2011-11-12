#include <HomeAuto.h>

Shutters wtf = Shutters(2,3,4,5);
//include the definitions for the messages we will be sending
#include <ethernet_xbee_defs.h>

void setup()
{
  wtf.setup(57600);
  wtf.setPullUpButtons(true);
}

void loop()
{
  wtf.check();
}



