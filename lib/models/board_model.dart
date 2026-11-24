enum BoardType {
  arduinoUno,
  esp32DevKitV1,
  esp32S3,
}

class MicrocontrollerBoard {
  final BoardType type;
  final String id;
  final String name;
  final String shortName;
  final String chipFamily;
  final String logicVoltage;
  final String clockSpeed;
  final String description;
  final String badgeText;

  // Default Pin Configuration
  final int defaultBuiltinLedPin;
  final int defaultPwmPin;
  final List<int> defaultRelayPins; // [Relay 1, Relay 2, Relay 3, Relay 4]

  // Capabilities
  final List<int> pwmPins;
  final List<int> adcPins;
  final List<int> dacPins;
  final List<int> touchPins;
  final List<int> availableGpioPins;
  final Map<int, String> pinDescriptions;

  final bool hasClassicBt;
  final bool hasBle;
  final bool hasDac;
  final bool hasTouch;
  final String bluetoothTypeDescription;

  const MicrocontrollerBoard({
    required this.type,
    required this.id,
    required this.name,
    required this.shortName,
    required this.chipFamily,
    required this.logicVoltage,
    required this.clockSpeed,
    required this.description,
    required this.badgeText,
    required this.defaultBuiltinLedPin,
    required this.defaultPwmPin,
    required this.defaultRelayPins,
    required this.pwmPins,
    required this.adcPins,
    required this.dacPins,
    required this.touchPins,
    required this.availableGpioPins,
    required this.pinDescriptions,
    required this.hasClassicBt,
    required this.hasBle,
    required this.hasDac,
    required this.hasTouch,
    required this.bluetoothTypeDescription,
  });

  static const MicrocontrollerBoard arduinoUno = MicrocontrollerBoard(
    type: BoardType.arduinoUno,
    id: 'arduino_uno',
    name: 'Arduino Uno / Nano',
    shortName: 'Arduino Uno',
    chipFamily: 'ATmega328P (8-bit AVR)',
    logicVoltage: '5V Logic',
    clockSpeed: '16 MHz',
    description: 'Classic Arduino with 14 digital I/O pins, 6 PWM pins, and 6 analog ADC inputs.',
    badgeText: 'UNO / NANO',
    defaultBuiltinLedPin: 13,
    defaultPwmPin: 9,
    defaultRelayPins: [7, 8, 4, 12],
    pwmPins: [3, 5, 6, 9, 10, 11],
    adcPins: [14, 15, 16, 17, 18, 19], // A0=14 to A5=19
    dacPins: [], // No true DAC on Arduino Uno
    touchPins: [], // No capacitive touch
    availableGpioPins: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
    pinDescriptions: {
      2: 'Digital I/O (BT RX from HC-05 TX)',
      3: 'PWM ~Pin 3 (BT TX to HC-05 RX)',
      4: 'Digital I/O / Relay 3',
      5: 'PWM ~Pin 5',
      6: 'PWM ~Pin 6',
      7: 'Digital I/O / Relay 1 (D7)',
      8: 'Digital I/O / Relay 2 (D8)',
      9: 'PWM ~Pin 9 (Default PWM)',
      10: 'PWM ~Pin 10 / SPI SS',
      11: 'PWM ~Pin 11 / SPI MOSI',
      12: 'Digital I/O / Relay 4 (D12)',
      13: 'Built-in LED (Pin 13) / SPI SCK',
      14: 'Analog In A0 / Digital 14',
      15: 'Analog In A1 / Digital 15',
      16: 'Analog In A2 / Digital 16',
      17: 'Analog In A3 / Digital 17',
      18: 'Analog In A4 (I2C SDA) / Digital 18',
      19: 'Analog In A5 (I2C SCL) / Digital 19',
    },
    hasClassicBt: false,
    hasBle: false,
    hasDac: false,
    hasTouch: false,
    bluetoothTypeDescription: 'External HC-05 / HC-06 Bluetooth Module (via SoftwareSerial)',
  );

  static const MicrocontrollerBoard esp32DevKitV1 = MicrocontrollerBoard(
    type: BoardType.esp32DevKitV1,
    id: 'esp32_devkit_v1',
    name: 'ESP32 DevKit V1 (30/36 Pin)',
    shortName: 'ESP32 DevKit V1',
    chipFamily: 'ESP-WROOM-32 (Tensilica Xtensa Dual-Core LX6)',
    logicVoltage: '3.3V Logic',
    clockSpeed: '240 MHz',
    description: 'Powerful dual-core MCU with built-in Classic Bluetooth SPP, BLE, 2x True 8-bit DACs, 10 capacitive touch pins, and 16 LEDC PWM channels.',
    badgeText: 'ESP32 V1',
    defaultBuiltinLedPin: 2,
    defaultPwmPin: 16,
    defaultRelayPins: [18, 19, 21, 22],
    pwmPins: [2, 4, 5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33],
    adcPins: [32, 33, 34, 35, 36, 39, 0, 2, 4, 12, 13, 14, 15, 25, 26, 27], // 12-bit ADC (0-4095)
    dacPins: [25, 26], // DAC1 (GPIO 25), DAC2 (GPIO 26) - 8-bit True Analog
    touchPins: [4, 0, 2, 15, 13, 12, 14, 27, 33, 32], // T0 - T9
    availableGpioPins: [2, 4, 5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33, 34, 35, 36, 39],
    pinDescriptions: {
      2: 'Built-in Blue LED / Touch T2 / ADC2_CH2',
      4: 'Touch T0 / ADC2_CH0 / PWM',
      5: 'PWM / VSPI CS',
      12: 'Touch T5 / ADC2_CH5 / PWM',
      13: 'Touch T4 / ADC2_CH4 / PWM',
      14: 'Touch T6 / ADC2_CH6 / PWM',
      15: 'Touch T3 / ADC2_CH3 / PWM',
      16: 'PWM / UART2 RX',
      17: 'PWM / UART2 TX',
      18: 'Relay 1 (Default GPIO 18) / VSPI SCK',
      19: 'Relay 2 (Default GPIO 19) / VSPI MISO',
      21: 'Relay 3 (Default GPIO 21) / I2C SDA',
      22: 'Relay 4 (Default GPIO 22) / I2C SCL',
      23: 'PWM / VSPI MOSI',
      25: 'DAC 1 (True 8-bit Analog Output) / ADC2_CH8',
      26: 'DAC 2 (True 8-bit Analog Output) / ADC2_CH9',
      27: 'Touch T7 / ADC2_CH7 / PWM',
      32: 'Touch T9 / ADC1_CH4 (Input/Output)',
      33: 'Touch T8 / ADC1_CH5 (Input/Output)',
      34: 'ADC1_CH6 (Input Only, No Pullup)',
      35: 'ADC1_CH7 (Input Only, No Pullup)',
      36: 'ADC1_CH0 (Sensor VP, Input Only)',
      39: 'ADC1_CH3 (Sensor VN, Input Only)',
    },
    hasClassicBt: true,
    hasBle: true,
    hasDac: true,
    hasTouch: true,
    bluetoothTypeDescription: 'Native On-Chip Bluetooth Serial (Classic SPP BluetoothSerial.h)',
  );

  static const MicrocontrollerBoard esp32S3 = MicrocontrollerBoard(
    type: BoardType.esp32S3,
    id: 'esp32_s3',
    name: 'ESP32-S3 DevKitC-1',
    shortName: 'ESP32-S3',
    chipFamily: 'ESP32-S3 (Xtensa Dual-Core LX7 with Vector Instructions)',
    logicVoltage: '3.3V Logic',
    clockSpeed: '240 MHz',
    description: 'High-performance AI/Vector MCU with 44 GPIOs, USB-OTG, BLE 5.0, 14 Touch channels, and up to 20 ADC channels.',
    badgeText: 'ESP32-S3',
    defaultBuiltinLedPin: 48, // WS2812 RGB LED on GPIO 48
    defaultPwmPin: 18,
    defaultRelayPins: [4, 5, 6, 7],
    pwmPins: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 38, 39, 40, 41, 42, 47, 48],
    adcPins: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
    dacPins: [], // Hardware DAC removed on S3
    touchPins: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], // Touch 1 - 14
    availableGpioPins: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 38, 39, 40, 41, 42, 47, 48],
    pinDescriptions: {
      1: 'Touch 1 / ADC1_CH0',
      2: 'Touch 2 / ADC1_CH1',
      3: 'Touch 3 / ADC1_CH2',
      4: 'Relay 1 (Default GPIO 4) / Touch 4 / ADC1_CH3',
      5: 'Relay 2 (Default GPIO 5) / Touch 5 / ADC1_CH4',
      6: 'Relay 3 (Default GPIO 6) / Touch 6 / ADC1_CH5',
      7: 'Relay 4 (Default GPIO 7) / Touch 7 / ADC1_CH6',
      8: 'Touch 8 / ADC1_CH7',
      9: 'Touch 9 / ADC1_CH8',
      10: 'Touch 10 / ADC1_CH9',
      11: 'Touch 11 / ADC2_CH0',
      12: 'Touch 12 / ADC2_CH1',
      13: 'Touch 13 / ADC2_CH2',
      14: 'Touch 14 / ADC2_CH3',
      18: 'Default PWM / USB D-',
      19: 'USB D+ / JTAG',
      20: 'USB D- / JTAG',
      21: 'PWM / GPIO 21',
      38: 'PWM / SPI / JTAG',
      47: 'PWM / GPIO 47',
      48: 'Built-in WS2812 RGB LED (GPIO 48)',
    },
    hasClassicBt: false,
    hasBle: true,
    hasDac: false,
    hasTouch: true,
    bluetoothTypeDescription: 'Native BLE 5.0 (Bluetooth Low Energy) / USB Serial',
  );

  static const List<MicrocontrollerBoard> allBoards = [
    arduinoUno,
    esp32DevKitV1,
    esp32S3,
  ];

  static MicrocontrollerBoard getById(String id) {
    return allBoards.firstWhere(
      (b) => b.id == id,
      orElse: () => esp32DevKitV1,
    );
  }

  static MicrocontrollerBoard getByType(BoardType type) {
    return allBoards.firstWhere(
      (b) => b.type == type,
      orElse: () => esp32DevKitV1,
    );
  }
}

class BoardPinConfig {
  final int builtinLedPin;
  final int relay1Pin;
  final int relay2Pin;
  final int relay3Pin;
  final int relay4Pin;
  final int pwmPin;

  const BoardPinConfig({
    required this.builtinLedPin,
    required this.relay1Pin,
    required this.relay2Pin,
    required this.relay3Pin,
    required this.relay4Pin,
    required this.pwmPin,
  });

  factory BoardPinConfig.fromBoard(MicrocontrollerBoard board) {
    return BoardPinConfig(
      builtinLedPin: board.defaultBuiltinLedPin,
      relay1Pin: board.defaultRelayPins[0],
      relay2Pin: board.defaultRelayPins[1],
      relay3Pin: board.defaultRelayPins[2],
      relay4Pin: board.defaultRelayPins[3],
      pwmPin: board.defaultPwmPin,
    );
  }

  BoardPinConfig copyWith({
    int? builtinLedPin,
    int? relay1Pin,
    int? relay2Pin,
    int? relay3Pin,
    int? relay4Pin,
    int? pwmPin,
  }) {
    return BoardPinConfig(
      builtinLedPin: builtinLedPin ?? this.builtinLedPin,
      relay1Pin: relay1Pin ?? this.relay1Pin,
      relay2Pin: relay2Pin ?? this.relay2Pin,
      relay3Pin: relay3Pin ?? this.relay3Pin,
      relay4Pin: relay4Pin ?? this.relay4Pin,
      pwmPin: pwmPin ?? this.pwmPin,
    );
  }

  List<int> get allRelayPins => [relay1Pin, relay2Pin, relay3Pin, relay4Pin];
}
