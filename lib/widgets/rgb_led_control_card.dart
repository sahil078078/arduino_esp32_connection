import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RgbLedControlCard extends StatelessWidget {
  final bool isConnected;
  final bool isRgbOn;
  final int red;
  final int green;
  final int blue;
  final int redPin;
  final int greenPin;
  final int bluePin;
  final bool isCommonAnode;
  final bool isRgbBuiltin;
  final bool boardHasBuiltinRgb;
  final ValueChanged<bool> onTogglePower;
  final Function(int r, int g, int b) onColorChanged;
  final Function({int? rPin, int? gPin, int? bPin, bool? isCommonAnode, bool? isRgbBuiltin}) onConfigChanged;

  const RgbLedControlCard({
    super.key,
    required this.isConnected,
    required this.isRgbOn,
    required this.red,
    required this.green,
    required this.blue,
    required this.redPin,
    required this.greenPin,
    required this.bluePin,
    required this.isCommonAnode,
    required this.isRgbBuiltin,
    this.boardHasBuiltinRgb = false,
    required this.onTogglePower,
    required this.onColorChanged,
    required this.onConfigChanged,
  });

  Color get _currentColor => Color.fromARGB(255, red, green, blue);

  static const List<_PresetColor> _presets = [
    _PresetColor('Red', Color(0xFFFF0000), 255, 0, 0),
    _PresetColor('Green', Color(0xFF00FF00), 0, 255, 0),
    _PresetColor('Blue', Color(0xFF0000FF), 0, 0, 255),
    _PresetColor('Yellow', Color(0xFFFFFF00), 255, 255, 0),
    _PresetColor('Cyan', Color(0xFF00FFFF), 0, 255, 255),
    _PresetColor('Magenta', Color(0xFFFF00FF), 255, 0, 255),
    _PresetColor('White', Color(0xFFFFFFFF), 255, 255, 255),
    _PresetColor('Orange', Color(0xFFFF7900), 255, 121, 0),
    _PresetColor('Purple', Color(0xFF9333EA), 147, 51, 234),
    _PresetColor('Off', Color(0xFF000000), 0, 0, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRgbOn
              ? _currentColor.withAlpha(120)
              : AppColors.border,
          width: 1.2,
        ),
        boxShadow: isRgbOn
            ? [
                BoxShadow(
                  color: _currentColor.withAlpha(40),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon, Title, and Power Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRgbOn
                              ? [const Color(0xFFFF416C), const Color(0xFFFF4B2B)]
                              : [AppColors.surfaceMuted, AppColors.surfaceMuted],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.palette_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RGB LED Module (4-Pin)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'R: GPIO $redPin • G: GPIO $greenPin • B: GPIO $bluePin',
                            style: const TextStyle(
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
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: isRgbOn,
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primaryOrange,
                  inactiveThumbColor: AppColors.secondaryText,
                  inactiveTrackColor: AppColors.border,
                  onChanged: isConnected ? onTogglePower : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Live Color Preview Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isRgbOn ? _currentColor : const Color(0xFF202020),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withAlpha(60),
                width: 1.5,
              ),
              boxShadow: isRgbOn
                  ? [
                      BoxShadow(
                        color: _currentColor.withAlpha(90),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRgbOn ? 'ACTIVE COLOR' : 'RGB LED OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _getContrastTextColor(isRgbOn ? _currentColor : Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'rgb($red, $green, $blue)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _getContrastTextColor(isRgbOn ? _currentColor : Colors.grey),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(60),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${red.toRadixString(16).padLeft(2, '0').toUpperCase()}${green.toRadixString(16).padLeft(2, '0').toUpperCase()}${blue.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Common Type & LED Target Selector
          Row(
            children: [
              // Common Cathode vs Common Anode Pill
              Expanded(
                child: InkWell(
                  onTap: () => onConfigChanged(isCommonAnode: !isCommonAnode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCommonAnode ? Icons.battery_charging_full_rounded : Icons.power_input_rounded,
                          size: 15,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isCommonAnode ? 'Common Anode (+VCC)' : 'Common Cathode (GND)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (boardHasBuiltinRgb) ...[
                const SizedBox(width: 8),
                // ESP32-S3 Builtin vs External Toggle
                InkWell(
                  onTap: () => onConfigChanged(isRgbBuiltin: !isRgbBuiltin),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isRgbBuiltin ? AppColors.lightOrange : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRgbBuiltin ? AppColors.primaryOrange : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isRgbBuiltin ? Icons.memory_rounded : Icons.cable_rounded,
                          size: 15,
                          color: isRgbBuiltin ? AppColors.primaryOrange : AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isRgbBuiltin ? 'Onboard (GPIO 48)' : 'External (4-Pin)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isRgbBuiltin ? AppColors.primaryOrange : AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Preset Color Chips
          const Text(
            'Quick Colors',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((preset) {
              final isSelected = isRgbOn &&
                  red == preset.r &&
                  green == preset.g &&
                  blue == preset.b;
              return InkWell(
                onTap: isConnected ? () => onColorChanged(preset.r, preset.g, preset.b) : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: preset.color == const Color(0xFF000000)
                        ? Colors.black
                        : preset.color.withAlpha(isSelected ? 255 : 30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.black : preset.color.withAlpha(120),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: preset.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? _getContrastTextColor(preset.color)
                              : (preset.color == const Color(0xFF000000)
                                  ? Colors.white
                                  : AppColors.primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),

          // Red Channel Slider
          _buildChannelSlider(
            channelName: 'Red (R)',
            value: red,
            pin: redPin,
            color: const Color(0xFFEF4444),
            onChanged: isConnected ? (val) => onColorChanged(val, green, blue) : null,
          ),

          // Green Channel Slider
          _buildChannelSlider(
            channelName: 'Green (G)',
            value: green,
            pin: greenPin,
            color: const Color(0xFF10B981),
            onChanged: isConnected ? (val) => onColorChanged(red, val, blue) : null,
          ),

          // Blue Channel Slider
          _buildChannelSlider(
            channelName: 'Blue (B)',
            value: blue,
            pin: bluePin,
            color: const Color(0xFF3B82F6),
            onChanged: isConnected ? (val) => onColorChanged(red, green, val) : null,
          ),

          const SizedBox(height: 6),

          // 4-Leg Pinout Helper Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primaryOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '4-Leg Pinout: Leg 1=Red (GPIO $redPin) • Leg 2=${isCommonAnode ? "3.3V (Anode)" : "GND (Cathode)"} • Leg 3=Green (GPIO $greenPin) • Leg 4=Blue (GPIO $bluePin)',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelSlider({
    required String channelName,
    required int value,
    required int pin,
    required Color color,
    required ValueChanged<int>? onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '$channelName • GPIO $pin',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
            Text(
              '$value / 255',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withAlpha(40),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            onChanged: onChanged != null ? (v) => onChanged(v.round()) : null,
          ),
        ),
      ],
    );
  }

  Color _getContrastTextColor(Color color) {
    // Luminance check
    final luminance = color.computeLuminance();
    return luminance > 0.45 ? Colors.black : Colors.white;
  }
}

class _PresetColor {
  final String name;
  final Color color;
  final int r;
  final int g;
  final int b;
  const _PresetColor(this.name, this.color, this.r, this.g, this.b);
}
