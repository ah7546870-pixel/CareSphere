#include <Wire.h>
#include <MAX30105.h>
#include <WiFi.h>
#include <WebServer.h>
#include "spo2_algorithm.h"

// =====================================================
// WI-FI CONFIGURATION
// =====================================================

const char* ssid = "Abishek";          // Wi-Fi SSID
const char* password = "12345678";     // Wi-Fi Password

// =====================================================
// WEBSERVER
// =====================================================

WebServer server(80);

// =====================================================
// I2C PINS & STATUS LED
// =====================================================

#define SDA_PIN 8
#define SCL_PIN 9
#define LED_PIN 10  // Built-in status LED indicator

// =====================================================
// I2C ADDRESSES
// =====================================================

#define MAX30102_ADDR 0x57
#define MPU6050_ADDR  0x68

// =====================================================
// MAX30102 SETTINGS
// =====================================================

#define BUFFER_SIZE 100
#define FINGER_THRESHOLD 30000

// =====================================================
// SENSOR OBJECT
// =====================================================

MAX30105 max30102;

// =====================================================
// SENSOR STATUS
// =====================================================

bool maxOK = false;
bool mpuOK = false;

// =====================================================
// MAX30102 BUFFERS
// =====================================================

uint32_t irBuffer[BUFFER_SIZE];
uint32_t redBuffer[BUFFER_SIZE];

// =====================================================
// HR / SpO2
// =====================================================

int32_t heartRate = 0;
int8_t validHeartRate = 0;

int32_t spo2 = 0;
int8_t validSpO2 = 0;

// =====================================================
// MPU6050 REGISTERS
// =====================================================

#define MPU_PWR_MGMT_1   0x6B
#define MPU_SMPLRT_DIV   0x19
#define MPU_CONFIG       0x1A
#define MPU_GYRO_CONFIG  0x1B
#define MPU_ACCEL_CONFIG 0x1C
#define MPU_ACCEL_XOUT_H 0x3B
#define MPU_WHO_AM_I     0x75

// =====================================================
// MPU DATA
// =====================================================

float accX = 0;
float accY = 0;
float accZ = 0;

float gyroX = 0;
float gyroY = 0;
float gyroZ = 0;

float accMagnitude = 0;
float gyroMagnitude = 0;

bool motionDetected = false;

// =====================================================
// FILTERED VALUES & TIMERS
// =====================================================

float smoothHR = 0;
float smoothSpO2 = 0;

unsigned long lastStatusPrint = 0;
unsigned long lastTelemetrySync = 0;


// Track Wi-Fi reconnect attempts non-blockingly
unsigned long lastWifiReconnectAttempt = 0;

void ensureWifiConnected()
{
  if (WiFi.status() != WL_CONNECTED)
  {
    unsigned long now = millis();
    if (now - lastWifiReconnectAttempt > 5000)
    {
      lastWifiReconnectAttempt = now;
      Serial.println("[Wi-Fi] Connection lost. Attempting auto-reconnect...");
      WiFi.disconnect();
      WiFi.begin(ssid, password);
    }
  }
}

void handleVitals()
{
  digitalWrite(LED_PIN, HIGH);

  String jsonPayload = "{";
  jsonPayload += "\"heart_rate\":" + String((int)smoothHR) + ",";
  jsonPayload += "\"spo2\":" + String((int)smoothSpO2) + ",";
  jsonPayload += "\"accel_x\":" + String(accX, 2) + ",";
  jsonPayload += "\"accel_y\":" + String(accY, 2) + ",";
  jsonPayload += "\"accel_z\":" + String(accZ, 2) + ",";
  jsonPayload += "\"gyro_x\":" + String(gyroX, 2) + ",";
  jsonPayload += "\"gyro_y\":" + String(gyroY, 2) + ",";
  jsonPayload += "\"gyro_z\":" + String(gyroZ, 2) + ",";
  jsonPayload += "\"fall_detected\":" + String(motionDetected ? "true" : "false");
  jsonPayload += "}";

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", jsonPayload);

  digitalWrite(LED_PIN, LOW);
}

void handleNotFound() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(404, "text/plain", "Not found");
}


// =====================================================
// CHECK I2C DEVICE
// =====================================================

bool deviceExists(uint8_t address)
{
  Wire.beginTransmission(address);
  byte error = Wire.endTransmission();
  return (error == 0);
}


// =====================================================
// WRITE MPU6050 REGISTER
// =====================================================

void writeMPURegister(uint8_t reg, uint8_t value)
{
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
}


// =====================================================
// READ MPU6050 REGISTERS
// =====================================================

bool readMPURegisters(uint8_t startRegister, uint8_t *data, uint8_t length)
{
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(startRegister);

  if (Wire.endTransmission(false) != 0)
  {
    return false;
  }

  uint8_t received = Wire.requestFrom(MPU6050_ADDR, length);

  if (received != length)
  {
    return false;
  }

  for (uint8_t i = 0; i < length; i++)
  {
    data[i] = Wire.read();
  }

  return true;
}


// =====================================================
// READ ONE MPU REGISTER
// =====================================================

uint8_t readMPURegister(uint8_t reg)
{
  uint8_t value = 0;
  readMPURegisters(reg, &value, 1);
  return value;
}


// =====================================================
// INITIALIZE MPU6050
// =====================================================

bool initializeMPU6050()
{
  Serial.println();
  Serial.println("Initializing MPU6050...");

  if (!deviceExists(MPU6050_ADDR))
  {
    Serial.println("MPU6050 NOT FOUND at 0x68");
    return false;
  }

  Serial.println("MPU6050 found at 0x68");

  uint8_t whoAmI = readMPURegister(MPU_WHO_AM_I);
  Serial.print("WHO_AM_I = 0x");
  Serial.println(whoAmI, HEX);

  // Accept 0x68 (MPU6050), 0x70 (MPU6500), 0x71 (MPU9250)
  if (whoAmI != 0x68 && whoAmI != 0x70 && whoAmI != 0x71)
  {
    Serial.println("WARNING: Unexpected WHO_AM_I - proceeding anyway...");
  }

  writeMPURegister(MPU_PWR_MGMT_1, 0x00);
  delay(100);

  writeMPURegister(MPU_SMPLRT_DIV, 9);
  writeMPURegister(MPU_CONFIG, 0x03);
  writeMPURegister(MPU_GYRO_CONFIG, 0x08);
  writeMPURegister(MPU_ACCEL_CONFIG, 0x10);

  delay(100);
  Serial.println("MPU6050 READY");
  return true;
}


// =====================================================
// READ MPU6050
// =====================================================

void readMPU6050()
{
  if (!mpuOK)
  {
    return;
  }

  uint8_t data[14];

  if (!readMPURegisters(MPU_ACCEL_XOUT_H, data, 14))
  {
    motionDetected = true;
    return;
  }

  int16_t rawAccX = ((int16_t)data[0] << 8) | data[1];
  int16_t rawAccY = ((int16_t)data[2] << 8) | data[3];
  int16_t rawAccZ = ((int16_t)data[4] << 8) | data[5];

  int16_t rawGyroX = ((int16_t)data[8] << 8) | data[9];
  int16_t rawGyroY = ((int16_t)data[10] << 8) | data[11];
  int16_t rawGyroZ = ((int16_t)data[12] << 8) | data[13];

  accX = (rawAccX / 4096.0) * 9.80665;
  accY = (rawAccY / 4096.0) * 9.80665;
  accZ = (rawAccZ / 4096.0) * 9.80665;

  gyroX = rawGyroX / 65.5;
  gyroY = rawGyroY / 65.5;
  gyroZ = rawGyroZ / 65.5;

  accMagnitude = sqrt(accX * accX + accY * accY + accZ * accZ);
  gyroMagnitude = sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);

  float accelerationChange = fabs(accMagnitude - 9.80665);

  if (accelerationChange > 1.2 || gyroMagnitude > 15.0)
  {
    motionDetected = true;
  }
  else
  {
    motionDetected = false;
  }
}


// =====================================================
// PRINT MPU DATA
// =====================================================

void printMPUData()
{
  Serial.print("ACC X: ");
  Serial.print(accX, 2);

  Serial.print(" | ACC Y: ");
  Serial.print(accY, 2);

  Serial.print(" | ACC Z: ");
  Serial.print(accZ, 2);

  Serial.print(" m/s2");

  Serial.print(" || GYRO X: ");
  Serial.print(gyroX, 2);

  Serial.print(" | GYRO Y: ");
  Serial.print(gyroY, 2);

  Serial.print(" | GYRO Z: ");
  Serial.print(gyroZ, 2);

  Serial.println(" deg/s");
}


// =====================================================
// INITIALIZE MAX30102
// =====================================================

bool initializeMAX30102()
{
  Serial.println();
  Serial.println("Initializing MAX30102...");

  if (!deviceExists(MAX30102_ADDR))
  {
    Serial.println("MAX30102 NOT FOUND");
    return false;
  }

  Serial.println("MAX30102 detected at 0x57");

  if (!max30102.begin(Wire, I2C_SPEED_STANDARD, MAX30102_ADDR))
  {
    Serial.println("MAX30102 initialization failed");
    return false;
  }

  byte ledBrightness = 60;
  byte sampleAverage = 4;
  byte ledMode = 2;
  int sampleRate = 100;
  int pulseWidth = 411;
  int adcRange = 4096;

  max30102.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);

  max30102.setPulseAmplitudeRed(0x3F);
  max30102.setPulseAmplitudeIR(0x3F);
  max30102.setPulseAmplitudeGreen(0);

  Serial.println("MAX30102 READY");
  return true;
}


// =====================================================
// FINGER DETECTION
// =====================================================

bool fingerDetected(uint32_t irValue)
{
  return (irValue > FINGER_THRESHOLD);
}


// =====================================================
// MEASURE HR + SPO2
// =====================================================

bool measureHeartData()
{
  if (!maxOK)
  {
    return false;
  }

  for (int i = 0; i < BUFFER_SIZE; i++)
  {
    while (!max30102.available())
    {
      max30102.check();
      readMPU6050();
      delay(1);
    }

    redBuffer[i] = max30102.getRed();
    irBuffer[i] = max30102.getIR();
    max30102.nextSample();
  }

  uint64_t totalIR = 0;
  for (int i = 0; i < BUFFER_SIZE; i++)
  {
    totalIR += irBuffer[i];
  }

  uint32_t averageIR = totalIR / BUFFER_SIZE;

  if (averageIR < FINGER_THRESHOLD)
  {
    Serial.println();
    Serial.println("Finger not placed");
    return false;
  }

  uint32_t minIR = irBuffer[0];
  uint32_t maxIR = irBuffer[0];

  for (int i = 1; i < BUFFER_SIZE; i++)
  {
    if (irBuffer[i] < minIR) minIR = irBuffer[i];
    if (irBuffer[i] > maxIR) maxIR = irBuffer[i];
  }

  uint32_t signalRange = maxIR - minIR;

  if (signalRange < 500)
  {
    Serial.println();
    Serial.println("PPG signal too weak");
    Serial.print("IR Average: ");
    Serial.println(averageIR);
    Serial.print("IR Range: ");
    Serial.println(signalRange);
    return false;
  }

  maxim_heart_rate_and_oxygen_saturation(
    irBuffer,
    BUFFER_SIZE,
    redBuffer,
    &spo2,
    &validSpO2,
    &heartRate,
    &validHeartRate
  );

  readMPU6050();

  if (motionDetected)
  {
    Serial.println();
    Serial.println("Motion detected - measurement rejected");
    printMPUData();

    sendDataToDatabase();
    return false;
  }

  bool goodHR = validHeartRate && heartRate >= 40 && heartRate <= 180;
  bool goodSpO2 = validSpO2 && spo2 >= 90 && spo2 <= 100;

  if (goodHR)
  {
    if (smoothHR == 0)
    {
      smoothHR = heartRate;
    }
    else
    {
      smoothHR = (smoothHR * 0.70) + (heartRate * 0.30);
    }
  }

  if (goodSpO2)
  {
    if (smoothSpO2 == 0)
    {
      smoothSpO2 = spo2;
    }
    else
    {
      smoothSpO2 = (smoothSpO2 * 0.70) + (spo2 * 0.30);
    }
  }

  Serial.println();
  Serial.println("================================");
  Serial.println("Finger: DETECTED");

  if (goodHR)
  {
    Serial.print("Heart Rate: ");
    Serial.print(smoothHR, 0);
    Serial.println(" BPM");
  }
  else
  {
    Serial.println("Heart Rate: Signal unstable");
  }

  if (goodSpO2)
  {
    Serial.print("SpO2: ");
    Serial.print(smoothSpO2, 0);
    Serial.println(" %");
  }
  else
  {
    Serial.println("SpO2: Signal unstable");
  }

  Serial.print("IR Average: ");
  Serial.println(averageIR);
  Serial.print("IR Range: ");
  Serial.println(signalRange);
  printMPUData();
  Serial.println("================================");

  // The dashboard will poll /api/vitals to get this data

  return true;
}


// =====================================================
// SETUP
// =====================================================

void setup()
{
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Serial.setTxTimeoutMs(0); 
  Serial.begin(115200);

  delay(2000);

  Serial.println();
  Serial.println("======================================");
  Serial.println(" ESP32-C3 HEALTH SENSOR SYSTEM");
  Serial.println(" MAX30102 + MPU6050");
  Serial.println("======================================");

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  WiFi.setSleep(false); // Prevent Wi-Fi radio from turning off when unplugged from USB power
  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi-Fi");

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30)
  {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED)
  {
    Serial.println("\nWi-Fi Connected successfully!");
    Serial.print("ESP32 IP Address: ");
    Serial.println(WiFi.localIP());
  }
  else
  {
    Serial.println("\nWi-Fi connection pending background retry...");
  }

  // Set up WebServer endpoints
  server.on("/api/vitals", HTTP_GET, handleVitals);
  server.onNotFound(handleNotFound);
  server.begin();
  Serial.println("HTTP server started");

  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000);
  delay(500);

  Serial.println();
  Serial.println("I2C SCAN");
  Serial.println("-------------------------");

  if (deviceExists(0x57)) Serial.println("0x57 -> MAX30102");
  if (deviceExists(0x68)) Serial.println("0x68 -> MPU6050");

  Serial.println("-------------------------");
  delay(500);

  maxOK = initializeMAX30102();
  delay(500);

  mpuOK = initializeMPU6050();
  delay(500);

  Serial.println();
  Serial.println("======================================");
  if (maxOK) Serial.println("MAX30102 : OK");
  else Serial.println("MAX30102 : FAILED");

  if (mpuOK) Serial.println("MPU6050  : OK @ 0x68");
  else Serial.println("MPU6050  : FAILED");
  Serial.println("======================================");

  if (maxOK && mpuOK)
  {
    Serial.println();
    Serial.println("SYSTEM READY");
    Serial.println("Place ONE finger on MAX30102");
    Serial.println("Keep your hand still");
  }
}


// =====================================================
// LOOP (NON-BLOCKING CONTINUOUS EXECUTION)
// =====================================================

void loop()
{
  ensureWifiConnected();
  server.handleClient();

  if (mpuOK)
  {
    readMPU6050();
  }

  if (!maxOK)
  {
    delay(500);
    return;
  }

  max30102.check();

  if (!max30102.available())
  {
    delay(10);
    return;
  }

  uint32_t irValue = max30102.getIR();
  max30102.nextSample();

  if (!fingerDetected(irValue))
  {
    smoothHR = 0;
    smoothSpO2 = 0;

    if (millis() - lastStatusPrint > 1000)
    {
      Serial.println();
      Serial.println("Finger not placed");
      if (mpuOK)
      {
        printMPUData();
      }
      lastStatusPrint = millis();
    }
    delay(10);
    return;
  }

  if (millis() - lastStatusPrint > 1500)
  {
    Serial.println();
    Serial.println("Finger detected - measuring...");
    lastStatusPrint = millis();
  }

  measureHeartData();
  delay(100);
}
