import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board_model.dart';
import '../providers/bluetooth_provider.dart';
import '../theme/app_colors.dart';

class SensorsDacCard extends StatefulWidget {
  final bool isConnected;

  const SensorsDacCard({
    super.key,
    required this.isConnected,
  });

  @override
  State<SensorsDacCard> createState() => _SensorsDacCardState();
}

class _SensorsDacCardState extends State<SensorsDacCard> {
  int _selectedAdcPin = 14; // Default A0
  int _selectedTouchPin = 4; // Default T0

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bt = Provider.of<BluetoothProvider>(context, listen: false);
    if (bt.availableAdcPins.isNotEmpty && !bt.availableAdcPins.contains(_selectedAdcPin)) {
      _selectedAdcPin = bt.availableAdcPins.first;
    }
    if (bt.availableTouchPins.isNotEmpty && !bt.availableTouchPins.contains(_selectedTouchPin)) {
      _selectedTouchPin = bt.availableTouchPins.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothProvider>();
    final board = bt.selectedBoard;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sensors_rounded,
                        size: 20,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAC, ADC & Touch Sensors',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Hardware analog & capacitive touch controls',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  board.badgeText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // 1. DAC Section (True 8-bit Analog Output - ESP32 Only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.waves, size: 16, color: AppColors.primaryOrange),
                  const SizedBox(width: 6),
                  const Text(
                    'DAC True Analog Output',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              if (board.hasDac) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: bt.dacPin,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.primaryOrange, size: 18),
                      items: board.dacPins.map((p) {
                        return DropdownMenuItem<int>(
                          value: p,
                          child: Text(
                            'DAC Pin $p',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (p) {
                        if (p != null) bt.setDacPin(p);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          if (board.hasDac) ...[
            Text(
              '8-bit true analog voltage on GPIO ${bt.dacPin} (0V to 3.3V):',
              style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),

            // Voltage & Value readout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${bt.dacVoltage.toStringAsFixed(2)} V',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
                Text(
                  'Value: ${bt.dacValue} / 255',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primaryOrange,
                thumbColor: AppColors.primaryOrange,
                inactiveTrackColor: AppColors.border,
                trackHeight: 4,
              ),
              child: Slider(
                value: bt.dacValue.toDouble(),
                min: 0,
                max: 255,
                onChanged: widget.isConnected
                    ? (val) => bt.setDacValue(val.round())
                    : null,
              ),
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.secondaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'True DAC is hardware-supported on ESP32 DevKit V1 (GPIO 25 & 26). Use PWM for analog emulation on ${board.shortName}.',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // 2. Capacitive Touch Sensors (ESP32 & ESP32-S3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 16, color: AppColors.primaryOrange),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Capacitive Touch Input',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (board.hasTouch && board.touchPins.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: widget.isConnected
                      ? () => bt.requestTouchRead(_selectedTouchPin)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.sensors, size: 12),
                  label: const Text('Read Touch', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          if (board.hasTouch && board.touchPins.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: board.touchPins.take(8).map((pin) {
                final isSelected = pin == _selectedTouchPin;
                return ChoiceChip(
                  label: Text('GPIO $pin'),
                  selected: isSelected,
                  selectedColor: AppColors.lightOrange,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryOrange : AppColors.primaryText,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryOrange : AppColors.border,
                  ),
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedTouchPin = pin);
                  },
                );
              }).toList(),
            ),
          ] else ...[
            const Text(
              'Touch sensors not supported on Arduino Uno (Supported on ESP32 & ESP32-S3).',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // 3. ADC Sensor Inputs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined,
                        size: 16, color: AppColors.primaryOrange),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ADC Analog Sensor Reader',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.isConnected
                    ? () => bt.requestAdcRead(_selectedAdcPin)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 12),
                label: const Text('Read ADC', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: board.adcPins.take(6).map((pin) {
              final isSelected = pin == _selectedAdcPin;
              final label = board.type == BoardType.arduinoUno
                  ? 'A${pin - 14}'
                  : 'GPIO $pin';
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: AppColors.lightOrange,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryOrange : AppColors.primaryText,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryOrange : AppColors.border,
                ),
                onSelected: (sel) {
                  if (sel) setState(() => _selectedAdcPin = pin);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
