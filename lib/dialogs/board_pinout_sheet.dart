import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../theme/app_colors.dart';

class BoardPinoutSheet extends StatelessWidget {
  const BoardPinoutSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BoardPinoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothProvider>();
    final board = bt.selectedBoard;
    final pinConfig = bt.pinConfig;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.memory_rounded,
                      color: AppColors.primaryOrange, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${board.shortName} Pinout & Specs',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                color: AppColors.secondaryText,
              ),
            ],
          ),
          Text(
            '${board.chipFamily} • ${board.clockSpeed} • ${board.logicVoltage}',
            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              children: [
                // 1. Configured Active Pins Summary Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryOrange.withAlpha(90)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: AppColors.primaryOrange),
                          SizedBox(width: 6),
                          Text(
                            'Active Configured Pins in App',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildActiveChip('LED: GPIO ${pinConfig.builtinLedPin}'),
                          _buildActiveChip('Relay 1: GPIO ${pinConfig.relay1Pin}'),
                          _buildActiveChip('Relay 2: GPIO ${pinConfig.relay2Pin}'),
                          _buildActiveChip('Relay 3: GPIO ${pinConfig.relay3Pin}'),
                          _buildActiveChip('Relay 4: GPIO ${pinConfig.relay4Pin}'),
                          _buildActiveChip('PWM: GPIO ${pinConfig.pwmPin}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Hardware Capabilities Overview
                _buildSectionHeader('Hardware Features'),
                _buildCapabilityRow(
                  icon: Icons.bluetooth,
                  title: 'Bluetooth Protocol',
                  value: board.bluetoothTypeDescription,
                ),
                _buildCapabilityRow(
                  icon: Icons.tune,
                  title: 'PWM Output Channels',
                  value: '${board.pwmPins.length} Pins: ${board.pwmPins.join(", ")}',
                ),
                _buildCapabilityRow(
                  icon: Icons.analytics_outlined,
                  title: 'ADC Analog Inputs',
                  value: '${board.adcPins.length} Pins: ${board.adcPins.take(10).join(", ")}${board.adcPins.length > 10 ? "..." : ""}',
                ),
                _buildCapabilityRow(
                  icon: Icons.waves,
                  title: 'True DAC Analog Output',
                  value: board.hasDac
                      ? '2 Channels: GPIO 25 (DAC1) & GPIO 26 (DAC2) [8-bit 0-3.3V]'
                      : 'Not Available on ${board.shortName} (Use PWM for analog)',
                  highlight: board.hasDac,
                ),
                _buildCapabilityRow(
                  icon: Icons.touch_app_outlined,
                  title: 'Capacitive Touch Sensors',
                  value: board.hasTouch
                      ? '${board.touchPins.length} Touch Pins: ${board.touchPins.join(", ")}'
                      : 'Not Available on ${board.shortName}',
                  highlight: board.hasTouch,
                ),

                const SizedBox(height: 16),

                // 3. Pin by Pin Map
                _buildSectionHeader('GPIO Pin Details (${board.shortName})'),
                ...board.pinDescriptions.entries.map((entry) {
                  final pin = entry.key;
                  final desc = entry.value;

                  final isPwm = board.pwmPins.contains(pin);
                  final isAdc = board.adcPins.contains(pin);
                  final isDac = board.dacPins.contains(pin);
                  final isTouch = board.touchPins.contains(pin);
                  final isConfiguredRelay = pinConfig.allRelayPins.contains(pin);
                  final isConfiguredLed = pinConfig.builtinLedPin == pin;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isConfiguredLed || isConfiguredRelay)
                          ? AppColors.lightOrange.withAlpha(80)
                          : AppColors.appBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isConfiguredLed || isConfiguredRelay)
                            ? AppColors.primaryOrange.withAlpha(90)
                            : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'GPIO $pin',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        // Mini Tags
                        if (isPwm) _buildMiniTag('PWM', Colors.blue),
                        if (isDac) _buildMiniTag('DAC', Colors.purple),
                        if (isTouch) _buildMiniTag('TOUCH', Colors.teal),
                        if (isAdc && !isDac) _buildMiniTag('ADC', Colors.green),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildActiveChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryOrange.withAlpha(70)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  static Widget _buildCapabilityRow({
    required IconData icon,
    required String title,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryOrange.withAlpha(15)
            : AppColors.appBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.primaryOrange.withAlpha(60)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: highlight
                  ? AppColors.primaryOrange
                  : AppColors.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: highlight
                        ? AppColors.primaryOrange
                        : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMiniTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
