#include <Wire.h>
#include <BH1750.h>
#include <Adafruit_SHT31.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ld2410.h>
#include <WiFi.h>
#include <WebServer.h>
#include <HTTPClient.h>

// --- ESP32 I2S AUDIO & TALKIE VOCABULARY ---
#include <Arduino.h>
#include "driver/i2s.h"
#include "Talkie.h"
#include "Vocab_US_Large.h"   // Dictionary 2 (sp2_)
#include "Vocab_US_TI99.h"    // Dictionary 3 (sp3_)
#include "Vocab_US_Clock.h"   // Dictionary 4 (sp4_)
#include "Vocab_Special.h"    // Dictionary Tactical (spt_ - contains HERE)

// =====================================================
// EXACT HARDWARE PIN DEFINITIONS
// =====================================================

// MAX98357A I2S Hardware Audio Pins
#define I2S_LRC   27  // Word Select / LRCK
#define I2S_BCLK  26  // Bit Clock
#define I2S_DIN   25  // Serial Data In

// RGB LED Pins
#define RED_PIN   22
#define GREEN_PIN 18
#define BLUE_PIN  23

// Buzzer & SOS Button Pins
#define BUZZER_PIN 14
#define SOS_PIN    33

// Shared I2C Pins (BH1750, SHT31, SSD1306 Display)
#define I2C_SDA   21
#define I2C_SCL   22

// Battery Voltage Analog Pin
#define BATTERY_PIN 34

// Play audio alarm tone frequencies over speaker on GPIO 25
void playSpeakerTone(int freqHz, int durationMs)
{
  pinMode(I2S_DIN, OUTPUT);
  int delayMicros = 1000000 / (freqHz * 2);
  long numCycles = ((long)durationMs * 1000) / (delayMicros * 2);

  for (long i = 0; i < numCycles; i++) {
    digitalWrite(I2S_DIN, HIGH); // HIGH output on GPIO 25
    delayMicroseconds(delayMicros);
    digitalWrite(I2S_DIN, LOW);  // LOW output on GPIO 25
    delayMicroseconds(delayMicros);
  }
}

// Play Voice Melodic Alert: "NO LIGHT DETECTED"
void playNoLightVoiceAlert()
{
  Serial.println("[SPEAKER] Playing Voice Alert: No Light");
  voice.say(sp2_DANGER);
  voice.say(sp3_NO);
  voice.say(sp3_LIGHT);
}

// Play Voice Melodic Alert: "EMERGENCY DUAL ALERT"
void playDualEmergencyVoiceAlert()
{
  Serial.println("[SPEAKER] Playing DUAL EMERGENCY AUDIO ALERT!");
  playSpeakerTone(1000, 150);
  playSpeakerTone(500, 150);
  playSpeakerTone(1000, 150);
  playSpeakerTone(500, 150);
}

// =====================================================
// WI-FI CONFIGURATION
// =====================================================

const char* ssid = "Abishek";          // Wi-Fi SSID
const char* password = "12345678";     // Wi-Fi Password

// =====================================================
// WEBSERVER
// =====================================================

WebServer server(80);

unsigned long lastTelemetrySync = 0;
unsigned long lastWifiReconnectAttempt = 0;

// =====================================================
// SENSOR & DISPLAY OBJECTS
// =====================================================

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
BH1750 lightMeter;
Adafruit_SHT31 sht31 = Adafruit_SHT31();

ld2410 radar;
HardwareSerial RadarSerial(2);

// Voice Engine Control
Talkie voice;
unsigned long lastVoiceAlert = 0;
const unsigned long voiceInterval = 4000; // Speak alert fast every 4 seconds

// LED Blinking States
unsigned long lastLedBlink = 0;
bool ledState = false;

// Set RGB LED Color
void setRGB(bool red, bool green, bool blue)
{
  digitalWrite(RED_PIN, red ? HIGH : LOW);
  digitalWrite(GREEN_PIN, green ? HIGH : LOW);
  digitalWrite(BLUE_PIN, blue ? HIGH : LOW);
}

// Wi-Fi Auto-Reconnect Guard
void ensureWifiConnected()
{
  if (WiFi.status() != WL_CONNECTED)
  {
    unsigned long now = millis();
    if (now - lastWifiReconnectAttempt > 5000)
    {
      lastWifiReconnectAttempt = now;
      Serial.println("[Wi-Fi] Connection lost. Reconnecting...");
      WiFi.disconnect();
      WiFi.begin(ssid, password);
    }
  }
}

// Global variables for WebServer access
float globalTemperature = 0.0;
float globalHumidity = 0.0;
float globalLux = 0.0;
bool globalPresence = false;
bool globalSosTriggered = false;

void handleRoom()
{
  String jsonPayload = "{";
  jsonPayload += "\"temperature\":" + String(globalTemperature, 1) + ",";
  jsonPayload += "\"humidity\":" + String(globalHumidity, 1) + ",";
  jsonPayload += "\"ambient_light\":" + String(globalLux, 0) + ",";
  jsonPayload += "\"presence_detected\":" + String(globalPresence ? "true" : "false") + ",";
  jsonPayload += "\"emergency_button\":" + String(globalSosTriggered ? "true" : "false");
  jsonPayload += "}";

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", jsonPayload);
}

void handleNotFound() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(404, "text/plain", "Not found");
}

void setup()
{
  // 1. Initialize Serial
  Serial.begin(115200);

  // 2. Initialize Shared I2C Pins (SDA=21, SCL=22)
  Wire.begin(I2C_SDA, I2C_SCL);

  // 3. Configure Pins matching exact user pinout:
  pinMode(RED_PIN, OUTPUT);     // GPIO 22
  pinMode(GREEN_PIN, OUTPUT);   // GPIO 18
  pinMode(BLUE_PIN, OUTPUT);    // GPIO 23
  pinMode(BUZZER_PIN, OUTPUT);  // GPIO 14
  pinMode(SOS_PIN, INPUT_PULLUP); // GPIO 33

  // 4. Set default initial states
  setRGB(false, false, false);
  digitalWrite(BUZZER_PIN, LOW);

  // 5. Start OLED Display (Address 0x3C or 0x3D fallback)
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    display.begin(SSD1306_SWITCHCAPVCC, 0x3D);
  }
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  // 7. Start Light & Climate Modules
  lightMeter.begin();
  sht31.begin(0x44);

  // 8. Start Hardware Serial 2 for Radar at 256000 baud
  RadarSerial.begin(256000, SERIAL_8N1, 16, 17); // RX2=16 (Radar TX), TX2=17 (Radar RX)
  radar.begin(RadarSerial);

  // 9. Start Wi-Fi without modem sleep
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  WiFi.setSleep(false);
  WiFi.begin(ssid, password);

  // 10. Boot UI
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(10, 25);
  display.println("CARE SPHERE NODE");
  display.setCursor(25, 40);
  display.println("I2S READY");
  display.display();

  // Set up WebServer endpoints
  server.on("/api/room", HTTP_GET, handleRoom);
  server.onNotFound(handleNotFound);
  server.begin();
  Serial.println("HTTP server started");

  delay(1500);
}

void loop()
{
  ensureWifiConnected();
  server.handleClient();

  // --- 1. READ ENVIRONMENTAL DATA ---
  globalTemperature = sht31.readTemperature();
  globalHumidity = sht31.readHumidity();
  globalLux = lightMeter.readLightLevel();

  if (isnan(globalTemperature)) globalTemperature = 0.0;
  if (isnan(globalHumidity)) globalHumidity = 0.0;
  if (globalLux < 0) globalLux = 0.0;

  // --- 2. READ RADAR DATA ---
  radar.read();
  globalPresence = false;

  if (radar.isConnected()) 
  {
    if (radar.presenceDetected()) 
    {
      if ((radar.movingTargetDetected() && radar.movingTargetEnergy() > 15) || 
          (radar.stationaryTargetDetected() && radar.stationaryTargetEnergy() > 20)) 
      {
        globalPresence = true;
      }
    }
  }

  // --- 3. CHECK SOS BUTTON (GPIO 33) & BATTERY VOLTAGE ---
  globalSosTriggered = (digitalRead(SOS_PIN) == LOW); // LOW when button pressed

  // FORCE SOS BUZZER TO RING IMMEDIATELY IF SOS BUTTON PRESSED
  if (globalSosTriggered)
  {
    digitalWrite(BUZZER_PIN, HIGH);
  }

  int rawAdc = analogRead(BATTERY_PIN);
  float batteryVolts = (rawAdc / 4095.0) * 3.3 * 2.0;
  bool lowBattery = (rawAdc > 100 && batteryVolts < 3.4);

  // --- 4. RGB LED STATUS & BLINKING SYSTEM ---
  // Color Priorities:
  // 1. EMERGENCY (No Human & No Light OR SOS Pressed) -> Flashing RED (GPIO 22)
  // 2. LOW BATTERY -> GREEN (GPIO 18)
  // 3. NORMAL STATUS -> BLUE (GPIO 23)

  bool emergencySituation = (!globalPresence && globalLux < 20.0) || globalSosTriggered;

  if (millis() - lastLedBlink > 500)
  {
    ledState = !ledState;
    lastLedBlink = millis();
  }

  if (emergencySituation)
  {
    // Flash RED LED (GPIO 22) and sound Buzzer (GPIO 14)
    setRGB(ledState, false, false);
    if (!globalSosTriggered)
    {
      digitalWrite(BUZZER_PIN, ledState ? HIGH : LOW);
    }
  }
  else if (lowBattery)
  {
    // Low Battery: GREEN LED (GPIO 18)
    setRGB(false, true, false);
    digitalWrite(BUZZER_PIN, LOW);
  }
  else
  {
    // Normal Working Mode: BLUE LED (GPIO 23)
    setRGB(false, false, true);
    digitalWrite(BUZZER_PIN, LOW);
  }

  // --- 5. MAX98357A I2S SPEAKER VOICE & AUDIO SYNTHESIS ---
  if (millis() - lastVoiceAlert > voiceInterval) 
  {
    if (globalSosTriggered)
    {
      lastVoiceAlert = millis();
      Serial.println("[VOICE ALERT] SOS ACTIVATED!");
      playDualEmergencyVoiceAlert();
      voice.say(sp2_DANGER);
      voice.say(sp2_ALERT);
    }
    // DUAL EMERGENCY ALERT: BOTH NO LIGHT & NO HUMAN
    else if (!globalPresence && globalLux < 20.0)
    {
      lastVoiceAlert = millis();
      Serial.println("[VOICE ALERT] NO LIGHT & NO HUMAN PRESENT!");
      playDualEmergencyVoiceAlert();
      voice.say(spt_NO);
      voice.say(sp2_LIGHT);
      voice.say(sp2_ALERT);
    }
    // NO LIGHT DETECTED ALERT -> "NO LIGHT"
    else if (globalLux < 20.0) 
    {
      lastVoiceAlert = millis();
      Serial.println("[VOICE ALERT] NO LIGHT DETECTED!");
      playNoLightVoiceAlert();
      voice.say(spt_NO);
      voice.say(sp2_LIGHT);
    } 
    // NO HUMAN DETECTED ALERT -> "NO HUMAN PRESENT"
    else if (!globalPresence) 
    {
      lastVoiceAlert = millis();
      Serial.println("[VOICE ALERT] NO HUMAN DETECTED IN ROOM!");
      playNoHumanVoiceAlert();
      voice.say(sp2_ALERT);
      voice.say(sp2_SERVICE);
    }
  }

  // The dashboard will poll /api/room to get this data

  // --- 7. OLED DISPLAY INTERFACE ---
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("=== CARE SPHERE NODE ===");
  display.println("");
  
  display.print("Temp : "); display.print(globalTemperature, 1); display.println(" C");
  display.print("Hum  : "); display.print(globalHumidity, 1); display.println(" %");
  display.print("Light: "); display.print(globalLux, 0); display.println(" lx");

  display.println("-------------------");
  display.print("Status: ");
  if (emergencySituation) display.println("EMERGENCY!");
  else if (globalPresence) display.println("PRESENT");
  else display.println("ROOM EMPTY");

  display.display();

  // --- 8. SERIAL LOGGING ---
  Serial.print("T:"); Serial.print(globalTemperature, 1);
  Serial.print(" | H:"); Serial.print(globalHumidity, 1);
  Serial.print(" | L:"); Serial.print(globalLux, 0);
  Serial.print(" | Present:"); Serial.print(globalPresence ? "YES" : "NO");
  Serial.print(" | SOS:"); Serial.println(globalSosTriggered ? "YES" : "NO");

  delay(200);
}
