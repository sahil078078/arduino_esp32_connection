import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class ArduinoCodeScreen extends StatelessWidget {
  const ArduinoCodeScreen({super.key});

  static const String _arduinoSketch = '''// Arduino & ESP32 Bluetooth Controller Sketch
// Supports: Voice Commands ("LED_ON", "LED_OFF", "ALL_ON", "ALL_OFF", "FORWARD", etc.)
// And Single Chars ('1', '0', 'F', 'B', 'L', 'R', 'S') + PWM ("PWM:9:180")
// Connect HC-05 TX to Arduino Pin 2 (RX)
// Connect HC-05 RX to Arduino Pin 3 (TX)

#include <SoftwareSerial.h>

// RX = Pin 2, TX = Pin 3
SoftwareSerial BT(2, 3);

const int builtinLed = 13;
const int relay1 = 7;
const int relay2 = 8;
const int pwmPin = 9;

void setup() {
  pinMode(builtinLed, OUTPUT);
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(pwmPin, OUTPUT);

  digitalWrite(builtinLed, LOW);
  digitalWrite(relay1, LOW);
  digitalWrite(relay2, LOW);

  // PC Serial Monitor debug
  Serial.begin(9600);
  
  // HC-05 Bluetooth baud rate
  BT.begin(9600);
  
  Serial.println("==========================================");
  Serial.println("Arduino/Esp32 Controller Ready!");
  Serial.println("Waiting for Voice & BT commands...");
  Serial.println("==========================================");
  BT.println("CONNECTED: Arduino Hub Ready");
}

void loop() {
  // Read incoming string from Bluetooth (Voice command or Text)
  if (BT.available()) {
    String msg = BT.readStringUntil('\\n');
    msg.trim(); // Remove whitespace and \\r

    if (msg.length() > 0) {
      Serial.print("[BT IN] ");
      Serial.println(msg);

      String lower = msg;
      lower.toLowerCase();

      // 1. LED / Light Controls (Voice: "1", "0", "one", "zero", "on", "off", "ledon", "light on")
      if (lower == "1" || lower == "one" || lower == "on" || lower == "ledon" || lower == "light on" || lower == "lighton" || lower == "led on" || msg == "LED_ON") {
        digitalWrite(builtinLed, HIGH);
        Serial.println("-> Action: LED 13 Turned ON");
        BT.println("ACK: LED ON");
      }
      else if (lower == "0" || lower == "zero" || lower == "off" || lower == "ledoff" || lower == "light off" || lower == "lightoff" || lower == "led off" || msg == "LED_OFF") {
        digitalWrite(builtinLed, LOW);
        Serial.println("-> Action: LED 13 Turned OFF");
        BT.println("ACK: LED OFF");
      }

      // 2. All On / All Off (Voice: "all on", "all off")
      else if (lower == "all on" || lower == "allon" || msg == "ALL_ON") {
        digitalWrite(builtinLed, HIGH);
        digitalWrite(relay1, HIGH);
        digitalWrite(relay2, HIGH);
        Serial.println("-> Action: ALL PINS & RELAYS ON");
        BT.println("ACK: ALL ON");
      }
      else if (lower == "all off" || lower == "alloff" || msg == "ALL_OFF") {
        digitalWrite(builtinLed, LOW);
        digitalWrite(relay1, LOW);
        digitalWrite(relay2, LOW);
        Serial.println("-> Action: ALL PINS & RELAYS OFF");
        BT.println("ACK: ALL OFF");
      }

      // 3. Robot Motion Controls (Voice: "forward", "backward", "left", "right", "stop")
      else if (lower == "f" || lower == "forward" || lower.indexOf("forward") >= 0) {
        Serial.println("-> Robot: Moving FORWARD");
        BT.println("ROBOT: FORWARD");
      }
      else if (lower == "b" || lower == "backward" || lower == "back" || lower.indexOf("backward") >= 0) {
        Serial.println("-> Robot: Moving BACKWARD");
        BT.println("ROBOT: BACKWARD");
      }
      else if (lower == "l" || lower == "left" || lower.indexOf("left") >= 0) {
        Serial.println("-> Robot: Turning LEFT");
        BT.println("ROBOT: LEFT");
      }
      else if (lower == "r" || lower == "right" || lower.indexOf("right") >= 0) {
        Serial.println("-> Robot: Turning RIGHT");
        BT.println("ROBOT: RIGHT");
      }
      else if (lower == "s" || lower == "stop" || lower.indexOf("stop") >= 0) {
        Serial.println("-> Robot: STOPPED");
        BT.println("ROBOT: STOP");
      }

      // 4. Relays
      else if (msg == "A") {
        digitalWrite(relay1, HIGH);
        BT.println("ACK: Relay 1 ON");
      }
      else if (msg == "a") {
        digitalWrite(relay1, LOW);
        BT.println("ACK: Relay 1 OFF");
      }

      // 5. PWM Duty Cycle: e.g. "PWM:9:180"
      else if (msg.startsWith("PWM:")) {
        int firstColon = msg.indexOf(':');
        int secondColon = msg.indexOf(':', firstColon + 1);
        if (firstColon != -1 && secondColon != -1) {
          int pin = msg.substring(firstColon + 1, secondColon).toInt();
          int val = msg.substring(secondColon + 1).toInt();
          analogWrite(pin, constrain(val, 0, 255));
          Serial.print("-> PWM Pin ");
          Serial.print(pin);
          Serial.print(" set to ");
          Serial.println(val);
          BT.println("ACK: PWM Applied");
        }
      }
      else {
        Serial.print("-> Voice/Text Message: ");
        Serial.println(msg);
        BT.print("RCV: ");
        BT.println(msg);
      }
    }
  }

  // Forward PC Serial Monitor input to Bluetooth (optional)
  if (Serial.available()) {
    BT.write(Serial.read());
  }
}
''';

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
        title: const Text(
          'Arduino C++ Sketch',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: _arduinoSketch));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Arduino sketch copied to clipboard!'),
                  backgroundColor: AppColors.primaryOrange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: AppColors.primaryOrange),
            tooltip: 'Copy Code',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Wiring Diagram Helper Card
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
                const Row(
                  children: [
                    Icon(Icons.cable_rounded,
                        size: 20, color: AppColors.primaryOrange),
                    SizedBox(width: 8),
                    Text(
                      'HC-05 / HC-06 Wiring Guide',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),
                _wiringRow('HC-05 VCC', '->', 'Arduino 5V'),
                _wiringRow('HC-05 GND', '->', 'Arduino GND'),
                _wiringRow('HC-05 TX', '->', 'Arduino Pin 2 (Software RX)'),
                _wiringRow('HC-05 RX', '->', 'Arduino Pin 3 (Software TX)'),
                const SizedBox(height: 6),
                const Text(
                  'Note: HC-05 RX operates at 3.3V logic. Use a 1k & 2k resistor divider between Arduino Pin 3 and HC-05 RX.',
                  style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),

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
                    const Text(
                      'Arduino IDE Sketch (.ino)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            const ClipboardData(text: _arduinoSketch));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Arduino sketch copied to clipboard!'),
                            backgroundColor: AppColors.primaryOrange,
                          ),
                        );
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
                  child: const SelectableText(
                    _arduinoSketch,
                    style: TextStyle(
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

  Widget _wiringRow(String left, String arrow, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              left,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: AppColors.primaryOrange,
              ),
            ),
          ),
          Text(arrow,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
          const SizedBox(width: 8),
          Text(
            right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
