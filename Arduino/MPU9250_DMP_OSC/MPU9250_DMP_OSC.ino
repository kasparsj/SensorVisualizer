#include <WiFi.h>       // use for ESP32
#include <SparkFunMPU9250-DMP.h>
#include <Adafruit_BMP280.h>
#include <ArduinoOSC.h>

#define fifoRate 60 // (4 - 200)
#define updateRate 60
#define sendEuler false

const char* ssid = "k";
const char* password = "letmeinplease";

//static char* remoteIp = "192.168.1.129";
static char* remoteIp = "192.168.1.141";
static uint16_t remotePort = 9000;

const int id = 2;

MPU9250_DMP imu;
Adafruit_BMP280 bmp;

float quatX, quatY, quatZ, quatW = 0;
float accX, accY, accZ = 0;
float gyroX, gyroY, gyroZ = 0;
float magX, magY, magZ = 0;
float temp, press, alt = 0;

unsigned long lastUpdate = 0;

void setup() {
  Serial.begin(115200);

  Wire.begin(19, 22, 400000); // lolin32 lite

  setupWifi();
  setupIMU();
  setupBmp();

  Serial.println("setup finished");
}

void setupWifi()
{
    WiFi.disconnect(true);
    
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println(" connected");
}

void setupIMU()
{
  // Call imu.begin() to verify communication and initialize
  if (imu.begin() != INV_SUCCESS)
  {
    while (1)
    {
      Serial.println("Unable to communicate with MPU-9250");
      Serial.println("Check connections, and try again.");
      Serial.println();
      delay(5000);
    }
  }
  imu.setSampleRate(fifoRate);
  imu.dmpBegin(DMP_FEATURE_6X_LP_QUAT |
               DMP_FEATURE_GYRO_CAL |
               DMP_FEATURE_SEND_CAL_GYRO,
              fifoRate); 
}

void setupBmp()
{
  if (!bmp.begin(0x76)) {
    Serial.println(F("Could not find a valid BMP280 sensor, check wiring!"));
    while(1);
  }

  bmp.setSampling(Adafruit_BMP280::MODE_NORMAL,
                  Adafruit_BMP280::SAMPLING_NONE,
                  Adafruit_BMP280::SAMPLING_X1,
                  Adafruit_BMP280::FILTER_OFF,
                  Adafruit_BMP280::STANDBY_MS_1); 
}

void loop()
{
  unsigned long ms = millis();
  
  if ( imu.fifoAvailable() )
  {
    if (imu.dmpUpdateFifo() == INV_SUCCESS) {
      // processing does not work with these
      quatX = imu.calcQuat(imu.qx);
      quatY = imu.calcQuat(imu.qy);
      quatZ = imu.calcQuat(imu.qz);
      quatW = imu.calcQuat(imu.qw);
      OscWiFi.send(remoteIp, remotePort, "/quat", id, quatX, quatY, quatZ, quatW);
      if (sendEuler) {
        imu.computeEulerAngles();
        OscWiFi.send(remoteIp, remotePort, "/euler", id, imu.roll, imu.pitch, imu.yaw);        
      }
    }
  }
  else if ( (ms - lastUpdate) >= (1000 / updateRate) && imu.dataReady() )
  {
    if (imu.update() == INV_SUCCESS) {
      accX = imu.calcAccel(imu.ax);
      accY = imu.calcAccel(imu.ay);
      accZ = imu.calcAccel(imu.az);
      gyroX = imu.calcGyro(imu.gx);
      gyroY = imu.calcGyro(imu.gy);
      gyroZ = imu.calcGyro(imu.gz);
      magX = imu.calcMag(imu.mx);
      magY = imu.calcMag(imu.my);
      magZ = imu.calcMag(imu.mz);
      OscWiFi.send(remoteIp, remotePort, "/acc", id, accX, accY, accZ);
      OscWiFi.send(remoteIp, remotePort, "/gyro", id, gyroX, gyroY, gyroZ);
      OscWiFi.send(remoteIp, remotePort, "/mag", id, magX, magY, magZ);
    }

    alt = bmp.readAltitude();
    //temp = imu.temperature;
    OscWiFi.send(remoteIp, remotePort, "/altitude", id, alt);
    //OscWiFi.publish(remoteIp, remotePort, "/temperature", id, temp);
    lastUpdate = ms;
  }
}
