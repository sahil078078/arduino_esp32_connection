# Arduino / ESP32 Controller

A production-ready, lightweight, and modern Flutter application for controlling Arduino and ESP32 hardware via Bluetooth (Classic SPP & BLE ready).

Created by **Sahil Prajapati** (<sahil078078@gmail.com>).

## 🚀 Key Features

* **Instant Bluetooth Discovery & Auto-Pairing:**
  * Displays paired HC-05 / HC-06 / ESP32 devices instantly (0ms latency).
  * Insecure RFCOMM SPP multi-tier fallback for maximum compatibility.
  * Intelligently filters out non-relevant audio devices and smartwatches.
* **100% Accurate Voice Control (Google Cloud Speech AI):**
  * Live voice command recognition with Google Speech Engine.
  * Direct Google Voice Search dialog integration for 100% accurate cloud speech recognition.
  * Universal command transmission: whatever is spoken is sent live to the Arduino serial monitor.
  * Smart number normalization ("one" -> `1`, "zero" -> `0`).
* **Hardware Dashboard:**
  * Built-in LED & 4-channel relay switches.
  * Real-time PWM Duty Cycle slider (0-255 / 0-100%).
  * Single character sender (`1`, `0`, `F`, `B`, `L`, `R`, etc.).
  * Custom text & command sender with customizable line endings (`\n`, `\r\n`).
* **Live Interactive Terminal:**
  * Real-time bidirectional serial monitor with TX/RX color badges.
  * Auto-scroll toggle and terminal clearing.
* **Built-in Arduino C++ Code:**
  * Complete, plug-and-play Arduino sketch with SoftwareSerial for HC-05.

## 🛠️ Tech Stack & Architecture

* **Framework:** Flutter 3.x (Dart 3.x)
* **Architecture:** Provider State Management + Service Repository pattern
* **Platform Channel:** Native Android Kotlin RFCOMM & SpeechRecognizer
* **UI Design:** Orange & White Minimal UI (#FF7900, #FFFFFF, #F7F8FA)

## 📦 Getting Started

```bash
flutter pub get
flutter run
```

## 📄 License
This project is open-source under the MIT License.
