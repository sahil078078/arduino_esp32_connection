import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board_model.dart';
import '../providers/bluetooth_provider.dart';
import '../src/commons/btn/custom_btn.dart';
import '../src/commons/btn/custom_close_btn.dart';
import '../src/commons/custom_drop_down_btn.dart';
import '../src/commons/custom_switch_tile.dart';
import '../src/helper/app_toasting.dart';
import '../theme/app_colors.dart';

class PinConfigurationDialog extends StatefulWidget {
  const PinConfigurationDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PinConfigurationDialog(),
    );
  }

  @override
  State<PinConfigurationDialog> createState() => _PinConfigurationDialogState();
}

class _PinConfigurationDialogState extends State<PinConfigurationDialog> {
  late int _builtinLedPin;
  late int _relay1Pin;
  late int _relay2Pin;
  late int _relay3Pin;
  late int _relay4Pin;
  late int _pwmPin;
  late int _rgbRedPin;
  late int _rgbGreenPin;
  late int _rgbBluePin;
  late bool _isCommonAnode;
  late bool _isRgbBuiltin;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final bt = Provider.of<BluetoothProvider>(context, listen: false);
      _builtinLedPin = bt.pinConfig.builtinLedPin;
      _relay1Pin = bt.pinConfig.relay1Pin;
      _relay2Pin = bt.pinConfig.relay2Pin;
      _relay3Pin = bt.pinConfig.relay3Pin;
      _relay4Pin = bt.pinConfig.relay4Pin;
      _pwmPin = bt.pinConfig.pwmPin;
      _rgbRedPin = bt.pinConfig.rgbRedPin;
      _rgbGreenPin = bt.pinConfig.rgbGreenPin;
      _rgbBluePin = bt.pinConfig.rgbBluePin;
      _isCommonAnode = bt.pinConfig.isCommonAnode;
      _isRgbBuiltin = bt.pinConfig.isRgbBuiltin;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothProvider>();
    final board = bt.selectedBoard;
    final availablePins = board.availableGpioPins;

    // Safety fallback if current pin is not in list
    List<int> getDropdownPins(int current) {
      final set = Set<int>.from(availablePins)..add(current);
      final list = set.toList()..sort();
      return list;
    }

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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primaryOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GPIO & Relay Pin Settings',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const CustomCloseBtn(size: 28),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  board.badgeText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configuring pins for ${board.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              children: [
                // 1. Builtin LED Pin
                _buildPinSectionTitle('Built-in LED Pin'),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Built-in LED (Status Indicator)',
                  description:
                      'Board default is GPIO ${board.defaultBuiltinLedPin}',
                  currentPin: _builtinLedPin,
                  pins: getDropdownPins(_builtinLedPin),
                  icon: Icons.lightbulb_rounded,
                  onChanged: (p) => setState(() => _builtinLedPin = p),
                ),

                const SizedBox(height: 16),

                // 2. Relay Pins
                _buildPinSectionTitle('4-Channel Relay Output Pins'),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Relay Channel 1',
                  description: 'Triggered by char "A" / "a" or voice',
                  currentPin: _relay1Pin,
                  pins: getDropdownPins(_relay1Pin),
                  icon: Icons.power_rounded,
                  onChanged: (p) => setState(() => _relay1Pin = p),
                ),
                const SizedBox(height: 8),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Relay Channel 2',
                  description: 'Triggered by char "B" / "b"',
                  currentPin: _relay2Pin,
                  pins: getDropdownPins(_relay2Pin),
                  icon: Icons.power_rounded,
                  onChanged: (p) => setState(() => _relay2Pin = p),
                ),
                const SizedBox(height: 8),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Relay Channel 3',
                  description: 'Triggered by char "C" / "c"',
                  currentPin: _relay3Pin,
                  pins: getDropdownPins(_relay3Pin),
                  icon: Icons.power_rounded,
                  onChanged: (p) => setState(() => _relay3Pin = p),
                ),
                const SizedBox(height: 8),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Relay Channel 4',
                  description: 'Triggered by char "D" / "d"',
                  currentPin: _relay4Pin,
                  pins: getDropdownPins(_relay4Pin),
                  icon: Icons.power_rounded,
                  onChanged: (p) => setState(() => _relay4Pin = p),
                ),

                const SizedBox(height: 16),

                // 3. Default PWM Pin
                _buildPinSectionTitle('Default PWM Duty Cycle Pin'),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Primary PWM Pin',
                  description: 'Used for motor speed / LED dimming',
                  currentPin: _pwmPin,
                  pins: board.pwmPins.contains(_pwmPin)
                      ? board.pwmPins
                      : (List<int>.from(board.pwmPins)
                          ..add(_pwmPin)
                          ..sort()),
                  icon: Icons.tune_rounded,
                  onChanged: (p) => setState(() => _pwmPin = p),
                ),
                const SizedBox(height: 16),

                // 4. Non-Addressable RGB LED Pins (4 legs: R, G, B + Common)
                _buildPinSectionTitle(
                  '4-Pin RGB LED Configuration (Non-Addressable)',
                ),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Red Channel (Leg 1)',
                  description: 'PWM / GPIO pin for Red diode',
                  currentPin: _rgbRedPin,
                  pins: getDropdownPins(_rgbRedPin),
                  icon: Icons.palette_outlined,
                  onChanged: (p) => setState(() => _rgbRedPin = p),
                ),
                const SizedBox(height: 8),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Green Channel (Leg 3)',
                  description: 'PWM / GPIO pin for Green diode',
                  currentPin: _rgbGreenPin,
                  pins: getDropdownPins(_rgbGreenPin),
                  icon: Icons.palette_outlined,
                  onChanged: (p) => setState(() => _rgbGreenPin = p),
                ),
                const SizedBox(height: 8),
                _buildPinSelectorTile(
                  board: board,
                  label: 'Blue Channel (Leg 4)',
                  description: 'PWM / GPIO pin for Blue diode',
                  currentPin: _rgbBluePin,
                  pins: getDropdownPins(_rgbBluePin),
                  icon: Icons.palette_outlined,
                  onChanged: (p) => setState(() => _rgbBluePin = p),
                ),
                const SizedBox(height: 10),

                // Common Anode vs Common Cathode switch
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.appBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: CustomSwitchTile(
                    value: _isCommonAnode,
                    onChanged: (v) => setState(() => _isCommonAnode = v),
                    title: 'Common Leg Polarity',
                    subTitle: _isCommonAnode
                        ? 'Common Anode (+VCC / Inverted PWM)'
                        : 'Common Cathode (GND / Normal PWM)',
                  ),
                ),

                if (board.builtinRgbPin != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.appBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: CustomSwitchTile(
                      value: _isRgbBuiltin,
                      onChanged: (v) => setState(() => _isRgbBuiltin = v),
                      title: 'Target Hardware LED',
                      subTitle: _isRgbBuiltin
                          ? 'On-board LED (GPIO ${board.builtinRgbPin})'
                          : 'External 4-Pin RGB LED Module',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Bottom Action Buttons
          Row(
            children: [
              CustomBtn(
                onTap: () {
                  bt.resetPinsToDefault();
                  setState(() {
                    _builtinLedPin = board.defaultBuiltinLedPin;
                    _relay1Pin = board.defaultRelayPins[0];
                    _relay2Pin = board.defaultRelayPins[1];
                    _relay3Pin = board.defaultRelayPins[2];
                    _relay4Pin = board.defaultRelayPins[3];
                    _pwmPin = board.defaultPwmPin;
                    _rgbRedPin = board.defaultRgbPins[0];
                    _rgbGreenPin = board.defaultRgbPins[1];
                    _rgbBluePin = board.defaultRgbPins[2];
                    _isCommonAnode = false;
                    _isRgbBuiltin = board.builtinRgbPin != null;
                  });
                  AppToasting.showWarningToast('Pins reset to board defaults');
                },
                text: 'Reset',
                prefix: const Icon(
                  Icons.restart_alt_rounded,
                  size: 18,
                  color: AppColors.secondaryText,
                ),
                bgColor: Colors.transparent,
                borderColor: AppColors.border,
                borderWidth: 1,
                radius: 10,
                height: 44,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomBtn(
                  onTap: () {
                    bt.updatePinConfig(
                      builtinLedPin: _builtinLedPin,
                      relay1Pin: _relay1Pin,
                      relay2Pin: _relay2Pin,
                      relay3Pin: _relay3Pin,
                      relay4Pin: _relay4Pin,
                      pwmPin: _pwmPin,
                      rgbRedPin: _rgbRedPin,
                      rgbGreenPin: _rgbGreenPin,
                      rgbBluePin: _rgbBluePin,
                      isCommonAnode: _isCommonAnode,
                      isRgbBuiltin: _isRgbBuiltin,
                    );
                    Navigator.of(context).pop();
                    AppToasting.showSuccessToast(
                      'Pins saved: Relays ($_relay1Pin, $_relay2Pin, $_relay3Pin, $_relay4Pin), RGB ($_rgbRedPin, $_rgbGreenPin, $_rgbBluePin)',
                    );
                  },
                  text: 'Save Pin Configuration',
                  prefix: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  bgColor: AppColors.primaryOrange,
                  borderColor: AppColors.primaryOrange,
                  radius: 10,
                  height: 44,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  String _formatPinLabel(MicrocontrollerBoard board, int p) {
    final tags = <String>[];
    if (board.pwmPins.contains(p)) tags.add('PWM');
    if (board.adcPins.contains(p)) tags.add('ADC');
    if (board.dacPins.contains(p)) tags.add('DAC');
    if (board.touchPins.contains(p)) tags.add('Touch');
    final tagText = tags.isNotEmpty ? ' [${tags.join(', ')}]' : '';
    return 'GPIO $p$tagText';
  }

  Widget _buildPinSelectorTile({
    required MicrocontrollerBoard board,
    required String label,
    required String description,
    required int currentPin,
    required List<int> pins,
    required IconData icon,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.appBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CustomDropdownBtn<int>(
            value: currentPin,
            btnDecoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryOrange, width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryOrange,
              size: 20,
            ),
            items: pins.map((p) {
              return DropdownMenuItem<int>(
                value: p,
                child: Text(
                  _formatPinLabel(board, p),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              );
            }).toList(),
            onChanged: (p) {
              if (p != null) onChanged(p);
            },
          ),
        ],
      ),
    );
  }
}
