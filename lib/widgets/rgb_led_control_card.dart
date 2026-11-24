import 'package:flutter/material.dart';
import '../models/board_model.dart';
import '../src/commons/btn/custom_btn.dart';
import '../src/commons/btn/custom_close_btn.dart';
import '../src/commons/custom_drop_down_btn.dart';
import '../src/commons/custom_switch_tile.dart';
import '../src/helper/app_toasting.dart';
import '../theme/app_colors.dart';
import 'interactive_color_picker.dart';

enum RgbViewMode {
  colorPicker,
  sliders,
}

class RgbLedControlCard extends StatefulWidget {
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
  final MicrocontrollerBoard board;
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
    required this.board,
    required this.onTogglePower,
    required this.onColorChanged,
    required this.onConfigChanged,
  });

  @override
  State<RgbLedControlCard> createState() => _RgbLedControlCardState();
}

class _RgbLedControlCardState extends State<RgbLedControlCard> {
  RgbViewMode _viewMode = RgbViewMode.colorPicker;

  Color get _currentColor => Color.fromARGB(255, widget.red, widget.green, widget.blue);

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

  String _formatPinLabel(int pin) {
    final tags = <String>[];
    if (widget.board.pwmPins.contains(pin)) tags.add('PWM');
    if (widget.board.adcPins.contains(pin)) tags.add('ADC');
    if (widget.board.dacPins.contains(pin)) tags.add('DAC');
    if (widget.board.touchPins.contains(pin)) tags.add('Touch');
    final tagText = tags.isNotEmpty ? ' [${tags.join(', ')}]' : '';
    return 'GPIO $pin$tagText';
  }

  void _showPinSetupSheet(BuildContext context) {
    int tempRed = widget.redPin;
    int tempGreen = widget.greenPin;
    int tempBlue = widget.bluePin;
    bool tempAnode = widget.isCommonAnode;
    bool tempBuiltin = widget.isRgbBuiltin;

    final availablePins = Set<int>.from(widget.board.availableGpioPins)
      ..addAll([tempRed, tempGreen, tempBlue]);
    final sortedPins = availablePins.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: AppColors.primaryOrange, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'RGB GPIO Pin Configuration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const CustomCloseBtn(size: 28),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assign Red, Green, Blue pins from ${widget.board.shortName} (Normal, PWM, ADC).',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 14),

                  // Red Channel Pin Dropdown
                  _buildDropdownRow(
                    label: 'Red Channel (Leg 1)',
                    pin: tempRed,
                    color: const Color(0xFFEF4444),
                    pins: sortedPins,
                    onChanged: (p) => setModalState(() => tempRed = p),
                  ),
                  const SizedBox(height: 8),

                  // Green Channel Pin Dropdown
                  _buildDropdownRow(
                    label: 'Green Channel (Leg 3)',
                    pin: tempGreen,
                    color: const Color(0xFF10B981),
                    pins: sortedPins,
                    onChanged: (p) => setModalState(() => tempGreen = p),
                  ),
                  const SizedBox(height: 8),

                  // Blue Channel Pin Dropdown
                  _buildDropdownRow(
                    label: 'Blue Channel (Leg 4)',
                    pin: tempBlue,
                    color: const Color(0xFF3B82F6),
                    pins: sortedPins,
                    onChanged: (p) => setModalState(() => tempBlue = p),
                  ),
                  const SizedBox(height: 12),

                  // Common Polarity Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.appBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: CustomSwitchTile(
                      value: tempAnode,
                      onChanged: (val) => setModalState(() => tempAnode = val),
                      title: 'Common Leg Polarity',
                      subTitle: tempAnode
                          ? 'Common Anode (+VCC / Inverted PWM)'
                          : 'Common Cathode (GND / Normal PWM)',
                    ),
                  ),

                  // ESP32-S3 Onboard vs External Switch
                  if (widget.boardHasBuiltinRgb) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.appBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: CustomSwitchTile(
                        value: tempBuiltin,
                        onChanged: (val) => setModalState(() => tempBuiltin = val),
                        title: 'Target Hardware LED',
                        subTitle: tempBuiltin
                            ? 'On-board LED (GPIO ${widget.board.builtinRgbPin})'
                            : 'External 4-Pin RGB LED Module',
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Save & Apply Button
                  CustomBtn(
                    width: double.infinity,
                    height: 44,
                    text: 'Save & Apply RGB Pins',
                    prefix: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                    bgColor: AppColors.primaryOrange,
                    borderColor: AppColors.primaryOrange,
                    radius: 10,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    onTap: () {
                      widget.onConfigChanged(
                        rPin: tempRed,
                        gPin: tempGreen,
                        bPin: tempBlue,
                        isCommonAnode: tempAnode,
                        isRgbBuiltin: tempBuiltin,
                      );
                      Navigator.of(context).pop();
                      AppToasting.showSuccessToast(
                        'RGB Pins saved: R=GPIO $tempRed, G=GPIO $tempGreen, B=GPIO $tempBlue',
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required int pin,
    required Color color,
    required List<int> pins,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.appBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          CustomDropdownBtn<int>(
            value: pin,
            btnDecoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryOrange, width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryOrange, size: 18),
            items: pins.map((p) {
              return DropdownMenuItem<int>(
                value: p,
                child: Text(
                  _formatPinLabel(p),
                  style: const TextStyle(
                    fontSize: 11.5,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isRgbOn
              ? _currentColor.withAlpha(120)
              : AppColors.border,
          width: 1.2,
        ),
        boxShadow: widget.isRgbOn
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
          // Header: Icon, Title, Pin Configuration Button & Power Switch
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
                          colors: widget.isRgbOn
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
                          InkWell(
                            onTap: () => _showPinSetupSheet(context),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'R: GPIO ${widget.redPin} • G: GPIO ${widget.greenPin} • B: GPIO ${widget.bluePin}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryOrange,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_note_rounded, size: 14, color: AppColors.primaryOrange),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryOrange),
                    tooltip: 'Change RGB Pins',
                    onPressed: () => _showPinSetupSheet(context),
                  ),
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: widget.isRgbOn,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primaryOrange,
                      inactiveThumbColor: AppColors.secondaryText,
                      inactiveTrackColor: AppColors.border,
                      onChanged: widget.isConnected ? widget.onTogglePower : null,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Live Color Preview Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isRgbOn ? _currentColor : const Color(0xFF202020),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withAlpha(60),
                width: 1.5,
              ),
              boxShadow: widget.isRgbOn
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
                      widget.isRgbOn ? 'ACTIVE COLOR' : 'RGB LED OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _getContrastTextColor(widget.isRgbOn ? _currentColor : Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'rgb(${widget.red}, ${widget.green}, ${widget.blue})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _getContrastTextColor(widget.isRgbOn ? _currentColor : Colors.grey),
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
                    '#${widget.red.toRadixString(16).padLeft(2, '0').toUpperCase()}${widget.green.toRadixString(16).padLeft(2, '0').toUpperCase()}${widget.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}',
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

          // Polarity & Target LED Quick Pills
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => widget.onConfigChanged(isCommonAnode: !widget.isCommonAnode),
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
                          widget.isCommonAnode ? Icons.battery_charging_full_rounded : Icons.power_input_rounded,
                          size: 15,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.isCommonAnode ? 'Common Anode (+VCC)' : 'Common Cathode (GND)',
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
              if (widget.boardHasBuiltinRgb) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => widget.onConfigChanged(isRgbBuiltin: !widget.isRgbBuiltin),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.isRgbBuiltin ? AppColors.lightOrange : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isRgbBuiltin ? AppColors.primaryOrange : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isRgbBuiltin ? Icons.memory_rounded : Icons.cable_rounded,
                          size: 15,
                          color: widget.isRgbBuiltin ? AppColors.primaryOrange : AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.isRgbBuiltin ? 'Onboard (GPIO 48)' : 'External (4-Pin)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.isRgbBuiltin ? AppColors.primaryOrange : AppColors.primaryText,
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

          // View Mode Selector: [ 🎨 Color Picker ] vs [ 🎚️ RGB Sliders ]
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _viewMode = RgbViewMode.colorPicker),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _viewMode == RgbViewMode.colorPicker
                            ? AppColors.primaryOrange
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.color_lens_rounded,
                            size: 16,
                            color: _viewMode == RgbViewMode.colorPicker ? Colors.white : AppColors.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Color Picker',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _viewMode == RgbViewMode.colorPicker ? Colors.white : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _viewMode = RgbViewMode.sliders),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _viewMode == RgbViewMode.sliders
                            ? AppColors.primaryOrange
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: _viewMode == RgbViewMode.sliders ? Colors.white : AppColors.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'RGB Sliders',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _viewMode == RgbViewMode.sliders ? Colors.white : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // View Content: Interactive Color Picker vs Sliders
          if (_viewMode == RgbViewMode.colorPicker) ...[
            InteractiveColorPicker(
              currentColor: _currentColor,
              enabled: widget.isConnected,
              onColorChanged: (c) {
                final r = (c.r * 255.0).round() & 0xff;
                final g = (c.g * 255.0).round() & 0xff;
                final b = (c.b * 255.0).round() & 0xff;
                widget.onColorChanged(r, g, b);
              },
            ),
          ] else ...[
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
                final isSelected = widget.isRgbOn &&
                    widget.red == preset.r &&
                    widget.green == preset.g &&
                    widget.blue == preset.b;
                return InkWell(
                  onTap: widget.isConnected ? () => widget.onColorChanged(preset.r, preset.g, preset.b) : null,
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
              value: widget.red,
              pin: widget.redPin,
              color: const Color(0xFFEF4444),
              onChanged: widget.isConnected ? (val) => widget.onColorChanged(val, widget.green, widget.blue) : null,
            ),

            // Green Channel Slider
            _buildChannelSlider(
              channelName: 'Green (G)',
              value: widget.green,
              pin: widget.greenPin,
              color: const Color(0xFF10B981),
              onChanged: widget.isConnected ? (val) => widget.onColorChanged(widget.red, val, widget.blue) : null,
            ),

            // Blue Channel Slider
            _buildChannelSlider(
              channelName: 'Blue (B)',
              value: widget.blue,
              pin: widget.bluePin,
              color: const Color(0xFF3B82F6),
              onChanged: widget.isConnected ? (val) => widget.onColorChanged(widget.red, widget.green, val) : null,
            ),
          ],

          const SizedBox(height: 12),

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
                    '4-Leg Pinout: Leg 1=Red (GPIO ${widget.redPin}) • Leg 2=${widget.isCommonAnode ? "3.3V (Anode)" : "GND (Cathode)"} • Leg 3=Green (GPIO ${widget.greenPin}) • Leg 4=Blue (GPIO ${widget.bluePin})',
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
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: color,
            inactiveTrackColor: color.withAlpha(50),
            thumbColor: color,
            overlayColor: color.withAlpha(40),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: onChanged != null ? (v) => onChanged(v.round()) : null,
          ),
        ),
      ],
    );
  }

  Color _getContrastTextColor(Color bg) {
    return bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
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
