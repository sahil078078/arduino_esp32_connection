import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/board_model.dart';
import '../providers/bluetooth_provider.dart';
import '../src/helper/app_toasting.dart';
import '../theme/app_colors.dart';

enum CodeTab {
  arduinoUno,
  esp32DevKitV1,
  esp32S3,
  esp32Wifi,
}

class ArduinoCodeScreen extends StatefulWidget {
  const ArduinoCodeScreen({super.key});

  @override
  State<ArduinoCodeScreen> createState() => _ArduinoCodeScreenState();
}

class _ArduinoCodeScreenState extends State<ArduinoCodeScreen> {
  CodeTab _selectedTab = CodeTab.esp32DevKitV1;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final bt = Provider.of<BluetoothProvider>(context, listen: false);
      if (bt.connectionMedium == ConnectionMedium.wifi) {
        _selectedTab = CodeTab.esp32Wifi;
      } else {
        switch (bt.selectedBoard.type) {
          case BoardType.arduinoUno:
            _selectedTab = CodeTab.arduinoUno;
            break;
          case BoardType.esp32DevKitV1:
            _selectedTab = CodeTab.esp32DevKitV1;
            break;
          case BoardType.esp32S3:
            _selectedTab = CodeTab.esp32S3;
            break;
        }
      }
      _initialized = true;
    }
  }

  // 1. Arduino Uno / Nano + HC-05 Bluetooth Sketch
  static const String _arduinoUnoSketch = '''// ========================================================
// Arduino Uno / Nano Bluetooth Controller Sketch
// Hardware: Arduino Uno + HC-05 / HC-06 Bluetooth Module
// Wiring: HC-05 TX -> Pin 2 (RX) | HC-05 RX -> Pin 3 (TX)
// Features: Relays, Built-in LED, PWM, ADC & 4-Pin Non-Addressable RGB LED
// ========================================================

#include <SoftwareSerial.h>

// SoftwareSerial BT (RX Pin, TX Pin)
SoftwareSerial BT(2, 3);

// Configurable Pins
const int builtinLed = 13;
const int relay1 = 7;
const int relay2 = 8;
const int relay3 = 4;
const int relay4 = 12;
const int pwmPin = 9;

// 4-Pin Non-Addressable RGB LED Pins (PWM capable pins)
// Common Cathode: Common leg to GND (Normal PWM: 0=OFF, 255=Full)
// Common Anode: Common leg to 5V (Inverted PWM: 255=OFF, 0=Full)
const int rgbRedPin   = 9;
const int rgbGreenPin = 10;
const int rgbBluePin  = 11;

void setup() {
  pinMode(builtinLed, OUTPUT);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  pinMode(relay4, OUTPUT);
  pinMode(pwmPin, OUTPUT);

  pinMode(rgbRedPin, OUTPUT);
  pinMode(rgbGreenPin, OUTPUT);
  pinMode(rgbBluePin, OUTPUT);

  digitalWrite(builtinLed, LOW);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  digitalWrite(relay3, LOW);
  digitalWrite(relay4, LOW);

  // Default RGB OFF
  analogWrite(rgbRedPin, 0);
  analogWrite(rgbGreenPin, 0);
  analogWrite(rgbBluePin, 0);

  Serial.begin(9600);
  BT.begin(9600); // Standard HC-05 Baud Rate

  Serial.println("==========================================");
  Serial.println("Arduino Uno Ready for Bluetooth Commands!");
  Serial.println("RGB 4-Pin Module Pins: R=9, G=10, B=11");
  Serial.println("==========================================");
  BT.println("CONNECTED: Arduino Uno Ready");
}

void loop() {
  if (BT.available()) {
    String msg = BT.readStringUntil('\\n');
    msg.trim();

    if (msg.length() > 0) {
      Serial.print("[BT IN] ");
      Serial.println(msg);

      String lower = msg;
      lower.toLowerCase();

      // 1. Built-in LED ("1", "one", "on" / "0", "zero", "off")
      if (lower == "1" || lower == "one" || lower == "on" || lower == "ledon" || msg.startsWith("LED:13:1")) {
        digitalWrite(builtinLed, HIGH);
        Serial.println("-> Action: LED 13 Turned ON");
        BT.println("ACK: LED 13 ON");
      }
      else if (lower == "0" || lower == "zero" || lower == "off" || lower == "ledoff" || msg.startsWith("LED:13:0")) {
        digitalWrite(builtinLed, LOW);
        Serial.println("-> Action: LED 13 Turned OFF");
        BT.println("ACK: LED 13 OFF");
      }

      // 2. 4-Channel Relays
      else if (msg == "A" || msg == "R1:1" || msg.startsWith("RELAY:7:1")) {
        digitalWrite(relay1, HIGH);
        BT.println("ACK: Relay 1 ON");
      }
      else if (msg == "a" || msg == "R1:0" || msg.startsWith("RELAY:7:0")) {
        digitalWrite(relay1, LOW);
        BT.println("ACK: Relay 1 OFF");
      }
      else if (msg == "B" || msg == "R2:1" || msg.startsWith("RELAY:8:1")) {
        digitalWrite(relay2, HIGH);
        BT.println("ACK: Relay 2 ON");
      }
      else if (msg == "b" || msg == "R2:0" || msg.startsWith("RELAY:8:0")) {
        digitalWrite(relay2, LOW);
        BT.println("ACK: Relay 2 OFF");
      }
      else if (msg == "C" || msg == "R3:1" || msg.startsWith("RELAY:4:1")) {
        digitalWrite(relay3, HIGH);
        BT.println("ACK: Relay 3 ON");
      }
      else if (msg == "c" || msg == "R3:0" || msg.startsWith("RELAY:4:0")) {
        digitalWrite(relay3, LOW);
        BT.println("ACK: Relay 3 OFF");
      }
      else if (msg == "D" || msg == "R4:1" || msg.startsWith("RELAY:12:1")) {
        digitalWrite(relay4, HIGH);
        BT.println("ACK: Relay 4 ON");
      }
      else if (msg == "d" || msg == "R4:0" || msg.startsWith("RELAY:12:0")) {
        digitalWrite(relay4, LOW);
        BT.println("ACK: Relay 4 OFF");
      }

      // 3. All On / All Off
      else if (lower == "all on" || lower == "allon" || msg == "ALL_ON") {
        digitalWrite(builtinLed, HIGH);
        digitalWrite(relay1, HIGH);
        digitalWrite(relay2, HIGH);
        digitalWrite(relay3, HIGH);
        digitalWrite(relay4, HIGH);
        BT.println("ACK: ALL ON");
      }
      else if (lower == "all off" || lower == "alloff" || msg == "ALL_OFF") {
        digitalWrite(builtinLed, LOW);
        digitalWrite(relay1, LOW);
        digitalWrite(relay2, LOW);
        digitalWrite(relay3, LOW);
        digitalWrite(relay4, LOW);
        analogWrite(rgbRedPin, 0);
        analogWrite(rgbGreenPin, 0);
        analogWrite(rgbBluePin, 0);
        BT.println("ACK: ALL OFF");
      }

      // 4. Non-Addressable 4-Pin RGB LED ("RGB:255:128:0")
      else if (msg.startsWith("RGB:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        int thirdColon = msg.indexOf(':', secondColon + 1);
        if (firstColon > 0 && secondColon > 0) {
          int r = msg.substring(firstColon + 1, secondColon).toInt();
          int g = (thirdColon > 0) ? msg.substring(secondColon + 1, thirdColon).toInt() : 0;
          int b = (thirdColon > 0) ? msg.substring(thirdColon + 1).toInt() : 0;
          analogWrite(rgbRedPin, r);
          analogWrite(rgbGreenPin, g);
          analogWrite(rgbBluePin, b);
          Serial.print("-> RGB Set: R="); Serial.print(r);
          Serial.print(" G="); Serial.print(g);
          Serial.print(" B="); Serial.println(b);
          BT.println("ACK: RGB SET");
        }
      }

      // 5. PWM Duty Cycle ("PWM:9:180")
      else if (msg.startsWith("PWM:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        if (firstColon > 0 && secondColon > 0) {
          int pin = msg.substring(firstColon + 1, secondColon).toInt();
          int val = msg.substring(secondColon + 1).toInt();
          analogWrite(pin, val);
          Serial.print("-> PWM Pin ");
          Serial.print(pin);
          Serial.print(" set to ");
          Serial.println(val);
          BT.println("ACK: PWM SET");
        }
      }

      // 6. ADC Read ("READ:ADC:14")
      else if (msg.startsWith("READ:ADC:")) {
        int pin = msg.substring(9).toInt();
        int val = analogRead(pin);
        Serial.print("-> ADC Pin ");
        Serial.print(pin);
        Serial.print(" Value: ");
        Serial.println(val);
        BT.print("ADC:");
        BT.print(pin);
        BT.print(":");
        BT.println(val);
      }

      // 7. Custom Voice / Text
      else {
        Serial.print("-> Custom Text: ");
        Serial.println(msg);
        BT.print("RECEIVED: ");
        BT.println(msg);
      }
    }
  }
}''';

  // 2. ESP32 DevKit V1 Classic Bluetooth Sketch
  static const String _esp32DevKitV1Sketch = '''// ========================================================
// ESP32 DevKit V1 Bluetooth Controller Sketch
// Hardware: ESP32 DevKit V1 (ESP-WROOM-32)
// Uses NATIVE ON-CHIP Classic Bluetooth (BluetoothSerial.h)
// Features: Relays, Built-in LED, True DAC, Touch, ADC & 4-Pin RGB LED
// ========================================================

#include "BluetoothSerial.h"

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to enable it
#endif

BluetoothSerial SerialBT;

// Configurable GPIO Pins (ESP32 DevKit V1)
const int builtinLed = 2;   // Blue On-board LED on GPIO 2
const int relay1 = 18;      // Relay 1 GPIO 18
const int relay2 = 19;      // Relay 2 GPIO 19
const int relay3 = 21;      // Relay 3 GPIO 21
const int relay4 = 22;      // Relay 4 GPIO 22

// Primary PWM Configuration (LEDC Channel 0)
const int pwmPin = 16;      // Primary PWM GPIO 16
const int pwmChannel = 0;   // LEDC Channel 0
const int pwmFreq = 5000;   // 5 kHz Frequency
const int pwmResolution = 8;// 8-bit resolution (0 - 255)

// 4-Pin Non-Addressable RGB LED Pins & Channels
// Leg 1: Red -> GPIO 4   (LEDC Channel 1)
// Leg 2: Common -> GND (Common Cathode) or 3.3V (Common Anode)
// Leg 3: Green -> GPIO 5 (LEDC Channel 2)
// Leg 4: Blue -> GPIO 17 (LEDC Channel 3)
const int rgbRedPin   = 4;
const int rgbGreenPin = 5;
const int rgbBluePin  = 17;
const int chR = 1;
const int chG = 2;
const int chB = 3;

void setup() {
  Serial.begin(115200);

  // Setup GPIO Output Pins
  pinMode(builtinLed, OUTPUT);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  pinMode(relay4, OUTPUT);

  digitalWrite(builtinLed, LOW);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  digitalWrite(relay3, LOW);
  digitalWrite(relay4, LOW);

  // Setup Primary Hardware PWM (LEDC Channel 0)
  ledcSetup(pwmChannel, pwmFreq, pwmResolution);
  ledcAttachPin(pwmPin, pwmChannel);

  // Setup 4-Pin RGB LED Hardware PWM Channels (1, 2, 3)
  ledcSetup(chR, pwmFreq, pwmResolution);
  ledcAttachPin(rgbRedPin, chR);
  ledcSetup(chG, pwmFreq, pwmResolution);
  ledcAttachPin(rgbGreenPin, chG);
  ledcSetup(chB, pwmFreq, pwmResolution);
  ledcAttachPin(rgbBluePin, chB);

  ledcWrite(chR, 0);
  ledcWrite(chG, 0);
  ledcWrite(chB, 0);

  // Start On-Chip Bluetooth Serial with Device Name
  SerialBT.begin("ESP32-Bluetooth-Hub"); 

  Serial.println("==========================================");
  Serial.println("ESP32 DevKit V1 Ready!");
  Serial.println("Bluetooth Name: 'ESP32-Bluetooth-Hub'");
  Serial.println("RGB 4-Pin Pins: R=GPIO 4, G=GPIO 5, B=GPIO 17");
  Serial.println("True 8-bit DAC on GPIO 25 & 26 Enabled");
  Serial.println("==========================================");
}

void loop() {
  if (SerialBT.available()) {
    String msg = SerialBT.readStringUntil('\\n');
    msg.trim();

    if (msg.length() > 0) {
      Serial.print("[ESP32 BT IN] ");
      Serial.println(msg);

      String lower = msg;
      lower.toLowerCase();

      // 1. Built-in LED on GPIO 2
      if (lower == "1" || lower == "one" || lower == "on" || lower == "ledon" || msg.startsWith("LED:2:1")) {
        digitalWrite(builtinLed, HIGH);
        Serial.println("-> Action: ESP32 LED GPIO 2 ON");
        SerialBT.println("ACK: LED GPIO 2 ON");
      }
      else if (lower == "0" || lower == "zero" || lower == "off" || lower == "ledoff" || msg.startsWith("LED:2:0")) {
        digitalWrite(builtinLed, LOW);
        Serial.println("-> Action: ESP32 LED GPIO 2 OFF");
        SerialBT.println("ACK: LED GPIO 2 OFF");
      }

      // 2. 4-Channel Relays (GPIO 18, 19, 21, 22)
      else if (msg == "A" || msg == "R1:1" || msg.startsWith("RELAY:18:1")) {
        digitalWrite(relay1, HIGH);
        SerialBT.println("ACK: Relay 1 (GPIO 18) ON");
      }
      else if (msg == "a" || msg == "R1:0" || msg.startsWith("RELAY:18:0")) {
        digitalWrite(relay1, LOW);
        SerialBT.println("ACK: Relay 1 (GPIO 18) OFF");
      }
      else if (msg == "B" || msg == "R2:1" || msg.startsWith("RELAY:19:1")) {
        digitalWrite(relay2, HIGH);
        SerialBT.println("ACK: Relay 2 (GPIO 19) ON");
      }
      else if (msg == "b" || msg == "R2:0" || msg.startsWith("RELAY:19:0")) {
        digitalWrite(relay2, LOW);
        SerialBT.println("ACK: Relay 2 (GPIO 19) OFF");
      }
      else if (msg == "C" || msg == "R3:1" || msg.startsWith("RELAY:21:1")) {
        digitalWrite(relay3, HIGH);
        SerialBT.println("ACK: Relay 3 (GPIO 21) ON");
      }
      else if (msg == "c" || msg == "R3:0" || msg.startsWith("RELAY:21:0")) {
        digitalWrite(relay3, LOW);
        SerialBT.println("ACK: Relay 3 (GPIO 21) OFF");
      }
      else if (msg == "D" || msg == "R4:1" || msg.startsWith("RELAY:22:1")) {
        digitalWrite(relay4, HIGH);
        SerialBT.println("ACK: Relay 4 (GPIO 22) ON");
      }
      else if (msg == "d" || msg == "R4:0" || msg.startsWith("RELAY:22:0")) {
        digitalWrite(relay4, LOW);
        SerialBT.println("ACK: Relay 4 (GPIO 22) OFF");
      }

      // 3. All On / All Off
      else if (lower == "all on" || lower == "allon" || msg == "ALL_ON") {
        digitalWrite(builtinLed, HIGH);
        digitalWrite(relay1, HIGH);
        digitalWrite(relay2, HIGH);
        digitalWrite(relay3, HIGH);
        digitalWrite(relay4, HIGH);
        SerialBT.println("ACK: ALL PINS ON");
      }
      else if (lower == "all off" || lower == "alloff" || msg == "ALL_OFF") {
        digitalWrite(builtinLed, LOW);
        digitalWrite(relay1, LOW);
        digitalWrite(relay2, LOW);
        digitalWrite(relay3, LOW);
        digitalWrite(relay4, LOW);
        ledcWrite(chR, 0);
        ledcWrite(chG, 0);
        ledcWrite(chB, 0);
        SerialBT.println("ACK: ALL PINS OFF");
      }

      // 4. Non-Addressable 4-Pin RGB LED ("RGB:255:128:0")
      else if (msg.startsWith("RGB:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        int thirdColon = msg.indexOf(':', secondColon + 1);
        if (firstColon > 0 && secondColon > 0) {
          int r = msg.substring(firstColon + 1, secondColon).toInt();
          int g = (thirdColon > 0) ? msg.substring(secondColon + 1, thirdColon).toInt() : 0;
          int b = (thirdColon > 0) ? msg.substring(thirdColon + 1).toInt() : 0;
          ledcWrite(chR, r);
          ledcWrite(chG, g);
          ledcWrite(chB, b);
          Serial.printf("-> RGB Color: R=%d, G=%d, B=%d\\n", r, g, b);
          SerialBT.println("ACK: RGB SET");
        }
      }

      // 5. True 8-bit DAC Output (GPIO 25 & 26) ("DAC:25:200")
      else if (msg.startsWith("DAC:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        if (firstColon > 0 && secondColon > 0) {
          int pin = msg.substring(firstColon + 1, secondColon).toInt();
          int val = msg.substring(secondColon + 1).toInt();
          if (pin == 25 || pin == 26) {
            dacWrite(pin, val); // True analog output (0 - 3.3V)
            Serial.printf("-> True DAC Pin %d set to %d (%.2f V)\\n", pin, val, (val / 255.0) * 3.3);
            SerialBT.printf("ACK: DAC%d SET\\n", pin);
          }
        }
      }

      // 6. LEDC Hardware PWM ("PWM:16:180")
      else if (msg.startsWith("PWM:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        if (firstColon > 0 && secondColon > 0) {
          int pin = msg.substring(firstColon + 1, secondColon).toInt();
          int val = msg.substring(secondColon + 1).toInt();
          ledcWrite(pwmChannel, val);
          Serial.printf("-> LEDC PWM Pin %d set to %d\\n", pin, val);
          SerialBT.println("ACK: PWM SET");
        }
      }

      // 7. Capacitive Touch Sensor Read ("READ:TOUCH:4")
      else if (msg.startsWith("READ:TOUCH:")) {
        int pin = msg.substring(11).toInt();
        int touchVal = touchRead(pin); // ESP32 capacitive touch (0 - 100)
        Serial.printf("-> Touch Sensor Pin %d Value: %d\\n", pin, touchVal);
        SerialBT.printf("TOUCH:%d:%d\\n", pin, touchVal);
      }

      // 8. 12-bit ADC Read (GPIO 32 - 39) ("READ:ADC:34")
      else if (msg.startsWith("READ:ADC:")) {
        int pin = msg.substring(9).toInt();
        int adcVal = analogRead(pin); // 12-bit: 0 to 4095
        Serial.printf("-> ADC Pin %d Value: %d (%.2f V)\\n", pin, adcVal, (adcVal / 4095.0) * 3.3);
        SerialBT.printf("ADC:%d:%d\\n", pin, adcVal);
      }

      // 9. Custom Voice Command / Raw String
      else {
        Serial.print("-> Custom Text: ");
        Serial.println(msg);
        SerialBT.print("RECEIVED: ");
        SerialBT.println(msg);
      }
    }
  }
}''';

  // 3. ESP32-S3 DevKitC-1 Serial / Bluetooth Sketch
  static const String _esp32S3Sketch = '''// ========================================================
// ESP32-S3 DevKitC-1 Controller Sketch
// Hardware: ESP32-S3 (Xtensa Dual-Core LX7)
// Features: Built-in WS2812 RGB LED (GPIO 48) & External 4-Pin RGB LED,
//           14 Touch Pins, 20 ADC Channels, Relays, PWM
// ========================================================

#include <Arduino.h>

// ESP32-S3 GPIO Pins
const int builtinLedPin = 48; // WS2812 RGB Onboard on DevKitC-1
const int relay1 = 4;
const int relay2 = 5;
const int relay3 = 6;
const int relay4 = 7;
const int pwmPin = 18;

// External 4-Pin Non-Addressable RGB LED Pins (PWM capable)
const int extRgbRed   = 15;
const int extRgbGreen = 16;
const int extRgbBlue  = 17;

const int pwmFreq = 5000;
const int pwmRes  = 8;

void setup() {
  Serial.begin(115200);

  pinMode(builtinLedPin, OUTPUT);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  pinMode(relay4, OUTPUT);

  pinMode(extRgbRed, OUTPUT);
  pinMode(extRgbGreen, OUTPUT);
  pinMode(extRgbBlue, OUTPUT);

  digitalWrite(builtinLedPin, LOW);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  digitalWrite(relay3, LOW);
  digitalWrite(relay4, LOW);

  // Setup ESP32-S3 LEDC PWM
  ledcAttach(pwmPin, pwmFreq, pwmRes);
  ledcAttach(extRgbRed, pwmFreq, pwmRes);
  ledcAttach(extRgbGreen, pwmFreq, pwmRes);
  ledcAttach(extRgbBlue, pwmFreq, pwmRes);

  ledcWrite(extRgbRed, 0);
  ledcWrite(extRgbGreen, 0);
  ledcWrite(extRgbBlue, 0);

  Serial.println("==========================================");
  Serial.println("ESP32-S3 DevKitC-1 Ready!");
  Serial.println("On-board RGB LED: GPIO 48");
  Serial.println("External RGB LED: R=GPIO 15, G=GPIO 16, B=GPIO 17");
  Serial.println("14 Capacitive Touch Pins (GPIO 1 to 14)");
  Serial.println("==========================================");
}

void loop() {
  if (Serial.available()) {
    String msg = Serial.readStringUntil('\\n');
    msg.trim();

    if (msg.length() > 0) {
      Serial.print("[ESP32-S3 IN] ");
      Serial.println(msg);

      String lower = msg;
      lower.toLowerCase();

      // 1. Built-in LED (GPIO 48)
      if (lower == "1" || lower == "one" || lower == "on" || lower == "ledon" || msg.startsWith("LED:48:1")) {
        digitalWrite(builtinLedPin, HIGH);
        Serial.println("ACK: ESP32-S3 LED ON");
      }
      else if (lower == "0" || lower == "zero" || lower == "off" || lower == "ledoff" || msg.startsWith("LED:48:0")) {
        digitalWrite(builtinLedPin, LOW);
        Serial.println("ACK: ESP32-S3 LED OFF");
      }

      // 2. Relays (GPIO 4, 5, 6, 7)
      else if (msg == "A" || msg == "R1:1" || msg.startsWith("RELAY:4:1")) {
        digitalWrite(relay1, HIGH);
        Serial.println("ACK: Relay 1 (GPIO 4) ON");
      }
      else if (msg == "a" || msg == "R1:0" || msg.startsWith("RELAY:4:0")) {
        digitalWrite(relay1, LOW);
        Serial.println("ACK: Relay 1 (GPIO 4) OFF");
      }
      else if (msg == "B" || msg == "R2:1" || msg.startsWith("RELAY:5:1")) {
        digitalWrite(relay2, HIGH);
        Serial.println("ACK: Relay 2 (GPIO 5) ON");
      }
      else if (msg == "b" || msg == "R2:0" || msg.startsWith("RELAY:5:0")) {
        digitalWrite(relay2, LOW);
        Serial.println("ACK: Relay 2 (GPIO 5) OFF");
      }
      else if (msg == "C" || msg == "R3:1" || msg.startsWith("RELAY:6:1")) {
        digitalWrite(relay3, HIGH);
        Serial.println("ACK: Relay 3 (GPIO 6) ON");
      }
      else if (msg == "c" || msg == "R3:0" || msg.startsWith("RELAY:6:0")) {
        digitalWrite(relay3, LOW);
        Serial.println("ACK: Relay 3 (GPIO 6) OFF");
      }
      else if (msg == "D" || msg == "R4:1" || msg.startsWith("RELAY:7:1")) {
        digitalWrite(relay4, HIGH);
        Serial.println("ACK: Relay 4 (GPIO 7) ON");
      }
      else if (msg == "d" || msg == "R4:0" || msg.startsWith("RELAY:7:0")) {
        digitalWrite(relay4, LOW);
        Serial.println("ACK: Relay 4 (GPIO 7) OFF");
      }

      // 3. RGB LED Control ("RGB:255:0:255")
      else if (msg.startsWith("RGB:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        int thirdColon = msg.indexOf(':', secondColon + 1);
        if (firstColon > 0 && secondColon > 0) {
          int r = msg.substring(firstColon + 1, secondColon).toInt();
          int g = (thirdColon > 0) ? msg.substring(secondColon + 1, thirdColon).toInt() : 0;
          int b = (thirdColon > 0) ? msg.substring(thirdColon + 1).toInt() : 0;

          // A. Drive On-board WS2812 RGB LED (GPIO 48)
          #ifdef RGB_BUILTIN
          rgbLedWrite(RGB_BUILTIN, r, g, b);
          #else
          neopixelWrite(builtinLedPin, r, g, b);
          #endif

          // B. Drive External 4-Pin RGB LED (GPIO 15, 16, 17)
          ledcWrite(extRgbRed, r);
          ledcWrite(extRgbGreen, g);
          ledcWrite(extRgbBlue, b);

          Serial.printf("ACK: RGB Set to R=%d G=%d B=%d\\n", r, g, b);
        }
      }

      // 4. LEDC PWM ("PWM:18:200")
      else if (msg.startsWith("PWM:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        if (firstColon > 0 && secondColon > 0) {
          int val = msg.substring(secondColon + 1).toInt();
          ledcWrite(pwmPin, val);
          Serial.printf("ACK: PWM %d\\n", val);
        }
      }

      // 5. Capacitive Touch (14 channels on S3: GPIO 1 - 14)
      else if (msg.startsWith("READ:TOUCH:")) {
        int pin = msg.substring(11).toInt();
        int touchVal = touchRead(pin);
        Serial.printf("TOUCH:%d:%d\\n", pin, touchVal);
      }

      // 6. 12-bit ADC Read (20 channels)
      else if (msg.startsWith("READ:ADC:")) {
        int pin = msg.substring(9).toInt();
        int adcVal = analogRead(pin);
        Serial.printf("ADC:%d:%d\\n", pin, adcVal);
      }

      // 7. Custom Voice / Text
      else {
        Serial.print("RECEIVED: ");
        Serial.println(msg);
      }
    }
  }
}''';

  // 4. ESP32 WiFi Controller Sketch (SoftAP + WebServer + Socket)
  static const String _esp32WifiSketch = '''// ========================================================
// ESP32 WiFi Controller Sketch (HTTP WebServer + SoftAP)
// Hardware: ESP32 DevKit V1 / ESP32-S3 / Any ESP32 Board
// Modes Supported:
//   1. SoftAP (ESP32 creates its own hotspot: 'ESP32_Controller_AP')
//      Default IP: 192.168.4.1 (Connect directly to this WiFi from Phone!)
//   2. Station Mode (Optional: Connects to your Home/Office WiFi Router)
// Features: Relays, Built-in LED, 4-Pin Non-Addressable RGB LED, PWM, ADC
// ========================================================

#include <WiFi.h>
#include <WebServer.h>

// ---------------------------------------------
// WiFi Credentials Configuration
// ---------------------------------------------
// 1. SoftAP Hotspot Settings (ESP32 acts as Access Point)
const char* apSSID     = "ESP32_Controller_AP";
const char* apPassword = "password123"; // Min 8 characters

// 2. Station Mode (Optional: connect to your home router)
// Set useStationMode = true and enter your router credentials
const bool  useStationMode = false; 
const char* staSSID        = "YOUR_ROUTER_SSID";
const char* staPassword    = "YOUR_ROUTER_PASSWORD";

// WebServer on standard HTTP Port 80
WebServer server(80);

// Configurable GPIO Output Pins
const int builtinLed = 2;   // Blue Onboard LED on GPIO 2 (or 48 for S3)
const int relay1 = 18;      // Relay 1 GPIO 18
const int relay2 = 19;      // Relay 2 GPIO 19
const int relay3 = 21;      // Relay 3 GPIO 21
const int relay4 = 22;      // Relay 4 GPIO 22

// PWM Configuration (Primary Motor / Dimmer PWM)
const int pwmPin = 16;      // Primary PWM GPIO 16
const int pwmChannel = 0;
const int pwmFreq = 5000;
const int pwmRes  = 8;

// 4-Pin Non-Addressable RGB LED Pins & Channels
// Leg 1: Red -> GPIO 4   (LEDC Channel 1)
// Leg 2: Common -> GND (Cathode) or 3.3V (Anode)
// Leg 3: Green -> GPIO 5 (LEDC Channel 2)
// Leg 4: Blue -> GPIO 17 (LEDC Channel 3)
const int rgbRedPin   = 4;
const int rgbGreenPin = 5;
const int rgbBluePin  = 17;
const int chR = 1;
const int chG = 2;
const int chB = 3;

// Helper to add CORS headers so Flutter HTTP works smoothly
void sendCorsHeader() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "*");
}

// ---------------------------------------------
// HTTP Route Handlers
// ---------------------------------------------

// Root Status Page
void handleRoot() {
  sendCorsHeader();
  String html = "<html><head><title>ESP32 WiFi Controller</title></head>";
  html += "<body style='font-family:sans-serif;text-align:center;padding:30px;'>";
  html += "<h2>ESP32 WiFi Controller Hub</h2>";
  html += "<p>IP: " + WiFi.softAPIP().toString() + "</p>";
  html += "<p>Status: Ready for HTTP REST Commands</p>";
  html += "<p>Endpoints: /ping, /cmd?c=..., /text?t=..., /rgb?r=..&g=..&b=.., /pwm?pin=..&val=..</p>";
  html += "</body></html>";
  server.send(200, "text/html", html);
}

// Ping Endpoint (Tested by Flutter app for latency)
void handlePing() {
  sendCorsHeader();
  String json = "{\\"status\\":\\"ok\\",\\"board\\":\\"ESP32 WiFi\\",\\"uptime\\":" + String(millis()) + "}";
  server.send(200, "application/json", json);
}

// Single Character Command (/cmd?c=1 or /cmd?c=A)
void handleCmd() {
  sendCorsHeader();
  if (server.hasArg("c")) {
    String c = server.arg("c");
    c.trim();

    // 1. Built-in LED
    if (c == "1") {
      digitalWrite(builtinLed, HIGH);
      server.send(200, "text/plain", "ACK: LED ON");
      return;
    } else if (c == "0") {
      digitalWrite(builtinLed, LOW);
      server.send(200, "text/plain", "ACK: LED OFF");
      return;
    }

    // 2. Relays
    else if (c == "A") { digitalWrite(relay1, HIGH); server.send(200, "text/plain", "ACK: Relay 1 ON"); return; }
    else if (c == "a") { digitalWrite(relay1, LOW);  server.send(200, "text/plain", "ACK: Relay 1 OFF"); return; }
    else if (c == "B") { digitalWrite(relay2, HIGH); server.send(200, "text/plain", "ACK: Relay 2 ON"); return; }
    else if (c == "b") { digitalWrite(relay2, LOW);  server.send(200, "text/plain", "ACK: Relay 2 OFF"); return; }
    else if (c == "C") { digitalWrite(relay3, HIGH); server.send(200, "text/plain", "ACK: Relay 3 ON"); return; }
    else if (c == "c") { digitalWrite(relay3, LOW);  server.send(200, "text/plain", "ACK: Relay 3 OFF"); return; }
    else if (c == "D") { digitalWrite(relay4, HIGH); server.send(200, "text/plain", "ACK: Relay 4 ON"); return; }
    else if (c == "d") { digitalWrite(relay4, LOW);  server.send(200, "text/plain", "ACK: Relay 4 OFF"); return; }
  }
  server.send(400, "text/plain", "ERR: Missing or unknown param 'c'");
}

// Custom String / Voice Command (/text?t=ALL_ON or /text?t=RGB:255:0:0)
void handleText() {
  sendCorsHeader();
  if (server.hasArg("t")) {
    String t = server.arg("t");
    t.trim();

    // Relays All ON / All OFF
    if (t == "ALL_ON" || t == "all on") {
      digitalWrite(builtinLed, HIGH);
      digitalWrite(relay1, HIGH);
      digitalWrite(relay2, HIGH);
      digitalWrite(relay3, HIGH);
      digitalWrite(relay4, HIGH);
      server.send(200, "text/plain", "ACK: ALL ON");
      return;
    } else if (t == "ALL_OFF" || t == "all off") {
      digitalWrite(builtinLed, LOW);
      digitalWrite(relay1, LOW);
      digitalWrite(relay2, LOW);
      digitalWrite(relay3, LOW);
      digitalWrite(relay4, LOW);
      ledcWrite(chR, 0); ledcWrite(chG, 0); ledcWrite(chB, 0);
      server.send(200, "text/plain", "ACK: ALL OFF");
      return;
    }

    // RGB String Payload: RGB:255:128:0
    else if (t.startsWith("RGB:")) {
      int firstColon = t.indexOf(':');
      int secondColon = t.indexOf(':', firstColon + 1);
      int thirdColon = t.indexOf(':', secondColon + 1);
      if (firstColon > 0 && secondColon > 0) {
        int r = t.substring(firstColon + 1, secondColon).toInt();
        int g = (thirdColon > 0) ? t.substring(secondColon + 1, thirdColon).toInt() : 0;
        int b = (thirdColon > 0) ? t.substring(thirdColon + 1).toInt() : 0;
        ledcWrite(chR, r);
        ledcWrite(chG, g);
        ledcWrite(chB, b);
        server.send(200, "text/plain", "ACK: RGB SET");
        return;
      }
    }

    server.send(200, "text/plain", "ACK: RECEIVED: " + t);
    return;
  }
  server.send(400, "text/plain", "ERR: Missing param 't'");
}

// 4-Pin Non-Addressable RGB Endpoint (/rgb?r=255&g=0&b=128)
void handleRgb() {
  sendCorsHeader();
  int r = server.hasArg("r") ? server.arg("r").toInt() : 0;
  int g = server.hasArg("g") ? server.arg("g").toInt() : 0;
  int b = server.hasArg("b") ? server.arg("b").toInt() : 0;

  ledcWrite(chR, constrain(r, 0, 255));
  ledcWrite(chG, constrain(g, 0, 255));
  ledcWrite(chB, constrain(b, 0, 255));

  Serial.printf("-> WiFi RGB Set: R=%d G=%d B=%d\\n", r, g, b);
  server.send(200, "text/plain", "ACK: RGB SET");
}

// PWM Endpoint (/pwm?pin=16&val=200)
void handlePwm() {
  sendCorsHeader();
  if (server.hasArg("pin") && server.hasArg("val")) {
    int val = server.arg("val").toInt();
    ledcWrite(pwmChannel, constrain(val, 0, 255));
    server.send(200, "text/plain", "ACK: PWM SET");
    return;
  }
  server.send(400, "text/plain", "ERR: Missing pin or val");
}

// True DAC Endpoint (/dac?pin=25&val=180)
void handleDac() {
  sendCorsHeader();
  if (server.hasArg("pin") && server.hasArg("val")) {
    int pin = server.arg("pin").toInt();
    int val = server.arg("val").toInt();
    if (pin == 25 || pin == 26) {
      dacWrite(pin, constrain(val, 0, 255));
      server.send(200, "text/plain", "ACK: DAC SET");
      return;
    }
  }
  server.send(400, "text/plain", "ERR: Valid DAC pins are 25 & 26");
}

// 12-bit ADC Endpoint (/adc?pin=34)
void handleAdc() {
  sendCorsHeader();
  if (server.hasArg("pin")) {
    int pin = server.arg("pin").toInt();
    int val = analogRead(pin);
    server.send(200, "application/json", "{\\"pin\\":" + String(pin) + ",\\"value\\":" + String(val) + "}");
    return;
  }
  server.send(400, "text/plain", "ERR: Missing pin");
}

// Capacitive Touch Endpoint (/touch?pin=4)
void handleTouch() {
  sendCorsHeader();
  if (server.hasArg("pin")) {
    int pin = server.arg("pin").toInt();
    int val = touchRead(pin);
    server.send(200, "application/json", "{\\"pin\\":" + String(pin) + ",\\"touch\\":" + String(val) + "}");
    return;
  }
  server.send(400, "text/plain", "ERR: Missing pin");
}

void setup() {
  Serial.begin(115200);

  // Setup GPIO Output Pins
  pinMode(builtinLed, OUTPUT);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  pinMode(relay4, OUTPUT);

  digitalWrite(builtinLed, LOW);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  digitalWrite(relay3, LOW);
  digitalWrite(relay4, LOW);

  // Setup Primary PWM
  ledcSetup(pwmChannel, pwmFreq, pwmRes);
  ledcAttachPin(pwmPin, pwmChannel);

  // Setup 4-Pin RGB LED PWM Channels
  ledcSetup(chR, pwmFreq, pwmRes);
  ledcAttachPin(rgbRedPin, chR);
  ledcSetup(chG, pwmFreq, pwmRes);
  ledcAttachPin(rgbGreenPin, chG);
  ledcSetup(chB, pwmFreq, pwmRes);
  ledcAttachPin(rgbBluePin, chB);

  ledcWrite(chR, 0); ledcWrite(chG, 0); ledcWrite(chB, 0);

  // 1. Start SoftAP Mode (Hotspot)
  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP(apSSID, apPassword);
  IPAddress apIP = WiFi.softAPIP();

  Serial.println("==========================================");
  Serial.println("ESP32 WiFi Controller Ready!");
  Serial.print("SoftAP Hotspot: "); Serial.println(apSSID);
  Serial.print("SoftAP Password: "); Serial.println(apPassword);
  Serial.print("SoftAP IP Address: "); Serial.println(apIP);
  Serial.println("Connect your phone WiFi to 'ESP32_Controller_AP'");
  Serial.println("==========================================");

  // 2. Optional Station Mode (Home Router)
  if (useStationMode) {
    WiFi.begin(staSSID, staPassword);
    Serial.print("Connecting to Router WiFi");
    int retries = 0;
    while (WiFi.status() != WL_CONNECTED && retries < 20) {
      delay(500);
      Serial.print(".");
      retries++;
    }
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\\nConnected to Router!");
      Serial.print("Station IP: "); Serial.println(WiFi.localIP());
    } else {
      Serial.println("\\nRouter connection timed out. SoftAP is active.");
    }
  }

  // 3. Register WebServer Endpoints
  server.on("/", HTTP_GET, handleRoot);
  server.on("/ping", HTTP_GET, handlePing);
  server.on("/cmd", HTTP_GET, handleCmd);
  server.on("/text", HTTP_GET, handleText);
  server.on("/rgb", HTTP_GET, handleRgb);
  server.on("/pwm", HTTP_GET, handlePwm);
  server.on("/dac", HTTP_GET, handleDac);
  server.on("/adc", HTTP_GET, handleAdc);
  server.on("/touch", HTTP_GET, handleTouch);

  server.begin();
  Serial.println("HTTP WebServer Started on Port 80!");
}

void loop() {
  server.handleClient();
}''';

  String get _currentSketch {
    switch (_selectedTab) {
      case CodeTab.arduinoUno:
        return _arduinoUnoSketch;
      case CodeTab.esp32DevKitV1:
        return _esp32DevKitV1Sketch;
      case CodeTab.esp32S3:
        return _esp32S3Sketch;
      case CodeTab.esp32Wifi:
        return _esp32WifiSketch;
    }
  }

  String get _currentBoardTitle {
    switch (_selectedTab) {
      case CodeTab.arduinoUno:
        return 'Arduino Uno Bluetooth Sketch (.ino)';
      case CodeTab.esp32DevKitV1:
        return 'ESP32 DevKit V1 Bluetooth Sketch (.ino)';
      case CodeTab.esp32S3:
        return 'ESP32-S3 Bluetooth / Serial Sketch (.ino)';
      case CodeTab.esp32Wifi:
        return 'ESP32 WiFi Controller WebServer Sketch (.ino)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.code_rounded, color: AppColors.primaryOrange, size: 22),
            SizedBox(width: 8),
            Text(
              'Microcontroller Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Board Tabs (4 Tabs)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildBoardTab('Arduino', CodeTab.arduinoUno),
                _buildBoardTab('ESP32 BT', CodeTab.esp32DevKitV1),
                _buildBoardTab('ESP32-S3', CodeTab.esp32S3),
                _buildBoardTab('ESP32 WiFi', CodeTab.esp32Wifi),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Board Info & Hardware Connection Guide
          _buildHardwareGuideCard(),

          const SizedBox(height: 16),

          // Code Container with Copy Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _currentBoardTitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentSketch));
                        AppToasting.showSuccessToast(
                            '$_currentBoardTitle copied to clipboard!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy Sketch',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: SelectableText(
                    _currentSketch,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBoardTab(String title, CodeTab type) {
    final isSelected = _selectedTab == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareGuideCard() {
    switch (_selectedTab) {
      case CodeTab.arduinoUno:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cable_rounded, size: 18, color: AppColors.primaryOrange),
                  SizedBox(width: 8),
                  Text(
                    'Arduino Uno + HC-05 & RGB Wiring',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _wiringRow('HC-05 VCC', '->', 'Arduino 5V'),
              _wiringRow('HC-05 GND', '->', 'Arduino GND'),
              _wiringRow('HC-05 TX', '->', 'Arduino Pin 2 (Software RX)'),
              _wiringRow('HC-05 RX', '->', 'Arduino Pin 3 (Software TX) [Via 1k/2k Divider]'),
              _wiringRow('RGB Red', '->', 'Pin 9 (~PWM)'),
              _wiringRow('RGB Common', '->', 'GND (Cathode) or 5V (Anode)'),
              _wiringRow('RGB Green', '->', 'Pin 10 (~PWM)'),
              _wiringRow('RGB Blue', '->', 'Pin 11 (~PWM)'),
            ],
          ),
        );

      case CodeTab.esp32DevKitV1:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bluetooth_connected_rounded, size: 18, color: AppColors.primaryOrange),
                  SizedBox(width: 8),
                  Text(
                    'ESP32 DevKit V1 Hardware Highlights',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _wiringRow('Bluetooth', '->', 'Native Classic BT Serial (Device: "ESP32-Bluetooth-Hub")'),
              _wiringRow('Builtin LED', '->', 'GPIO 2 (Blue On-board LED)'),
              _wiringRow('4 Relays', '->', 'GPIO 18, 19, 21, 22 (Configurable in Settings)'),
              _wiringRow('4-Pin RGB', '->', 'Red: GPIO 4, Green: GPIO 5, Blue: GPIO 17 (LEDC Channels 1, 2, 3)'),
              _wiringRow('True DACs', '->', 'GPIO 25 (DAC1) & GPIO 26 (DAC2) [0 - 3.3V]'),
              _wiringRow('Touch Pins', '->', 'T0 (GPIO 4), T2 (GPIO 2), T3 (GPIO 15)...'),
            ],
          ),
        );

      case CodeTab.esp32S3:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.memory_rounded, size: 18, color: AppColors.primaryOrange),
                  SizedBox(width: 8),
                  Text(
                    'ESP32-S3 DevKitC-1 Hardware Highlights',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _wiringRow('Serial / BLE', '->', 'Native BLE 5.0 / USB-OTG Serial CDC (115200 Baud)'),
              _wiringRow('Onboard RGB', '->', 'GPIO 48 (WS2812 Smart RGB LED)'),
              _wiringRow('External RGB', '->', 'Red: GPIO 15, Green: GPIO 16, Blue: GPIO 17'),
              _wiringRow('4 Relays', '->', 'GPIO 4, 5, 6, 7 (Configurable in Settings)'),
              _wiringRow('14 Touch', '->', 'Touch 1 to Touch 14 (GPIO 1 to 14)'),
              _wiringRow('20 ADC', '->', '12-bit ADC Channels 1 to 20 (GPIO 1 to 20)'),
            ],
          ),
        );

      case CodeTab.esp32Wifi:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.wifi_rounded, size: 18, color: AppColors.primaryOrange),
                  SizedBox(width: 8),
                  Text(
                    'ESP32 WiFi (SoftAP & Router Mode) Guide',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _wiringRow('SoftAP SSID', '->', 'ESP32_Controller_AP (Password: password123)'),
              _wiringRow('Default IP', '->', '192.168.4.1 (Port 80)'),
              _wiringRow('Connection', '->', 'Connect phone WiFi directly to "ESP32_Controller_AP"'),
              _wiringRow('4-Pin RGB', '->', 'Red: GPIO 4, Green: GPIO 5, Blue: GPIO 17'),
              _wiringRow('4 Relays', '->', 'GPIO 18, 19, 21, 22'),
              _wiringRow('PWM / ADC', '->', 'PWM: GPIO 16, ADC: GPIO 32-39, Touch: GPIO 4'),
            ],
          ),
        );
    }
  }

  Widget _wiringRow(String left, String arrow, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              left,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
          Text(arrow, style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
