/******************************************************/
//       THIS IS A GENERATED FILE - DO NOT EDIT       //
/******************************************************/

#include "Particle.h"
#line 1 "/Users/matthewpanizza/Library/CloudStorage/OneDrive-Personal/Particle/SkateInfoView/src/SkateInfoView.ino"
/*************************************/
/*          SkateInfoView            */
/*    Created by Matthew Panizza     */
/*          October 2020             */
/*************************************/

void setup();
static void onDataReceived(const uint8_t* data, size_t len, const BlePeerDevice& peer, void* context);
void loop();
void calculateRPM();
void hallPulse();
void publishTest(int dataValue);
void writeOdo();
#line 7 "/Users/matthewpanizza/Library/CloudStorage/OneDrive-Personal/Particle/SkateInfoView/src/SkateInfoView.ino"
SYSTEM_MODE(SEMI_AUTOMATIC);                                          //Start with Bluetooth LE only

SerialLogHandler logHandler(LOG_LEVEL_TRACE);                         //Log Configuration

#define APPRX_BATT_RESISTANCE   0.20                                  //Battery Resistance approximation
#define MAH_TP_INT              100                                   //Battery testing interval
#define HL_THRESH               50
#define NUM_WHEEL_MAG           6                                     //Number of wheel RPM magnets
#define ODO_EEPROM              40                                    //Odometer eeprom location
#define ODO_MIN_TIME            25000                                 //Minimum time between writes for odometer EEPROM

#define VCAL 0

const char* serviceUuid     = "b4250400-fb4b-4746-b2b0-93f0e61122c6"; //service
const char* rpmlvl          = "b4250401-fb4b-4746-b2b0-93f0e61122c6"; //temperature char
const char* cloudmode       = "b4250402-fb4b-4746-b2b0-93f0e61122c6"; //cloud char
const char* bttlvl          = "b4250403-fb4b-4746-b2b0-93f0e61122c6"; //battery voltage char
const char* currlvl         = "b4250404-fb4b-4746-b2b0-93f0e61122c6"; //current char
const char* estpercent      = "b4250405-fb4b-4746-b2b0-93f0e61122c6"; //percentage estimate char
const char* encons          = "b4250406-fb4b-4746-b2b0-93f0e61122c6"; //energy consumption char
const char* templvl         = "b4250407-fb4b-4746-b2b0-93f0e61122c6"; //temperature char
const char* triplvl         = "b4250408-fb4b-4746-b2b0-93f0e61122c6"; //temperature char
const char* odolvl          = "b4250409-fb4b-4746-b2b0-93f0e61122c6"; //temperature char

//Global Variables
int i;                              //Iterator
bool tone_high = false;             //Piezo beep variable
int numBatts;
int brtSensor;                      //Photoresistor sensor
float battVoltage;                  //Battery voltage float -> do this value / 93.89 for actual voltage
float battVoltageCorr;              //Battery voltage with internal resistance correction
float battCurrent;                  //Battery net current in A
float battCurrentmA;                //Battery net current in mA
float battTemp;                     //Battery temperature in F
unsigned long lastLoopTime;         //Loop timer for current integration
unsigned long nextPollTime;
unsigned long hallPollTime;
float mAH_consumption;              //Result of current integration
float mAH_TP;                       //Next value to take reading of battery voltage
int battPercent;                    //Percentage estimate of the battery state-of-charge
bool batteryTest = false;           //Enables/disables battery discharge logging
int HLMode;
uint16_t pulse_1S;                   //Count hall pulses over last second
uint16_t pulse_2S;                   //Count hall pulses over last two seconds
uint8_t RPS;                        //Revolution per second calculation
uint32_t revCount;                  //Counts total revolutions for odometer
uint32_t hMile;                     //Counts hundredths of a mile
uint32_t odoMile;                   //Counts tenths of a mile for odometer
uint32_t odoSave;                   //Counter for when odo was saved to EEPROM last
uint32_t odoSaveTime;
size_t name1;

// Bluetooth LE Characteristics and Services
BleUuid SkateInfoService(serviceUuid);
BleCharacteristic bttlvlCharacteristic  ("bttlvl",     BleCharacteristicProperty::NOTIFY, bttlvl, SkateInfoService);   
BleCharacteristic currlvlCharacteristic ("currlvl",    BleCharacteristicProperty::NOTIFY, currlvl, SkateInfoService);
BleCharacteristic estpctCharacteristic  ("estpercent", BleCharacteristicProperty::NOTIFY, estpercent, SkateInfoService);
BleCharacteristic enconsCharacteristic  ("encons",     BleCharacteristicProperty::NOTIFY, encons, SkateInfoService);  
BleCharacteristic templvlCharacteristic ("templvl",    BleCharacteristicProperty::NOTIFY, templvl, SkateInfoService);
BleCharacteristic rpmlvlCharacteristic  ("rpmlvl",     BleCharacteristicProperty::NOTIFY, rpmlvl, SkateInfoService);
BleCharacteristic trplvlCharacteristic  ("triplvl",     BleCharacteristicProperty::NOTIFY, triplvl, SkateInfoService);    
BleCharacteristic odolvlCharacteristic  ("odolvl",     BleCharacteristicProperty::NOTIFY, odolvl, SkateInfoService);    
BleCharacteristic modeCharacteristic    ("cloudmode",  BleCharacteristicProperty::WRITE_WO_RSP, cloudmode, serviceUuid, onDataReceived, (void*)cloudmode);

Timer timer(1000, calculateRPM);

void setup() {

    mAH_consumption = 0;                            //Initialize mAH consumption counter
    mAH_TP = 0;                                     //Initialize mAH test-point counter
    lastLoopTime = 0;                               //Initialize integration timer
    
    pulse_1S = 0;                                   //Reset hall pulse sensors
    pulse_2S = 0;
    RPS = 0;
    revCount = 0;

    BLE.selectAntenna(BleAntennaType::INTERNAL);    //Set to internal ceramic antenna
    BLE.setScanTimeout(100);                        //Timeout of 1 second

    EEPROM.put(1, 2);                               //Manually Set Battery Count
    EEPROM.get(1, numBatts);
    EEPROM.put(2, 0);                               //Manually Set Headlight Mode
    EEPROM.get(2, HLMode);                          //Retrieve last-set headlight mode

    uint8_t od0,od1,od2,od3;
    odoSaveTime = 0;

    EEPROM.get(ODO_EEPROM, od3);
    EEPROM.get(ODO_EEPROM+1, od2);
    EEPROM.get(ODO_EEPROM+2, od1);
    EEPROM.get(ODO_EEPROM+3, od0);
    odoMile = (od3 << 24) + (od2 << 16) + (od1 << 8) + od0;

    RGB.control(true);                              //Enable control of built-in RGB LED
    RGB.color(100, 0, 0);                           //Set to Red initially
                          
    pinMode(D4, INPUT_PULLUP);
    pinMode(D6, OUTPUT);                            //Configure pin for thermistor power
    pinMode(D7, OUTPUT);                            //Configure pin for blue indicator LED
    delay(100);

    digitalWrite(D6,HIGH);                          //Turn on thermistor sensor power

    attachInterrupt(D4, hallPulse, FALLING);         //Configure interrupt for hall RPM sensor

    // Add the characteristics
    BLE.addCharacteristic(modeCharacteristic);
    BLE.addCharacteristic(bttlvlCharacteristic);   
    BLE.addCharacteristic(currlvlCharacteristic);
    BLE.addCharacteristic(estpctCharacteristic);
    BLE.addCharacteristic(enconsCharacteristic);
    BLE.addCharacteristic(templvlCharacteristic);
    BLE.addCharacteristic(rpmlvlCharacteristic);
    BLE.addCharacteristic(trplvlCharacteristic);
    BLE.addCharacteristic(odolvlCharacteristic);

    BleAdvertisingData advData;                     //Advertising data
    
    advData.appendServiceUUID(SkateInfoService);    // Add the app service
    advData.appendLocalName("SK01");                //Local advertising name
    BLE.advertise(&advData);                        //Start advertising the characteristics

    while(!BLE.connected() && analogRead(A0) < 200){//Loop to blink the RGB LED until a device has connected
        for(i = 0; i <= 100; i+=5){
            RGB.color(i, 0, 0);
            delay(20);
        }
        delay(75);
        for(i = 100; i>= 0; i-=5){
            RGB.color(i, 0, 0);
            delay(20);
        }
        delay(75);
    }

    //Initial battery percentage calculation
    battPercent = (((analogRead(A1)+45)*1000/93.89)-34000)/70;
    
    //Fade into new LED percentage approximation
    for(i = 0; i< 100; i+=5){
        RGB.color(i*(100-battPercent)/100, i*battPercent/100, 0);
        delay(20);
    }
    nextPollTime = millis();
    //hallPollTime = millis();

    timer.start();
}

//Handler for commands sent by app over BLE
static void onDataReceived(const uint8_t* data, size_t len, const BlePeerDevice& peer, void* context) {

  // We're only looking for one byte
  if( len != 1 ) {
    return;
  }

  //get characteristics from "cloud" characteristic
    if ( context == cloudmode ) {
        switch (data[0])
        {
        case 1:
            RGB.control(false);         //Pass LED control back to system to see status of connection 
            //Cellular.on();              //Turn on cellular
            Particle.connect();         //Connect to device cloud
            break;
        case 2:
            RGB.control(false);
            System.dfu();               //Put system in DFU mode
            break;
        case 3:
            RGB.control(false);
            Particle.connect();         //Connect to device cloud over mesh
            break;
        case 4:
            batteryTest = true;         //Enable battery testing 
            digitalWrite(D7, HIGH);     //Turn on blue LED to indicate that test-mode is active
            break;
        case 50:
        case 51:
        case 52:
            HLMode = data[0]-50;        //Update Headlight Mode with user selected value
            EEPROM.put(2,HLMode);       //Save to eeprom to retain the mode across power cycles
            break;
        default:
            break;
        }

    }
    lastLoopTime = millis();
}

void loop() {
    ///////////////////////////////
    ////Check for Remote Signal////
    ///////////////////////////////    
    if(millis() > nextPollTime){                                            //Function that executes aprroximately every 250ms
        battTemp = 100.0*((analogRead(A4))/28.0);                           //Reports temperature in F
        battCurrent = analogRead(A0)-analogRead(A2)+4096;                   //Reports current * 100 * 1.25
        battCurrentmA = (analogRead(A0)-analogRead(A2))*1000/125;           //Gets net current in mA
        battVoltage = analogRead(A1)+VCAL;                                    //Gets raw ADC reading from voltage divider
        battVoltageCorr = ((analogRead(A1)+VCAL)*1000/79.125) + APPRX_BATT_RESISTANCE*1000*(analogRead(A0)/125.0); //mV
        battPercent = (battVoltageCorr-34000)/62;                           //Linear comparison of voltage to 34000mV

        hMile = (revCount/57);

        //Current integration for energy calculation
        mAH_consumption += (battCurrentmA)*((float)(millis()-lastLoopTime)/(float)3600000);
        lastLoopTime = millis();                                            //Reset integration counter

        //Percentage range-tweaking - ensures the percentage is between 0 and 100
        int x = (int)battPercent;
        if(x >= 0 && x <= 100){
            RGB.color(i*(100-battPercent)/100, i*battPercent/100, 0);
        }
        else if(x > 100){
            battPercent = 100;
            RGB.color(i*(100-battPercent)/100, i*battPercent/100, 0);
        }
        else{
            battPercent = 0;
            RGB.color(i*(100-battPercent)/100, i*battPercent/100, 0);
        }

        

        //Transmit each of the characteristics over BLE
        bttlvlCharacteristic.setValue((int)battVoltage);
        currlvlCharacteristic.setValue((int)battCurrent);
        estpctCharacteristic.setValue((uint8_t)battPercent);
        enconsCharacteristic.setValue((int)mAH_consumption);
        templvlCharacteristic.setValue((int)battTemp);
        rpmlvlCharacteristic.setValue((int)RPS);
        trplvlCharacteristic.setValue((int)hMile);
        odolvlCharacteristic.setValue((int)odoMile);

        //Log.trace("RPM: %d",RPS*60);
        //Log.trace("Speed: %0.1f",(RPS*0.6322));

        nextPollTime += 300;
    }

    //Log.trace("\nBattery Current: %f mA", battCurrentmA);
    //Log.trace("\nBattery Temperature: %f F", battTemp);
    //Log.trace("Battery Voltage: %f", battVoltage);
    //Log.trace("Energy Consumption: %f mAH", mAH_consumption);

    //Battery test function - logs battery voltage for each interval of MAH_TP_INT
    if(batteryTest){
        if(mAH_consumption > mAH_TP + MAH_TP_INT){      //Check if the next interval has been reached
            publishTest((int)battVoltageCorr);          //Publish the current-corrected battery voltage to the cloud
            mAH_TP = mAH_consumption;                   //Set test-point to current mAH value
        }
    }

    if(odoMile != odoSave && millis()-odoSaveTime > 25000) writeOdo();
    
    //if(!digitalRead(D4)) digitalWrite(D7,HIGH);
    //else digitalWrite(D7, LOW);
    delay(5);//250ms per loop
}

void calculateRPM(){
    RPS = ((pulse_1S + (pulse_2S >> 1))/(NUM_WHEEL_MAG << 1));       //Take average of past 1 second and past 2 seconds
    pulse_2S = pulse_1S;                             //Reset counters
    pulse_1S = 0;
    revCount += RPS;
    //hallPollTime += 1000;
    /*Log.trace("RPM: %d",RPS*60);
    Log.trace("Speed: %0.1f",(RPS*0.6322));*/
    
}

void hallPulse(){
    pulse_1S++;
    pulse_2S++;
}

void publishTest(int dataValue) {
    Particle.publish("sheetTest1",String::format("%d", dataValue),PRIVATE);
}  

void writeOdo(){
    odoSave = odoMile;
    odoSaveTime = millis();
    uint8_t od0, od1, od2, od3;
    od3 = odoMile >> 24;
    od2 = (odoMile >> 16) & 255;
    od1 = (odoMile >> 8) & 255;
    od0 = odoMile & 255;
    EEPROM.write(ODO_EEPROM, od3);
    EEPROM.write(ODO_EEPROM + 1, od2);
    EEPROM.write(ODO_EEPROM + 2, od1);
    EEPROM.write(ODO_EEPROM + 3, od0);
}




