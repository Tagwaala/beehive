# Beehive Monitoring System - Mobile App

A professional Flutter mobile application for real-time monitoring of beehive telemetry data (temperature, humidity, sound, vibration, and light levels). The app interfaces directly with an ESP32-based local web server, replacing the need for third-party platforms like Blynk.

## Features
- Real-time fetching of sensor data from the ESP32 Local Server.
- IP Address Configuration Screen with persistent storage.
- Professional dashboard with custom card layouts for metrics.
- Seamless network connectivity.

## 🚀 Installation & Setup Guide

This guide will walk you through the process of setting up the Beehive Monitoring app on your local machine.

### 1. Prerequisites

Before you begin, ensure you have the following installed on your system:

- **Flutter SDK**: [Download & Install Flutter](https://docs.flutter.dev/get-started/install). Ensure Flutter is added to your system's PATH.
- **Android Studio** or **VS Code**: Recommended IDEs for Flutter development.
  - Install the **Flutter** and **Dart** extensions/plugins in your chosen IDE.
- **Git**: [Download Git](https://git-scm.com/downloads) to clone the repository.

### 2. Verify Prerequisites

Open your terminal or command prompt and run the following command to check if Flutter is installed correctly:
```bash
flutter doctor
```
Ensure there are no critical errors (like missing Android SDK or toolchain).

### 3. Clone the Repository

Clone the project from GitHub using the following command:
```bash
git clone https://github.com/Tagwaala/beehive.git
```

Navigate into the project directory:
```bash
cd beehive
```

### 4. Install Dependencies

Fetch all the required Dart packages (like `http` and `shared_preferences`) by running:
```bash
flutter pub get
```

### 5. Running the Application

You can run the application on an emulator or a physical Android device.

**Option A: Running on an Emulator**
1. Open Android Studio and launch an Android Virtual Device (AVD) from the Device Manager.
2. Once the emulator is running, execute the following command in your terminal:
   ```bash
   flutter run
   ```

**Option B: Running on a Physical Device**
1. Enable **Developer Options** and **USB Debugging** on your Android device.
2. Connect your device to your computer via USB.
3. Ensure your device is recognized by running:
   ```bash
   flutter devices
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### 6. App Usage Instructions
1. Ensure your ESP32 is powered on and connected to your local Wi-Fi network.
2. Connect your mobile phone to the **same local Wi-Fi network**.
3. When you launch the app, enter the **IP Address** of your ESP32 in the configuration screen.
4. The app will securely save this IP for future sessions and open the Dashboard.
5. Monitor real-time telemetry data smoothly!

## Built With
* [Flutter](https://flutter.dev/) - UI Toolkit
* [Dart](https://dart.dev/) - Programming Language
