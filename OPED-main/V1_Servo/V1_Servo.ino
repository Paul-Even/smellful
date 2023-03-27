/*
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleServer.cpp
    Ported to Arduino ESP32 by Evandro Copercini
    updates by chegewara
*/

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include "BluetoothSerial.h"
#include <ESP32Servo.h>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

BluetoothSerial SerialBT;

Servo myservo1; //Initialize the three servo motors
Servo myservo2;
Servo myservo3;

Servo servoUti; //Initialize the variating used servo motors, to simplify the program

int s1 = 17; //Initialize the servo's pins
int s2 = 16;
int s3 = 15;

bool posidone = false; //Boolean to know if the positions of the servo's are the one needed.

char strength = 'x'; //Will recover the value of the smell's strength. Can be '0', '1' or '2'
char smell = 'y'; //Will recover the value of the wanted smell. Can be '0', '1' or '2'

int pos = 70; //The value of the servo's position. 70 is the position where no smell will be released.

String period1; //The values will help counting the diffusions' time
int period2;
unsigned long period;
unsigned long timeElapsed1;
unsigned long timeElapsed2;
unsigned long timeElapsed3;

bool modeC = false; //Tells if the calendar mode is ongoing
bool modeM = false; //Tells if the manual mode is ongoing
bool finC = false; //Tells if the calendar mode is finishing
int eventlance = -1; //Tells which event of the calendar is ongoing
bool Cencours = false; //Tells if there's an event on going

int infos[10][4]; //Two dimmensionnal array that will retrieve the data needed for each event of the calendar mode (Time until start, duration, smell, strength)


#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b" //Initialize the parameters of the BLE Server
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;

bool deviceConnected; //Checks the connecting status of the server
bool oldDeviceConnected;

int nblignes = 0; //Used for filling infos

class MyServerCallbacks: public BLEServerCallbacks { 
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
  
   
  
  void onWrite(BLECharacteristic *pCharacteristic){ //Actions done when the server receives a value
    std::string rxValue = pCharacteristic->getValue();
    period1 = "";
    if(rxValue[0] == '1'){modeC = true;} //Checks if the mode used is calendar or manual
    if(rxValue[0] == '2'){modeM = true;}

    if(rxValue == "xxx"){ // "xxx" is sent if the stop button is used.
      modeC = false; //Stops calendar and manual mode
      modeM = false;
      Cencours = false;
      int eventlance = -1;
      
      myservo1.attach(17,800,2200); //Puts the servo on sleep position
      myservo2.attach(16,800,2200);
      myservo3.attach(15,800,2200);
      myservo1.write(70);
      myservo2.write(70);
      myservo3.write(70);
      delay(2000);
      myservo1.detach();
      myservo2.detach();
      myservo3.detach();
      
      posidone = false; 

      for(int i = 0; i < 10; i++){ //Deletes the calendar's infos
      for(int j = 0; j < 4; j++){
       
        infos[i][j] = 0;
      }
      
    }
      period2 = 0;
      
    }

    if(rxValue[0] == '1') //If calendar mode is used
    {
      Serial.println("====STARTING TO RECEIVE====");
      Serial.print("Received value :");
      for(int i = 0; i < rxValue.length()-1; i++){ //Prints the received value
        
        Serial.print(rxValue[i]);
      }
      Serial.println();
      
           
      
      
      int x = 0;
      int y = 0;
      String s = "";
      for(int i = 1; i < rxValue.length(); i++){ //Fills the infos array
        if(rxValue[i] != '.' && rxValue[i] != ';'){
          s += rxValue[i];
        }
        if(rxValue[i] == '.'){
          infos[x][y] = s.toInt();
          s = "";
          y++;
        }
        if(rxValue[i] == ';'){
          infos[x][y] = s.toInt();
          y = 0;
          x++;
          nblignes ++;
          s = "";
        }
        
      }
      //infos = infos2;
      for(int i = 0; i < 10; i++){
      for(int j = 0; j < 4; j++){
       
        Serial.print((String)infos[i][j] + " ! ");
      }
      Serial.println();
      
    }
  
    }
    
    

    /////////////////////////////////////////////////////////////////////// 

    if(rxValue[0] == '2'){ //If manual mode is used
      posidone = false; //Tells that the servos have to change position
      //myservo1.attach(17,800,2200);
      //myservo2.attach(16,800,2200);
      //myservo3.attach(15,800,2200);

            if(rxValue.length() > 0){
      Serial.println("====STARTING TO RECEIVE====");
      Serial.print("Received value :");
      strength = rxValue[rxValue.length() - 2]; //Get the strength and smell value
      smell = rxValue[rxValue.length() - 1];
      for(int i = 1; i < rxValue.length()-2; i++){ //Get the duration value
        
        Serial.print(rxValue[i]);
        //period2 = period2*10;
        period1 += rxValue[i];
        
      }
      Serial.println("====FINISHING TO RECEIVE====");
      period2 = period1.toInt();
    }
  }
    }
      
};





void setup() {
  Serial.begin(115200);
  Serial.println("Starting BLE work!");

  BLEDevice::init("smellful"); //Starts the BLE Server with the functions defined earlier
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE |
                                         BLECharacteristic::PROPERTY_NOTIFY
                                       );
  pServer->setCallbacks(new MyServerCallbacks());
  pCharacteristic->setCallbacks(new MyCallbacks());
  pService->start();
  // BLEAdvertising *pAdvertising = pServer->getAdvertising();  // this still is working for backward compatibility
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Characteristic defined! Now you can read it in your phone!");

  

  
}

void loop() {

    // Actions when the phone disconnects from the server
    
    // disconnecting
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        Serial.println("start advertising");
        oldDeviceConnected = deviceConnected;

    }
    // connecting
    if (deviceConnected && !oldDeviceConnected) {
        // do stuff here on connecting
        oldDeviceConnected = deviceConnected;
        if(modeC == false && modeM == false){
          digitalWrite(2,HIGH);
        }
        
        
        
    }

timeElapsed1 = millis();
timeElapsed2 = 0;
if(Cencours == false && modeM == false) // Actions if nothing is ongoing
{
  delay(200);
  posidone = false;
}

finC = true;
  
  if(modeC == true && modeM == false){ // Actions if only the calendar mode is ongoing
    Serial.println("loop 1");
    if(infos[eventlance + 1][0] < 0 && Cencours == false && infos[eventlance + 1][0] != NULL){ //Checks if a new event is ready to start
      eventlance ++;
      Cencours = true;
    }
    

    if(Cencours == true){ // Check if an event is ongoing
      digitalWrite(2,HIGH);
      switch (infos[eventlance][2]) // Gives the needed position of the servo depending on the strength value.
  {
    Serial.println(infos[eventlance][2]);
    case 0:
      pos = 100; // Position for low smell
      break;
    case 1:  
      pos = 130; // Position for medium smell
      break;
    case 2:  
      pos = 165; // Position for high smell
      Serial.println("pos 165");
      break;        
  }

      if(posidone == false) // Checks if the servos need to move. With this condition, we don't always have to power the servos.
  {
    switch (infos[eventlance][3]) // Depending of the chosen smell, one servo will go down, and the two others will go up.
  {
    Serial.println(infos[eventlance][3]);
    case 0: 
      servoUti.attach(s1, 800, 2200);
      myservo2.attach(s2, 800, 2200);
      myservo2.write(70);
      myservo3.attach(s3, 800, 2200);
      myservo3.write(70);
      delay(2000);
      myservo2.detach();
      myservo3.detach();
      
      break;
    case 1:  
      servoUti.attach(s2, 800, 2200);
      myservo1.attach(s1, 800, 2200);
      myservo1.write(70);
      myservo3.attach(s3, 800, 2200);
      myservo3.write(70);
      delay(2000);
      myservo1.detach();
      myservo3.detach();
      break;
    case 2:  
      servoUti.attach(s3, 800, 2200);
      myservo1.attach(s1, 800, 2200);
      myservo1.write(70);
      
      myservo2.attach(s2, 800, 2200);
      myservo2.write(70);
      delay(2000);
      myservo1.detach();
      myservo2.detach();
      Serial.println("servo1 actif");
      break;              
  }
  servoUti.write(pos); // Puts the used servo in the good position
  Serial.println("servo en position");
  delay(2000);
  servoUti.detach(); 
  posidone = true; // Says that the servos don't need to move for now.
  }
  
  myservo1.detach(); // Makes sure that the servos are not powered.
  myservo2.detach();
  myservo3.detach();
  delay(2000);

      if(infos[eventlance][1] > 0) // Actions if the event is still ongoing
      {
        timeElapsed2 = millis() - timeElapsed1;
        infos[eventlance][1] = infos[eventlance][1] - timeElapsed2;
        finC = false;
        Serial.println("T restant : " + (String)infos[eventlance][1]);
      }  
      if(infos[eventlance][1] <= 0) // Actions if the event is finished
      {
        Cencours = false;
        myservo1.attach(17,800,2200); // Puts all the servos in sleep position
        myservo2.attach(16,800,2200);
        myservo3.attach(15,800,2200);
        myservo1.write(70);
        myservo2.write(70);
        myservo3.write(70);
        delay(2000);
        myservo1.detach();
        myservo2.detach();
        myservo3.detach();
        posidone = false;
      }
  
    }
    
    
      for(int i = 0; i < 10; i++) // Reduces wainting time of every events
    {
      if(infos[i][0] > 0)
      {
        timeElapsed2 = millis() - timeElapsed1;
        timeElapsed3 = timeElapsed2 - timeElapsed1;
        infos[i][0] = infos[i][0] - timeElapsed2;
        finC = false;
      }
     
      
    }
    if(finC == true){ // Actions if all calendar's events are finished
      modeC = false;   
         
    }
    
  }
  if(modeC == false && modeM == true) // Actions if only the manual mode is used
  {
    Serial.println("loop 2");
  switch (strength) // Gives the needed position of the servo depending on the strength value.
  {
    case '0':
      pos = 100;
      break;
    case '1':  
      pos = 130;
      break;
    case '2':  
      pos = 165;
      break;       
  }
  if(posidone == false) // Checks if the servos need to move. With this condition, we don't always have to power the servos.
  {
    switch (smell) // Depending of the chosen smell, one servo will go down, and the two others will go up.
  {
    case '0':
      servoUti.attach(s1, 800, 2200);
      myservo2.attach(s2, 800, 2200);
      myservo2.write(70);
      myservo3.attach(s3, 800, 2200);
      myservo3.write(70);
      delay(2000);
      myservo2.detach();
      myservo3.detach();
      break;
    case '1':  
      servoUti.attach(s2, 800, 2200);
      myservo1.attach(s1, 800, 2200);
      myservo1.write(70);
      myservo3.attach(s3, 800, 2200);
      myservo3.write(70);
      delay(2000);
      myservo1.detach();
      myservo3.detach();
      break;
    case '2':  
      servoUti.attach(s3, 800, 2200);
      myservo1.attach(s1, 800, 2200);
      myservo1.write(70);
      
      myservo2.attach(s2, 800, 2200);
      myservo2.write(70);
      delay(2000);
      myservo1.detach();
      myservo2.detach();
      Serial.println("servo1 actif");
      break;              
  }
  servoUti.write(pos); // Puts the used servo in the good position
  delay(2000);
  servoUti.detach();
  posidone = true; // Says that the servos don't need to move for now.
  }
  
  myservo1.detach(); // Makes sure that the servos are not powered.
  myservo2.detach();
  myservo3.detach();
  delay(2000);
  if(period2 > 0){ // Serial printing the value of the remaining time
    Serial.println("Period2 : " + (String)period2);
  }
  timeElapsed2 = millis(); // Reducting the diffusion's remaining time
  timeElapsed3 = timeElapsed2 - timeElapsed1;
  period2 = period2 - timeElapsed3;

  if(period2 < 0) // Actions if the diffusion is finished
  {
    period1 = "";
    period2 = 0;
    modeM = false;

    myservo1.attach(17,800,2200); // Puts all the servos in sleep position
        myservo2.attach(16,800,2200);
        myservo3.attach(15,800,2200);
        myservo1.write(70);
        myservo2.write(70);
        myservo3.write(70);
        delay(2000);
        myservo1.detach();
        myservo2.detach();
        myservo3.detach();
        posidone = false;
  }
  }
  if(modeC == true && modeM == true) // Actions if both mode are used at the same time
  {
    Serial.println("loop 3");
  switch (strength) // Gives the needed position of the servo depending on the strength value.
  {
    case '0':
      pos = 100;
      break;
    case '1':  
      pos = 130;
      break;
    case '2':  
      pos = 165;
      break;       
  }
  if(posidone == false) // Checks if the servos need to move. With this condition, we don't always have to power the servos.
  {
    switch (smell) // Depending of the chosen smell, one servo will go down, and the two others will go up.
  {
    case '0':
      servoUti.attach(s1, 800, 2200);
      myservo2.attach(s2, 800, 2200);
      myservo2.write(70);
      myservo3.attach(s3, 800, 2200);
      myservo3.write(70);
      delay(2000);
      myservo2.detach();
      myservo3.detach();
      break;
    case '1':  
      servoUti.attach(s2, 800, 2200);
      myservo1.attach(s1, 800, 2200);
      myservo1.write(70);
      myservo3.attach(s3, 800, 2200);
      myservo3.write(70);
      delay(2000);
      myservo1.detach();
      myservo3.detach();
      break;
    case '2':  
      servoUti.attach(s3, 800, 2200);
      myservo1.attach(s1, 800, 2200);
      myservo1.write(70);
      
      myservo2.attach(s2, 800, 2200);
      myservo2.write(70);
      delay(2000);
      myservo1.detach();
      myservo2.detach();
      break;              
  }
  servoUti.write(pos); // Puts the used servo in the good position
  delay(2000);
  servoUti.detach();
  posidone = true; // Says that the servos don't need to move for now.
  }
  
  myservo1.detach(); // Makes sure that the servos are not powered.
  myservo2.detach();
  myservo3.detach();
  delay(2000);
  timeElapsed2 = millis(); // Reducting the manual diffusion's remaining time
  timeElapsed3 = timeElapsed2 - timeElapsed1;
  period2 = period2 - timeElapsed3;

  
    for(int i = 0; i < 10; i++) // Reducting the calendar diffusion's wainting and remaining times
    {
      if(infos[i][0] > 0 ||  infos[i][1] > 0){
        finC = false; 
      }
      if(infos[i][0] > 0)
      {
        timeElapsed2 = millis() - timeElapsed1;
        timeElapsed3 = timeElapsed2 - timeElapsed1;
        infos[i][0] = infos[i][0] - timeElapsed2;
        
      }
      else if(infos[i][1] > 0){
          timeElapsed2 = millis() - timeElapsed1;
        timeElapsed3 = timeElapsed2 - timeElapsed1;
        infos[i][1] = infos[i][1] - timeElapsed2;        
      }
     
      
    }
    if(finC == true){
      modeC = false;
    }
    
  if(period2 < 0)
  {
    period1 = "";
    period2 = 0;
    modeM = false;
    myservo1.attach(17,800,2200);
        myservo2.attach(16,800,2200);
        myservo3.attach(15,800,2200);
        myservo1.write(70);
        myservo2.write(70);
        myservo3.write(70);
        delay(2000);
        myservo1.detach();
        myservo2.detach();
        myservo3.detach();
        posidone = false;
  }
  if(modeM == false && modeC == false) //Actions if both modes are finished
  {
    myservo1.attach(17,800,2200);
        myservo2.attach(16,800,2200);
        myservo3.attach(15,800,2200);
        myservo1.write(70);
        myservo2.write(70);
        myservo3.write(70);
        delay(2000);
        myservo1.detach();
        myservo2.detach();
        myservo3.detach();
        posidone = false;
  }
  
  
  }
  
}
