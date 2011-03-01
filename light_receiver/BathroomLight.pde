#include <XBee.h>
#include <ethernet_xbee_defs.h>

//uint8_t payload[] = { 0 };
//XBee xbee = XBee();
//XBeeResponse response = XBeeResponse();
//Rx16Response rx16 = Rx16Response();
//Tx16Request tx = Tx16Request(0xffff, payload, sizeof(payload));

const int period = 100;
const unsigned broadcastPeriod = 60000;
const int lightSwitch = 4;
const int lightPin = 2;

int lastSwitchState = LOW;
bool lightState = LOW;

void setup()
{
  pinMode(lightPin, OUTPUT);
  pinMode(lightSwitch, INPUT);
  lastSwitchState = digitalRead(lightSwitch);
  
  Serial.begin(57600);
//  xbee.begin(57600);
  Serial.print(STARTING, BYTE);
}

void setLight(bool value)
{
  lightState = value;
  digitalWrite(lightPin, lightState);
  broadcastState();
}

void sampleButton(void)
{
  int currentSwitchState = digitalRead(lightSwitch);
  if(currentSwitchState != lastSwitchState)
  {
    lastSwitchState = currentSwitchState;
    setLight(!lightState);
  }
}

void broadcastState(void)
{
  if(lightState)
    Serial.print(STATE_ON, BYTE);
  else
    Serial.print(STATE_OFF, BYTE);
  /*
  mySerial.println("Broadcasting State");
  if(lightState)
  {
    payload[0] = STATE_ON;
  }
  else
  {
    payload[0] = STATE_OFF;
  }
  
  TxStatusResponse txStatus = TxStatusResponse();
  xbee.send(tx);
  if (xbee.readPacket(50))
  {
    mySerial.println("Got response");
    // got a response, should be a znet tx status            	
    if (xbee.getResponse().getApiId() == TX_STATUS_RESPONSE)
    {
      xbee.getResponse().getZBTxStatusResponse(txStatus);
      	
      // get the delivery status, the fifth byte
      if (txStatus.getStatus() == SUCCESS)
      {
        mySerial.println("All is well");
        // success.  time to celebrate
      }
      else
      {
        // the remote XBee did not receive our packet. is it powered on?
      }
    }      
  }
  */
}

void checkForMessages(void)
{
    if (Serial.available())
    {
      char bla = (char) Serial.read();
      if(bla == OPEN) setLight(HIGH);
      else if(bla == CLOSE) setLight(LOW);
    }
      /*
  xbee.readPacket();
  if (xbee.getResponse().isAvailable())
  {
    // got something
    mySerial.println("Got something");
    if (xbee.getResponse().getApiId() == RX_16_RESPONSE || xbee.getResponse().getApiId() == RX_64_RESPONSE)
    {
      mySerial.println("Got nice packet");
      // got a rx packet
      xbee.getResponse().getRx16Response(rx16);
      int data = rx16.getData(0);
      if(data == OPEN) setLight(HIGH);
      else if(data == CLOSE) setLight(LOW);
    }
    else
    {
      // not something we were expecting
    }
  }
  */
}
void loop()                     
{
  static unsigned long timestamp = 0;
  static unsigned long broadcastTimestamp = 0;
  
  if(millis() - timestamp > period)
  {
    sampleButton();
    timestamp=millis();
  }
  
  if(millis() - broadcastTimestamp > broadcastPeriod)
  {
    broadcastTimestamp = millis();
    broadcastState();
  }
  
  checkForMessages();
}
