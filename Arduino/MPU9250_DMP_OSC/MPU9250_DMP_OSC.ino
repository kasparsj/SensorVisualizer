extern "C" void c_log(const char* format, ...) {
    char buf[128];
    va_list args;
    va_start(args, format);
    vsnprintf(buf, sizeof(buf), format, args);
    va_end(args);
    Serial.println(buf);  // or Serial.printf if you want to skip buffering
}

#include <WiFi.h>       // use for ESP32
#include <SparkFunMPU9250-DMP.h>
#include <Adafruit_BMP280.h>
#include <ArduinoOSCWiFi.h>

#define FIFO_RATE 60 // (4 - 200)
#define UPDATE_RATE 60
#define SEND_EULER false
#define BATTERY_PIN 34
#define ADC_MAX 4095.0
#define VOLTAGE_DIVIDER_RATIO 2.0  // Adjust according to your board

// const char* ssid = "OPTIC34C6-5G";
// const char* password = "095034C6";
const char* ssid = "toplap";
const char* password = "karlsruhe";

static char* remoteIp = "192.168.1.104";
static uint16_t remotePort = 57121;

// String deviceId = "lh";
String deviceId = "rh";
String oscPrefix = "/" + deviceId;

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
  analogReadResolution(12); // 12-bit ADC

  Wire.begin(19, 22, 400000); // lolin32 lite

  setupWifi();
  setupIMU();
  setupBmp();

  Serial.println("setup finished");
}

void setupWifi()
{
    Serial.print("CONNECTING WIFI ");
    Serial.print(ssid);
    
    WiFi.mode(WIFI_STA);
    WiFi.disconnect(true);
    
    WiFi.begin(ssid, password);
    
    // Add timeout to prevent infinite loop
    unsigned long startTime = millis();
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
        
        // Timeout after 20 seconds
        if (millis() - startTime > 20000) {
            Serial.println("\nWiFi connection TIMEOUT!");
            Serial.println("Check WiFi credentials or access point");
            // Return anyway and let the program continue
            return;
        }
    }
    
    Serial.println(" connected");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
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
  imu.setSampleRate(FIFO_RATE);
  imu.dmpBegin(DMP_FEATURE_6X_LP_QUAT |
               DMP_FEATURE_GYRO_CAL |
               DMP_FEATURE_SEND_CAL_GYRO,
              FIFO_RATE); 
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
      OscWiFi.send(remoteIp, remotePort, oscPrefix + "/quat", quatX, quatY, quatZ, quatW);
      if (SEND_EULER) {
        imu.computeEulerAngles();
        OscWiFi.send(remoteIp, remotePort, oscPrefix + "/euler", imu.roll, imu.pitch, imu.yaw);
      }
    }
  }
  else if ( (ms - lastUpdate) >= (1000 / UPDATE_RATE) && imu.dataReady() )
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
      OscWiFi.send(remoteIp, remotePort, oscPrefix + "/acc", accX, accY, accZ);
      OscWiFi.send(remoteIp, remotePort, oscPrefix + "/gyro", gyroX, gyroY, gyroZ);
      OscWiFi.send(remoteIp, remotePort, oscPrefix + "/mag", magX, magY, magZ);
    }

    alt = bmp.readAltitude();
    //temp = imu.temperature;
    OscWiFi.send(remoteIp, remotePort, oscPrefix + "/altitude", alt);
    //OscWiFi.publish(remoteIp, remotePort, oscPrefix + "/temperature", temp);

    // int raw = analogRead(BATTERY_PIN);
    // float voltage = (raw / ADC_MAX) * 3.3 * VOLTAGE_DIVIDER_RATIO;
    // OscWiFi.send(remoteIp, remotePort, oscPrefix + "/battery", voltage);

    lastUpdate = ms;
  }
}
