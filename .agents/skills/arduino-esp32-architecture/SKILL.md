---
name: arduino-esp32-architecture
description: >-
  Complete architecture reference, pinout mappings, Bluetooth/WiFi communication protocols,
  UI guidelines, and widget standards for the Arduino & ESP32 Controller application.
---

# Arduino & ESP32 Controller - Master Architecture Skill

## 1. Project Overview & Developer Identity
- **Application Name**: Arduino & ESP32 Controller (`arduino_control_app`)
- **Framework**: Flutter 3.8+ (Dart SDK ^3.8.1)
- **Primary Developer**: Sahil Prajapati (`sahil078078@gmail.com`)
- **Branding**: Orange & White Minimalist Industrial theme (`#FF7900` Primary, `#FFFFFF` Cards, `#F7F8FA` Background).
- **Typography**: 100% **Poppins** (`GoogleFonts.poppins`) across all screens, dialogs, widgets, and themes.

---

## 2. Supported Microcontrollers & Pin Capabilities

### A. Arduino Uno / Nano (ATmega328P)
- **Built-in LED**: GPIO 13 (Char `'1'` = HIGH, `'0'` = LOW)
- **Relay Channels (Default)**: GPIO 7 (R1), GPIO 8 (R2), GPIO 4 (R3), GPIO 12 (R4)
- **PWM Pins**: 3, 5, 6, 9, 10, 11 (8-bit, 0-255)
- **ADC Pins**: A0 (14), A1 (15), A2 (16), A3 (17), A4 (18), A5 (19) (10-bit, 0-1023)
- **RGB LED (4-Pin Non-Addressable)**: R=9, G=10, B=11 (Hardware PWM)
- **DAC**: Not hardware supported (PWM emulation only).
- **Touch**: Not supported.
- **Connection**: HC-05 / HC-06 Bluetooth module via SoftwareSerial (Pins 2 RX, 3 TX at 9600 baud).

### B. ESP32 DevKit V1 (ESP-WROOM-32)
- **Built-in LED**: GPIO 2
- **Relay Channels (Default)**: GPIO 18 (R1), GPIO 19 (R2), GPIO 21 (R3), GPIO 22 (R4)
- **PWM Pins**: 16 hardware channels assignable to any GPIO (e.g., 2, 4, 15, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33).
- **True DAC**: GPIO 25 (DAC1) & GPIO 26 (DAC2) (8-bit true analog voltage, 0V - 3.3V).
- **ADC Pins**: GPIO 32-39, 34-36 (ADC1), 0, 2, 4, 12-15, 25-27 (ADC2) (12-bit, 0-4095).
- **Capacitive Touch**: T0(4), T2(2), T3(15), T4(13), T5(12), T6(14), T7(27), T8(33), T9(32).
- **RGB LED (4-Pin Non-Addressable)**: Configurable, default R=25, G=26, B=27.
- **Connection**: Dual-mode (Bluetooth Classic SPP "ESP32_BT_Controller" or WiFi SoftAP/Station).

### C. ESP32-S3 (Xtensa Dual-Core LX7)
- **Built-in LED**: GPIO 48 (Onboard WS2812 / RGB)
- **Relay Channels (Default)**: GPIO 4 (R1), GPIO 5 (R2), GPIO 6 (R3), GPIO 7 (R4)
- **PWM Pins**: Assignable across GPIOs (1-21, 35-48).
- **DAC**: No hardware DAC on ESP32-S3 (PWM emulation only).
- **ADC Pins**: GPIO 1-10 (ADC1), 11-20 (ADC2).
- **Capacitive Touch**: 14 touch channels (GPIO 1-14).
- **RGB LED (4-Pin Non-Addressable)**: Configurable, default R=4, G=5, B=6.
- **Connection**: BLE / WiFi SoftAP (`192.168.4.1`) or Station (Router IP).

---

## 3. Communication Protocols

### A. Serial & Bluetooth Protocol
| Command | Action |
| :--- | :--- |
| `'1'` / `'0'` | Turn Built-in LED ON / OFF |
| `'A'` / `'a'` | Relay 1 ON / OFF |
| `'B'` / `'b'` | Relay 2 ON / OFF |
| `'C'` / `'c'` | Relay 3 ON / OFF |
| `'D'` / `'d'` | Relay 4 ON / OFF |
| `ALL_ON` / `ALL_OFF` | Turn all outputs ON / OFF |
| `PWM:<pin>:<val>` | Set PWM duty cycle (0-255) on specified pin |
| `DAC:<pin>:<val>` | Set true analog DAC output (0-255) on GPIO 25/26 |
| `RGB:<r>:<g>:<b>` | Set 4-pin RGB LED color (0-255 per channel) |
| `READ:ADC:<pin>` | Request analog reading from specified ADC pin |
| `READ:TOUCH:<pin>` | Request capacitive touch reading from pin |

### B. WiFi Communication Modes
1. **SoftAP Mode (Hotspot)**:
   - ESP32 broadcasts its own Wi-Fi SSID (`ESP32_Controller_AP`).
   - Default IP: `192.168.4.1`, Default HTTP Port: `80`, Default TCP Port: `8080`.
2. **Station Mode (Local Network)**:
   - ESP32 connects to the user's home/office Wi-Fi router.
   - Assigned local IP (e.g., `192.168.1.184`).
3. **HTTP Web Server Protocol**:
   - `GET /` -> HTML Web Dashboard.
   - `GET /ping` -> Returns `200 OK` (Latency testing).
   - `GET /cmd?c=<char>` -> Sends single character command.
   - `GET /text?msg=<text>` -> Sends custom string command.
   - `GET /pwm?pin=<pin>&val=<val>` -> Updates PWM pin.
   - `GET /dac?pin=<pin>&val=<val>` -> Updates DAC pin.
   - `GET /adc?pin=<pin>` -> Reads analog input.
   - `GET /touch?pin=<pin>` -> Reads touch sensor input.
4. **TCP Socket Stream Protocol**:
   - Persistent raw bidirectional TCP socket on port `8080`.
   - Newline-delimited text/binary stream.

---

## 4. UI & Widget Standards
- **Font**: Must use **Poppins** everywhere (`GoogleFonts.poppins`).
- **All Dropdowns**: Must strictly use `CustomDropdownBtn<T>` from `lib/src/commons/custom_drop_down_btn.dart`.
- **Buttons**: Must use `CustomBtn` from `lib/src/commons/btn/custom_btn.dart`.
- **Close Buttons**: Must use `CustomCloseBtn` from `lib/src/commons/btn/custom_close_btn.dart`.
- **Switches**: Must use `CustomSwitchTile` from `lib/src/commons/custom_switch_tile.dart`.
- **Form Fields**: Must use `CustomFormField` from `lib/src/commons/custom_form_field.dart`.
- **AppBars**:
  - Keep titles compact (17-18px bold Poppins, -0.2 letterSpacing).
  - Use concise labels to prevent overflow on mobile displays (<= 390px width).
  - Use compact status pills (`WiFi` / `BT` / `OFFLINE`).
