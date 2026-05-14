#include <DHT.h>
#include <WiFi.h>


#include <WebServer.h>

// --- WiFi Credentials ---
char ssid[] = "bee";
char pass[] = "bee123456";

// --- Pin Definitions ---
#define DHTPIN 4
#define DHTTYPE DHT11

#define SOUND_PIN 34    // Analog
#define VIBRATION_PIN 5 // Digital
#define LDR_PIN 35      // Analog
#define BUZZER_PIN 2

// Buttons
#define BTN_MUTE_PIN 27 // NEW: Mute

DHT dht(DHTPIN, DHTTYPE);
unsigned long lastSensorRead = 0;
const long interval = 2000;

WebServer server(80);

// --- Thresholds ---
float TEMP_HIGH_THRESHOLD = 45.0;
float TEMP_LOW_THRESHOLD = 10.0;
int SOUND_THRESHOLD = 2500;
int LIGHT_THRESHOLD = 2000;  // Below this = light detected (box opened)

// --- Variables ---
unsigned long buzzerTimer = 0;
bool buzzerActive = false;
unsigned long lastAlertTime = 0;

// Mute Logic
bool isMuted = false;

// --- Sensor State for App ---
float currentTemp = 0.0;
float currentHumidity = 0.0;
int currentSound = 0;
int currentVibration = 0;
int currentLight = 0;
String currentAlertCause = "None";

void triggerAlert(String cause) {
  // If Muted, SKIP buzzer, but still log event
  if (!buzzerActive && !isMuted) {
    buzzerActive = true;
    buzzerTimer = millis();
    digitalWrite(BUZZER_PIN, HIGH);
  } else if (isMuted) {
    digitalWrite(BUZZER_PIN, LOW); // Ensure off if muted
  }

  if (millis() - lastAlertTime > 10000) {
    Serial.println("ALERT TRIGGERED: " + cause + (isMuted ? " (MUTED)" : ""));
    currentAlertCause = cause;
    lastAlertTime = millis();
  }
}

void turnOffBuzzer() {
  digitalWrite(BUZZER_PIN, LOW);
  buzzerActive = false;
}

void sendSensorData() {
  bool alertConditionMet = false;

  // 1. Temperature & Humidity
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (!isnan(h) && !isnan(t)) {
    currentTemp = t;
    currentHumidity = h;

    if (t > TEMP_HIGH_THRESHOLD) {
      triggerAlert("High Temp: " + String(t) + "C");
      alertConditionMet = true;
    } else if (t < TEMP_LOW_THRESHOLD) {
      triggerAlert("Low Temp: " + String(t) + "C");
      alertConditionMet = true;
    }
  }

  // 3. Sound
  int soundLevel = analogRead(SOUND_PIN);
  currentSound = soundLevel;
  if (soundLevel > SOUND_THRESHOLD) {
    triggerAlert("High Noise: " + String(soundLevel));
    alertConditionMet = true;
  }

  // 4. Vibration
  int vibration = digitalRead(VIBRATION_PIN);
  currentVibration = vibration;
  if (vibration == HIGH) {
    triggerAlert("Vibration Detected!");
    alertConditionMet = true;
  }

  // 5. Light (LDR inside box: dark=high value, light=low value)
  // When someone opens the box, light enters → value drops → alert!
  int lightLevel = analogRead(LDR_PIN);
  currentLight = lightLevel;
  if (lightLevel < LIGHT_THRESHOLD) {
    triggerAlert("Light Detected - Box Opened!");
    alertConditionMet = true;
  }

  // Reset Mute if ALL conditions are CLEAR
  if (!alertConditionMet) {
    currentAlertCause = "None";
    if (isMuted) {
      Serial.println("Conditions Clear - Auto Unmuting");
      isMuted = false;
    }
  }
}

void sendCORS() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.sendHeader("Connection", "close");
}

void handlePing() {
  sendCORS();
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleData() {
  String json = "{";
  json += "\"temp\":" + String(currentTemp) + ",";
  json += "\"humidity\":" + String(currentHumidity) + ",";
  json += "\"sound\":" + String(currentSound) + ",";
  json += "\"vibration\":" + String(currentVibration) + ",";
  json += "\"light\":" + String(currentLight) + ",";
  json += "\"isMuted\":" + String(isMuted ? "true" : "false") + ",";
  json += "\"alert\":\"" + currentAlertCause + "\"";
  json += "}";

  sendCORS();
  server.send(200, "application/json", json);
}

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Beehive System...");

  dht.begin();

  pinMode(VIBRATION_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(SOUND_PIN, INPUT);
  pinMode(LDR_PIN, INPUT);

  pinMode(BTN_MUTE_PIN, INPUT_PULLUP); // Mute Button

  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  WiFi.setSleep(false);
  WiFi.begin(ssid, pass);

  int wifi_timeout = 0;
  while (WiFi.status() != WL_CONNECTED && wifi_timeout < 40) {
    delay(500);
    Serial.print(".");
    wifi_timeout++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    // Start Web Server
    server.on("/ping", HTTP_GET, handlePing);
    server.on("/data", HTTP_GET, handleData);
    server.begin();
    Serial.println("HTTP server started");
  } else {
    Serial.println("\nWiFi Connection Failed!");
  }

  lastSensorRead = millis();
}

// --- WiFi Auto-Reconnect ---
unsigned long lastWifiCheck = 0;
const long wifiCheckInterval = 10000; // Check every 10 seconds

void checkWiFiReconnect() {
  if (WiFi.status() != WL_CONNECTED && millis() - lastWifiCheck > wifiCheckInterval) {
    lastWifiCheck = millis();
    Serial.println("WiFi lost! Reconnecting...");
    WiFi.disconnect();
    WiFi.begin(ssid, pass);
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
      delay(250);
      Serial.print(".");
      attempts++;
    }
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nWiFi Reconnected! IP: " + WiFi.localIP().toString());
      server.begin(); // Restart server after reconnect
    } else {
      Serial.println("\nReconnection failed. Will retry...");
    }
  }
}

void loop() {
  // Auto-reconnect WiFi if disconnected
  checkWiFiReconnect();

  if (WiFi.status() == WL_CONNECTED) {
    server.handleClient();
  }
 
  if (millis() - lastSensorRead >= interval) {
    lastSensorRead = millis();
    sendSensorData();
  }

  if (buzzerActive && (millis() - buzzerTimer > 500)) {
    turnOffBuzzer();
  }

  // --- Mute Button Logic ---
  if (digitalRead(BTN_MUTE_PIN) == LOW) {
    if (!isMuted) {
      isMuted = true;
      Serial.println("System MUTED by User");
      turnOffBuzzer(); // Stop current beep
    } else {
      isMuted = false;
      Serial.println("System UNMUTED by User");
      // Buzzer will resume on next cycle if alert persists
    }
    delay(500); // Debounce long delay for toggle
  }
}
