import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/board_model.dart';
import '../providers/bluetooth_provider.dart';
import '../src/helper/app_toasting.dart';
import '../theme/app_colors.dart';

class ArduinoCodeScreen extends StatefulWidget {
  const ArduinoCodeScreen({super.key});

  @override
  State<ArduinoCodeScreen> createState() => _ArduinoCodeScreenState();
}

class _ArduinoCodeScreenState extends State<ArduinoCodeScreen> {
  BoardType _selectedTab = BoardType.esp32DevKitV1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bt = Provider.of<BluetoothProvider>(context, listen: false);
    _selectedTab = bt.selectedBoard.type;
  }

  static const String _arduinoUnoSketch = '''// ========================================================
// Arduino Uno / Nano Bluetooth Controller Sketch
// Hardware: Arduino Uno + HC-05 / HC-06 Bluetooth Module
// Wiring: HC-05 TX -> Pin 2 (RX) | HC-05 RX -> Pin 3 (TX)
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

void setup() {
  pinMode(builtinLed, OUTPUT);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  pinMode(relay4, OUTPUT);
  pinMode(pwmPin, OUTPUT);

  digitalWrite(builtinLed, LOW);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  digitalWrite(relay3, LOW);
  digitalWrite(relay4, LOW);

  Serial.begin(9600);
  BT.begin(9600); // Standard HC-05 Baud Rate

  Serial.println("==========================================");
  Serial.println("Arduino Uno Ready for Bluetooth Commands!");
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
        BT.println("ACK: ALL OFF");
      }

      // 4. PWM Duty Cycle ("PWM:9:180")
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

      // 5. ADC Read ("READ:ADC:14")
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

      // 6. Custom Voice / Text
      else {
        Serial.print("-> Custom Text: ");
        Serial.println(msg);
        BT.print("RECEIVED: ");
        BT.println(msg);
      }
    }
  }
}''';

  static const String _esp32DevKitV1Sketch = '''// ========================================================
// ESP32 DevKit V1 Bluetooth Controller Sketch
// Hardware: ESP32 DevKit V1 (ESP-WROOM-32)
// Uses NATIVE ON-CHIP Classic Bluetooth (BluetoothSerial.h)
// NO external HC-05 module needed!
// ========================================================

#include "BluetoothSerial.h"

// Check if Bluetooth is properly enabled in Arduino IDE
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

BluetoothSerial SerialBT;

// Configurable GPIO Pins (ESP32 DevKit V1)
const int builtinLed = 2;   // Blue On-board LED on GPIO 2
const int relay1 = 18;      // Relay 1 GPIO 18
const int relay2 = 19;      // Relay 2 GPIO 19
const int relay3 = 21;      // Relay 3 GPIO 21
const int relay4 = 22;      // Relay 4 GPIO 22

// PWM Configuration (ESP32 LEDC hardware timer)
const int pwmPin = 16;      // Primary PWM GPIO 16
const int pwmChannel = 0;   // LEDC Channel 0
const int pwmFreq = 5000;   // 5 kHz Frequency
const int pwmResolution = 8;// 8-bit resolution (0 - 255)

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

  // Setup ESP32 Hardware PWM (LEDC)
  ledcSetup(pwmChannel, pwmFreq, pwmResolution);
  ledcAttachPin(pwmPin, pwmChannel);

  // Start On-Chip Bluetooth Serial with Device Name
  SerialBT.begin("ESP32-Bluetooth-Hub"); 

  Serial.println("==========================================");
  Serial.println("ESP32 DevKit V1 Ready!");
  Serial.println("Bluetooth Name: 'ESP32-Bluetooth-Hub'");
  Serial.println("True 8-bit DAC on GPIO 25 & 26 Enabled");
  Serial.println("Capacitive Touch Pins T0 - T9 Ready");
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
        SerialBT.println("ACK: ALL PINS OFF");
      }

      // 4. True 8-bit DAC Output (GPIO 25 & 26) ("DAC:25:200")
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

      // 5. LEDC Hardware PWM ("PWM:16:180")
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

      // 6. Capacitive Touch Sensor Read ("READ:TOUCH:4")
      else if (msg.startsWith("READ:TOUCH:")) {
        int pin = msg.substring(11).toInt();
        int touchVal = touchRead(pin); // ESP32 capacitive touch (0 - 100)
        Serial.printf("-> Touch Sensor Pin %d Value: %d\\n", pin, touchVal);
        SerialBT.printf("TOUCH:%d:%d\\n", pin, touchVal);
      }

      // 7. 12-bit ADC Read (GPIO 32 - 39) ("READ:ADC:34")
      else if (msg.startsWith("READ:ADC:")) {
        int pin = msg.substring(9).toInt();
        int adcVal = analogRead(pin); // 12-bit: 0 to 4095
        Serial.printf("-> ADC Pin %d Value: %d (%.2f V)\\n", pin, adcVal, (adcVal / 4095.0) * 3.3);
        SerialBT.printf("ADC:%d:%d\\n", pin, adcVal);
      }

      // 8. Custom Voice Command / Raw String
      else {
        Serial.print("-> Custom Text: ");
        Serial.println(msg);
        SerialBT.print("RECEIVED: ");
        SerialBT.println(msg);
      }
    }
  }
}''';

  static const String _esp32S3Sketch = '''// ========================================================
// ESP32-S3 DevKitC-1 Bluetooth / Serial Controller Sketch
// Hardware: ESP32-S3 (Xtensa Dual-Core LX7)
// Built-in WS2812 RGB LED (GPIO 48), 14 Touch Pins, 20 ADC Pins
// ========================================================

#include <Arduino.h>

// ESP32-S3 GPIO Pins
const int builtinLedPin = 48; // WS2812 RGB / GPIO 48 on DevKitC-1
const int relay1 = 4;
const int relay2 = 5;
const int relay3 = 6;
const int relay4 = 7;
const int pwmPin = 18;

// PWM setup using ESP32-S3 LEDC
const int pwmFreq = 5000;
const int pwmRes = 8;
const int pwmChannel = 0;

void setup() {
  Serial.begin(115200);

  pinMode(builtinLedPin, OUTPUT);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  pinMode(relay4, OUTPUT);

  digitalWrite(builtinLedPin, LOW);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);
  digitalWrite(relay3, LOW);
  digitalWrite(relay4, LOW);

  // Setup LEDC PWM on ESP32-S3
  ledcAttach(pwmPin, pwmFreq, pwmRes);

  Serial.println("==========================================");
  Serial.println("ESP32-S3 DevKitC-1 Ready!");
  Serial.println("14 Capacitive Touch Pins (GPIO 1 to 14)");
  Serial.println("20 ADC Channels (12-bit: 0 - 4095)");
  Serial.println("==========================================");
}

void loop() {
  // Read Serial commands from USB / Bluetooth Bridge
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

      // 3. LEDC PWM ("PWM:18:200")
      else if (msg.startsWith("PWM:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        if (firstColon > 0 && secondColon > 0) {
          int val = msg.substring(secondColon + 1).toInt();
          ledcWrite(pwmPin, val);
          Serial.printf("ACK: PWM %d\\n", val);
        }
      }

      // 4. Capacitive Touch (14 channels on S3: GPIO 1 - 14)
      else if (msg.startsWith("READ:TOUCH:")) {
        int pin = msg.substring(11).toInt();
        int touchVal = touchRead(pin);
        Serial.printf("TOUCH:%d:%d\\n", pin, touchVal);
      }

      // 5. 12-bit ADC Read (20 channels)
      else if (msg.startsWith("READ:ADC:")) {
        int pin = msg.substring(9).toInt();
        int adcVal = analogRead(pin);
        Serial.printf("ADC:%d:%d\\n", pin, adcVal);
      }

      // 6. Custom Voice / Text
      else {
        Serial.print("RECEIVED: ");
        Serial.println(msg);
      }
    }
  }
}''';

  String get _currentSketch {
    switch (_selectedTab) {
      case BoardType.arduinoUno:
        return _arduinoUnoSketch;
      case BoardType.esp32DevKitV1:
        return _esp32DevKitV1Sketch;
      case BoardType.esp32S3:
        return _esp32S3Sketch;
    }
  }

  String get _currentBoardTitle {
    switch (_selectedTab) {
      case BoardType.arduinoUno:
        return 'Arduino Uno / Nano Sketch (.ino)';
      case BoardType.esp32DevKitV1:
        return 'ESP32 DevKit V1 Sketch (.ino)';
      case BoardType.esp32S3:
        return 'ESP32-S3 DevKitC-1 Sketch (.ino)';
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
          // Board Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildBoardTab('Arduino Uno', BoardType.arduinoUno),
                _buildBoardTab('ESP32 V1', BoardType.esp32DevKitV1),
                _buildBoardTab('ESP32-S3', BoardType.esp32S3),
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
                          fontSize: 14,
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

  Widget _buildBoardTab(String title, BoardType type) {
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
              fontSize: 12,
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
      case BoardType.arduinoUno:
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
                    'Arduino Uno + HC-05 Wiring',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _wiringRow('HC-05 VCC', '->', 'Arduino 5V'),
              _wiringRow('HC-05 GND', '->', 'Arduino GND'),
              _wiringRow('HC-05 TX', '->', 'Arduino Pin 2 (Software RX)'),
              _wiringRow('HC-05 RX', '->', 'Arduino Pin 3 (Software TX) [Via 1k/2k Divider]'),
            ],
          ),
        );

      case BoardType.esp32DevKitV1:
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
              _wiringRow('Bluetooth', '->', 'Native Classic BT Serial (No HC-05 needed!)'),
              _wiringRow('Builtin LED', '->', 'GPIO 2 (Blue On-board LED)'),
              _wiringRow('4 Relays', '->', 'GPIO 18, 19, 21, 22 (Configurable in Settings)'),
              _wiringRow('True DACs', '->', 'GPIO 25 (DAC1) & GPIO 26 (DAC2) [0 - 3.3V]'),
              _wiringRow('Touch Pins', '->', 'T0 (GPIO 4), T2 (GPIO 2), T3 (GPIO 15)...'),
            ],
          ),
        );

      case BoardType.esp32S3:
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
              _wiringRow('Bluetooth', '->', 'Native BLE 5.0 / USB-OTG Serial CDC'),
              _wiringRow('Builtin LED', '->', 'GPIO 48 (WS2812 RGB LED)'),
              _wiringRow('4 Relays', '->', 'GPIO 4, 5, 6, 7 (Configurable in Settings)'),
              _wiringRow('14 Touch', '->', 'Touch 1 to Touch 14 (GPIO 1 to 14)'),
              _wiringRow('20 ADC', '->', '12-bit ADC Channels 1 to 20 (GPIO 1 to 20)'),
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
