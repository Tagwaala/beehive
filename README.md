# Smart Beehive Monitor 🐝

A real-time monitoring system for beehives using **ESP32** and a **Flutter** mobile application. It tracks temperature, humidity, sound levels, vibration, and light (to detect if the box is opened).

---

## 🛠 Required Softwares

### 1. For ESP32 (Hardware)
* **Arduino IDE** (Latest version)
* **ESP32 Board Support**: Add `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json` to Preferences -> Additional Board Manager URLs.
* **Arduino Libraries**:
    * `DHT sensor library` (by Adafruit)
    * `Adafruit Unified Sensor`

### 2. For Flutter App (Mobile)
* **Flutter SDK** (Version 3.x or higher)
* **Android Studio** or **VS Code** (with Flutter & Dart extensions)
* **Android SDK** (for building the APK)

---

## 🚀 Installation & Setup

### Part 1: Setting up ESP32
1. Open `SmartBeehive.ino` in Arduino IDE.
2. Connect your ESP32 board.
3. Update the WiFi credentials in the code:
   ```cpp
   char ssid[] = "Your_WiFi_Name";
   char pass[] = "Your_WiFi_Password";
   ```
4. Select your board (e.g., **DOIT ESP32 DEVKIT V1**) and Port.
5. Click **Upload**.
6. Open Serial Monitor (115200 baud) to see the **IP Address** of your ESP32.

### Part 2: Setting up Flutter App
1. Open your terminal/command prompt.
2. Navigate to the `beehive-main` folder:
   ```bash
   cd beehive-main
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Connect your Android phone (with USB Debugging ON) or start an emulator.
5. Run the app:
   ```bash
   flutter run
   ```

---

## 📲 How to Connect
1. Ensure your phone and ESP32 are on the **same WiFi network**.
2. Open the app on your phone.
3. Go to **Settings** (Gear icon).
4. Enter the **IP Address** you saw in the Arduino Serial Monitor (e.g., `192.168.1.15`).
5. Save the connection. The dashboard will now show live data!

---

## 📡 Features
* **Live Dashboard**: Real-time Temperature, Humidity, Sound, and Light data.
* **Smart Alerts**: Get notified if someone opens the box (Light Detect) or if there is high vibration/noise.
* **Mute Toggle**: Physical button support to silence the buzzer.
* **Auto-Reconnect**: ESP32 automatically reconnects to WiFi if the connection drops.

---

## 👨‍💻 Developed By
* **Tayyaba Anwar**
* **Hina Tahir**
