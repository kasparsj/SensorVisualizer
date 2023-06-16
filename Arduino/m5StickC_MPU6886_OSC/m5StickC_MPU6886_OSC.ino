#include <M5StickC.h>
#include <Wire.h>
#include "Adafruit_Sensor.h"
#include <Adafruit_BMP280.h>
#include "bmm150.h"
#include "bmm150_defs.h"
#include "esp_wpa2.h"
#include <WiFi.h>
#include <ArduinoOSCWiFi.h>
#include <Adafruit_AHRS.h>

#define DEVICE_ID "m5StickC"
#define ENV_HAT_ENABLED 1
#define OSC_PREFIX "/polar"
#define SEND_QUAT 1
#define sampleFreq  60.0f // todo: find a way to change this, looks like this over the maximum

#define SSID "toplap-ka"
#define PASSWORD "toplap-ka"

// #define SSID "Insternet"
// #define EAP_IDENTITY "kaspars"
// #define EAP_PASSWORD "KHD.Tj7.Uov"

const char* oscAddress = "kaspars.local";
const int oscPort = 57121;
String oscPrefix = String(OSC_PREFIX);

// IMU
//Adafruit_NXPSensorFusion filter; // slowest
//Adafruit_Madgwick filter;  // faster than NXP
Adafruit_Mahony filter;  // fastest/smalleset

float accX, accY, accZ = 0;
float gyroX, gyroY, gyroZ = 0;
float qx, qy, qz, qw = 0;
float pitch, roll, yaw = 0;
float temp = 0;

// ENV HAT
BMM150 bmm = BMM150();
bool bmmInitialized = false;
bmm150_mag_data mag_offset;
float magX, magY, magZ = 0;
Adafruit_BMP280 bme;
bool bmeInitialized = false;
float press, alt = 0;
float headingDegrees;

// buttons
int aValue;
int lastAValue;
int bValue;
int lastBValue;

// state
bool paused = true;
long lastMs = 0;

void setup() {
  M5.begin();
  Wire.begin(0,26);
  M5.Lcd.setRotation(3);
  M5.Lcd.setTextSize(1);
  
  M5.Lcd.fillScreen(BLACK);
  M5.Lcd.setCursor(0, 0);
  setupWifi();

  M5.IMU.Init();
  #if ENV_HAT_ENABLED
  setupEnvHat();
  #endif
  M5.Lcd.fillScreen(BLACK);

  lastMs = millis();

  pinMode(BUTTON_A_PIN, INPUT);
  pinMode(BUTTON_B_PIN, INPUT);

  filter.begin(sampleFreq);
}

void setupWifi() {
  M5.Lcd.print("CONNECTING WIFI ");
  M5.Lcd.print(SSID);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();

#ifdef EAP_IDENTITY
  esp_wifi_sta_wpa2_ent_set_username((uint8_t *)EAP_IDENTITY, strlen(EAP_IDENTITY));
  esp_wifi_sta_wpa2_ent_set_password((uint8_t *)EAP_PASSWORD, strlen(EAP_PASSWORD));
  //esp_wpa2_config_t config = WPA2_CONFIG_INIT_DEFAULT();
  //esp_wifi_sta_wpa2_ent_enable(&config);
  esp_wifi_sta_wpa2_ent_enable();
  WiFi.begin(SSID);
#else
  WiFi.begin(SSID, PASSWORD);  
#endif
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    M5.Lcd.print(".");
  }
  Serial.println("");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void setupEnvHat() {
  Serial.println("Initializing BME");
  if (!bme.begin(0x76)){  
      Serial.println("BMP280 not found");
  }
  else {
    bmeInitialized = true;
  }
  Serial.println("Initializing BMM");
  int res = bmm.initialize();
  if(res == BMM150_E_ID_NOT_CONFORM) {
    Serial.printf("BMM150 not found: %d\r\n", res);
  } else {
    Serial.println("Calibrating BMM150...");      
    calibrateBmm(10);
    Serial.println("Calibration done.");          
    bmmInitialized = true;
  }
}

void calibrateBmm(uint32_t timeout)
{
  int16_t mag_x_min = 0;
  int16_t mag_x_max = 0;
  int16_t mag_y_min = 0;
  int16_t mag_y_max = 0;
  int16_t mag_z_min = 0;
  int16_t mag_z_max = 0;
  uint32_t timeStart = 0;

  bmm.read_mag_data();  
  mag_x_min = bmm.raw_mag_data.raw_datax;
  mag_x_max = bmm.raw_mag_data.raw_datax;
  mag_y_min = bmm.raw_mag_data.raw_datay;
  mag_y_max = bmm.raw_mag_data.raw_datay;
  mag_z_min = bmm.raw_mag_data.raw_dataz;
  mag_z_max = bmm.raw_mag_data.raw_dataz;
  delay(100);

  timeStart = millis();
  
  while((millis() - timeStart) < timeout)
  {
    bmm.read_mag_data();
    
    /* Update x-Axis max/min mag */
    if(mag_x_min > bmm.raw_mag_data.raw_datax)
    {
      mag_x_min = bmm.raw_mag_data.raw_datax;
      // Serial.print("Update mag_x_min: ");
      // Serial.println(mag_x_min);

    } 
    else if(mag_x_max < bmm.raw_mag_data.raw_datax)
    {
      mag_x_max = bmm.raw_mag_data.raw_datax;
      // Serial.print("update mag_x_max: ");
      // Serial.println(mag_x_max);
    }

    /* Update y-Axis max/min mag */
    if(mag_y_min > bmm.raw_mag_data.raw_datay)
    {
      mag_y_min = bmm.raw_mag_data.raw_datay;
      // Serial.print("Update mag_y_min: ");
      // Serial.println(mag_y_min);

    } 
    else if(mag_y_max < bmm.raw_mag_data.raw_datay)
    {
      mag_y_max = bmm.raw_mag_data.raw_datay;
      // Serial.print("update mag_y_max: ");
      // Serial.println(mag_y_max);
    }

    /* Update z-Axis max/min mag */
    if(mag_z_min > bmm.raw_mag_data.raw_dataz)
    {
      mag_z_min = bmm.raw_mag_data.raw_dataz;
      // Serial.print("Update mag_z_min: ");
      // Serial.println(mag_z_min);

    } 
    else if(mag_z_max < bmm.raw_mag_data.raw_dataz)
    {
      mag_z_max = bmm.raw_mag_data.raw_dataz;
      // Serial.print("update mag_z_max: ");
      // Serial.println(mag_z_max);
    }
    
    Serial.print(".");
    delay(1);

  }

  mag_offset.x = mag_x_min + (mag_x_max - mag_x_min)/2;
  mag_offset.y = mag_y_min + (mag_y_max - mag_y_min)/2;
  mag_offset.z = mag_z_min + (mag_z_max - mag_z_min)/2;
}

void loop() {
  long ms = millis();
  if (paused) {
    handleButtons();
    M5.Lcd.setCursor(0, 0);
    M5.Lcd.println("PAUSED");
    printStatus();
    delay(100);
  }
  if ((ms - lastMs) < (1000.f / sampleFreq)) {
    return;
  }
  handleButtons();
  updateIMU();
  updateENV();
  if (bmmInitialized) {
    filter.update(gyroX, gyroY, gyroZ, accX, accY, accZ, magX, magY, magZ);
  }
  else {
    filter.updateIMU(gyroX, gyroY, gyroZ, accX, accY, accZ);
  }
  #if (SEND_QUAT)
    filter.getQuaternion(&qw, &qx, &qy, &qz);
  #else
    roll = filter.getRoll();
    pitch = filter.getPitch();
    yaw = filter.getYaw();
  #endif

  sendOSC();
  M5.Lcd.setCursor(0, 0);
  M5.Lcd.println("RECORDING");
  printIMU();
  printENV();
  printStatus();
  lastMs = ms;
}

void handleButtons() {
  aValue = digitalRead(BUTTON_A_PIN);
  bValue = digitalRead(BUTTON_B_PIN);
  if (aValue != lastAValue) {
    if (aValue == 0) { // button down
      paused = !paused;
      M5.Lcd.fillScreen(BLACK);
    }
  }
  if (bValue != lastBValue) {
    if (bValue == 0) {
      M5.Lcd.fillScreen(BLACK);
    }
  }
  lastAValue = aValue;
  lastBValue = bValue;
}

void updateIMU() {
  M5.IMU.getAccelData(&accX, &accY, &accZ);
  M5.IMU.getGyroData(&gyroX, &gyroY, &gyroZ);
  M5.IMU.getTempData(&temp);
}

void updateENV() {
  if (bmmInitialized) {
    updateBMM();
  }
  if (bmeInitialized) {
    updateBMP();
  }
}

void updateBMM() {
  bmm.read_mag_data();

  magX = bmm.raw_mag_data.raw_datax - mag_offset.x;
  magY = bmm.raw_mag_data.raw_datay - mag_offset.y;
  magZ = bmm.raw_mag_data.raw_dataz - mag_offset.z;

  float xyHeading = atan2(magX, magY);
  float zxHeading = atan2(magZ, magX);
  float heading = xyHeading;

  if(heading < 0)
    heading += 2*PI;
  if(heading > 2*PI)
    heading -= 2*PI;
  headingDegrees = heading * 180/M_PI; 
  
  float xyHeadingDegrees = xyHeading * 180 / M_PI;
  float zxHeadingDegrees = zxHeading * 180 / M_PI;

//  Serial.print("xyHeadingDegrees: ");
//  Serial.println(xyHeadingDegrees);
//  Serial.print("zxHeadingDegrees: ");
//  Serial.println(zxHeadingDegrees);
//  M5.Lcd.printf("headingDegrees: %2.1f", headingDegrees);
}

void updateBMP() {
  //float pressure = bme.readPressure();
  //M5.Lcd.printf("pressure: %2.1f", pressure);

  alt = bme.readAltitude();
}

void sendOSC() {
  OscWiFi.send(oscAddress, oscPort, oscPrefix + "/acc", DEVICE_ID, accX, accY, accZ);
  OscWiFi.send(oscAddress, oscPort, oscPrefix + "/gyro_deg", DEVICE_ID, gyroX, gyroY, gyroZ);
  #if SEND_QUAT
  OscWiFi.send(oscAddress, oscPort, oscPrefix + "/quat", DEVICE_ID, qx, qy, qz, qw);
  #else
  OscWiFi.send(oscAddress, oscPort, oscPrefix + "/euler_deg", DEVICE_ID, roll, pitch, yaw);
  #endif

  if (bmeInitialized) {
    OscWiFi.send(oscAddress, oscPort, oscPrefix + "/altitude", DEVICE_ID, alt);
  }
  if (bmmInitialized) {
    OscWiFi.send(oscAddress, oscPort, oscPrefix + "/mag", DEVICE_ID, magX, magY, magZ);
    OscWiFi.send(oscAddress, oscPort, oscPrefix + "/comp", DEVICE_ID, headingDegrees);
  }
}

void printIMU() {
  M5.Lcd.print("Pitch    Roll   Yaw\r\n");
  M5.Lcd.printf("%.2f   %.2f   %.2f\r\n", pitch, roll, yaw);
}

void printENV() {
  if (bmmInitialized) {
      M5.Lcd.print("Heading: ");
      M5.Lcd.println(headingDegrees);
  }
  if (bmeInitialized) {
    M5.Lcd.printf("Altitude: %2.1f\r\n", alt);
  }
}

void printStatus() {
  printSpeed();
  printTemp();
  printBattery();
}

void printSpeed() {
  M5.Lcd.printf("Speed: %3u Hz\r\n", 1000 / (millis()-lastMs)); // 6ms / 166hz
}

void printTemp() {
  M5.Lcd.printf("Temperature : %.2f C\r\n", temp);
}

void printBattery() {
  // 30 mins battery life
  // 45 mins charging
  M5.Lcd.printf("Battery: %3u%%\r\n ", (int) (((M5.Axp.GetBatVoltage() - 3.f) / 1.15f) * 100.f));
//  M5.Lcd.printf("vbat:%.3fV\r\n", M5.Axp.GetBatVoltage()); // 4.16 - 3.05
//  M5.Lcd.printf("aps:%.3fV\r\n", M5.Axp.GetAPSVoltage()); // 4.9 - 3.03
//  M5.Lcd.printf("level:%d\r\n", M5.Axp.GetWarningLevel());
}
