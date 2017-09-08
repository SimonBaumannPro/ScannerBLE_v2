#include <RN487x_BLE.h>

#define debugSerial SerialUSB //  Port USB
#define bleSerial Serial1 // Bluetooth
#define SERIAL_TIMEOUT  10000

const char* myDeviceName = "testPeriph" ;  // Custom Device name  full name = "testPeriph-XXXX"
const char* myPrivateServiceUUID = "AD11CF40063F11E5BE3E0002A5D5C51B" ; // Custom private service UUID
const char* temperatureCharacteristicUUID = "BF3FBD80063F11E59E690002A5D5C501" ;  // custom characteristic GATT
const uint8_t temperatureCharacteristicLen = 2 ;  // data length (in bytes)
const uint16_t temperatureHandle = 0x72 ;
char temperaturePayload[temperatureCharacteristicLen] ;
float temperature_s ;
uint8_t newTempValue_u8 = 0 ;
uint8_t prevTempValue_u8 = 0 ;
const char* ledCharacteristicUUID = "BF3FBD80063F11E59E690002A5D5C503" ;  // custom characteristic GATT
const uint8_t ledRGBCharacteristicLen = 6 ;
const uint8_t ledBlueCharacteristicLen = 2 ;
uint16_t ledHandle = 0x75 ;
const char* ledPayload ;
bool blueLedOn = false ;

void initLed()
{
  pinMode(LED_BUILTIN, OUTPUT) ;
  pinMode(LED_RED, OUTPUT) ;
  pinMode(LED_GREEN, OUTPUT) ;
  pinMode(LED_BLUE, OUTPUT) ;
  pinMode(BUTTON, INPUT_PULLUP) ;
}

void turnBlueLedOn()
{
  digitalWrite(LED_BUILTIN, HIGH) ;
  blueLedOn = true ;
}

void turnBlueLedOff()
{
  digitalWrite(LED_BUILTIN, LOW) ;
  blueLedOn = false ;
}

void setRgbColor(uint8_t red, uint8_t green, uint8_t blue)
{
  red = 255 - red ;
  green = 255 - green ;
  blue = 255 - blue ;

  analogWrite(LED_RED, red) ;
  analogWrite(LED_GREEN, green) ;
  analogWrite(LED_BLUE, blue) ;
}

void initTemperature()
{
  pinMode(TEMP_SENSOR, INPUT) ;
  //Set ADC resolution to 12 bits
  analogReadResolution(12) ;
}

float getTemperature()
{
  float mVolts = (float)analogRead(TEMP_SENSOR) * 3300.0 / 1023.0 ;
  float temp = (mVolts - 500.0) / 100.0 ;
  return temp ;
}

void convertIntToCharArray(int value)
{
  String str;
  str = String(value);

  str.toCharArray(temperaturePayload,4);  
}

void setup()
{
  while ((!debugSerial) && (millis() < SERIAL_TIMEOUT)) ;

  debugSerial.begin(115200) ;

  initLed() ;
  initTemperature() ;

  // Set the optional debug stream
  rn487xBle.setDiag(debugSerial) ;

  // Initialize the BLE hardware
  rn487xBle.hwInit() ;

  // Open the communication pipe with the BLE module
  bleSerial.begin(rn487xBle.getDefaultBaudRate()) ;

  // Assign the BLE serial port to the BLE library
  rn487xBle.initBleStream(&bleSerial) ;

  // Finalize the init. process
  if (rn487xBle.swInit())
  {
    setRgbColor(0, 255, 0) ;
    debugSerial.println("Init. procedure done!") ;
  }
  else
  {
    setRgbColor(255, 0, 0) ;
    debugSerial.println("Init. procedure failed!") ;
    while (1) ;
  }

  // Fist, enter into command mode
  rn487xBle.enterCommandMode() ;

  // Stop advertising before starting the demo
  rn487xBle.stopAdvertising() ;

  // Set the advertising output power (range: min = 5, max = 0)
  rn487xBle.setAdvPower(3) ;

  // Set the serialized device name, i.e. device n,ame + 2 last bytes from MAC address.
  rn487xBle.setSerializedName(myDeviceName) ;
  rn487xBle.clearAllServices() ;
  rn487xBle.reboot() ;
  rn487xBle.enterCommandMode() ;

  // Set a private service ...
  rn487xBle.setServiceUUID(myPrivateServiceUUID) ;

  // which contains ...
  // ...a temperature characteristic; readable and can perform notification, 2-octets size
  rn487xBle.setCharactUUID(temperatureCharacteristicUUID, READ_PROPERTY | NOTIFY_PROPERTY, temperatureCharacteristicLen) ;

  // ...an LED characteristic; properties: writable
  rn487xBle.setCharactUUID(ledCharacteristicUUID, WRITE_PROPERTY, ledRGBCharacteristicLen) ;

  // take into account the settings by issuing a reboot
  rn487xBle.reboot() ;
  rn487xBle.enterCommandMode() ;

  // Clear adv. packet
  rn487xBle.clearImmediateAdvertising() ;

  // Start adv.
  // The line below is required, to let an Android device discover the board.
  rn487xBle.startImmediateAdvertising(AD_TYPE_FLAGS, "06");
  rn487xBle.startImmediateAdvertising(AD_TYPE_MANUFACTURE_SPECIFIC_DATA, "CD00FE14AD11CF40063F11E5BE3E0002A5D5C51B") ;

  debugSerial.println("Starter Kit as a Peripheral with private service") ;
  debugSerial.println("================================================") ;
  debugSerial.print("Private service: ") ;
  debugSerial.println(myPrivateServiceUUID) ;
  debugSerial.print("Private characteristic used for the Temperature: ") ;
  debugSerial.println(temperatureCharacteristicUUID) ;
  debugSerial.print("Private characteristic used for the LED: ") ;
  debugSerial.println(ledCharacteristicUUID) ;
  debugSerial.println("You can now establish a connection from the Microchip SmartDiscovery App") ;
  debugSerial.print("with the starter kit: ") ;
  debugSerial.println(rn487xBle.getDeviceName()) ;

}

void loop()
{
  // Check the connection status
  if (rn487xBle.getConnectionStatus())
  {
    // Connected to a peer
    debugSerial.print("Connected to a peer central ") ;
    debugSerial.println(rn487xBle.getLastResponse()) ;

    // Temperature
    prevTempValue_u8 = newTempValue_u8 ;
    temperature_s = getTemperature() ;
    newTempValue_u8 = (int)temperature_s ;

    convertIntToCharArray(newTempValue_u8) ;
    
    debugSerial.print("Temperature payload : ") ;
    debugSerial.print(temperaturePayload[0]);
    debugSerial.println(temperaturePayload[1]);

    // Update the local characteristic only if value has changed
    if (newTempValue_u8 != prevTempValue_u8)
    {
      if (rn487xBle.writeLocalCharacteristic(temperatureHandle, temperaturePayload))
      {
        debugSerial.print("Temperature characteristic has been updated with the value = ") ; debugSerial.println(newTempValue_u8) ;
      }
    }

    // LED
    if (rn487xBle.readLocalCharacteristic(ledHandle))
    {
      // Read the local characteristic written by the client: smartphone/tablet
      // The payload must follow the 6-bit RGB coded format:
      // [0] Red MSB
      // [1] Red LSB
      // [2] Green MSB
      // [3] Green LSB
      // [4] Blue MSB
      // [5] Blue LSB
      // Each color can be coded from range 0x00 to 0xFF
      ledPayload = rn487xBle.getLastResponse() ;
      if (ledPayload != NULL)
      {
        if (ledPayload[0] != 'N') // != "N/A" response
        {
          debugSerial.print("Led payload = ");
          debugSerial.println(ledPayload);
          if (strlen(ledPayload) == ledBlueCharacteristicLen)
          {
            if (ledPayload[0] == 'F' && ledPayload[1] == 'F') turnBlueLedOn() ;
            else turnBlueLedOff() ;
          }
        }
      }
    }
  }
  else
  {
    // Not connected to a peer device
    debugSerial.println("Not connected to a peer device") ;
  }
  // Delay inter connection polling
  delay(3000) ;
}
