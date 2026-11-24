import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InteractiveColorPicker extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final bool enabled;

  const InteractiveColorPicker({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
    this.enabled = true,
  });

  @override
  State<InteractiveColorPicker> createState() => _InteractiveColorPickerState();
}

class _InteractiveColorPickerState extends State<InteractiveColorPicker> {
  late double _hue;
  late double _saturation;
  late double _value;

  final TextEditingController _hexController = TextEditingController();

  static const List<Color> _paletteSwatches = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF3D00), // Deep Orange
    Color(0xFFFF7900), // App Primary Orange
    Color(0xFFFFB300), // Amber
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF76FF03), // Lime
    Color(0xFF00E676), // Green
    Color(0xFF00B0FF), // Light Blue
    Color(0xFF0055FF), // Blue
    Color(0xFF7C4DFF), // Deep Purple
    Color(0xFFD500F9), // Magenta
    Color(0xFFFF4081), // Pink
    Color(0xFF00E5FF), // Cyan
    Color(0xFF1DE9B6), // Teal
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Off / Black
  ];

  @override
  void initState() {
    super.initState();
    _initHsvFromColor(widget.currentColor);
    _updateHexController();
  }

  @override
  void didUpdateWidget(covariant InteractiveColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColor != widget.currentColor) {
      _initHsvFromColor(widget.currentColor);
      _updateHexController();
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _initHsvFromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _updateHexController() {
    final r = (widget.currentColor.r * 255.0).round() & 0xff;
    final g = (widget.currentColor.g * 255.0).round() & 0xff;
    final b = (widget.currentColor.b * 255.0).round() & 0xff;
    final hex =
        '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();
    if (_hexController.text != hex) {
      _hexController.text = hex;
    }
  }

  void _notifyColor() {
    final newColor =
        HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    widget.onColorChanged(newColor);
    _updateHexController();
  }

  void _onPaletteSelected(Color color) {
    if (!widget.enabled) return;
    setState(() {
      _initHsvFromColor(color);
    });
    widget.onColorChanged(color);
    _updateHexController();
  }

  void _onHexSubmitted(String input) {
    String clean = input.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final intVal = int.tryParse(clean, radix: 16);
      if (intVal != null) {
        final c = Color(0xFF000000 | intVal);
        setState(() {
          _initHsvFromColor(c);
        });
        widget.onColorChanged(c);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 2D Saturation / Value Gradient Box
        LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = constraints.maxWidth;
            const boxHeight = 160.0;

            return GestureDetector(
              onPanDown: widget.enabled
                  ? (details) => _handle2DPan(details.localPosition, boxWidth, boxHeight)
                  : null,
              onPanUpdate: widget.enabled
                  ? (details) => _handle2DPan(details.localPosition, boxWidth, boxHeight)
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: boxWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    color: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                  ),
                  child: Stack(
                    children: [
                      // White Horizontal Gradient (Saturation)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.white, Colors.transparent],
                          ),
                        ),
                      ),
                      // Black Vertical Gradient (Value / Brightness)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                      // Current Position Pointer Thumb
                      Positioned(
                        left: (_saturation * boxWidth - 10).clamp(0.0, boxWidth - 20),
                        top: ((1.0 - _value) * boxHeight - 10).clamp(0.0, boxHeight - 20),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(120),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // 2. Rainbow Hue Slider
        LayoutBuilder(
          builder: (context, constraints) {
            final sliderWidth = constraints.maxWidth;
            const sliderHeight = 24.0;

            return GestureDetector(
              onPanDown: widget.enabled
                  ? (details) => _handleHuePan(details.localPosition.dx, sliderWidth)
                  : null,
              onPanUpdate: widget.enabled
                  ? (details) => _handleHuePan(details.localPosition.dx, sliderWidth)
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: sliderWidth,
                  height: sliderHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF0000), // Red 0°
                        Color(0xFFFFFF00), // Yellow 60°
                        Color(0xFF00FF00), // Green 120°
                        Color(0xFF00FFFF), // Cyan 180°
                        Color(0xFF0000FF), // Blue 240°
                        Color(0xFFFF00FF), // Magenta 300°
                        Color(0xFFFF0000), // Red 360°
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Hue Thumb Indicator
                      Positioned(
                        left: ((_hue / 360.0) * sliderWidth - 8).clamp(0.0, sliderWidth - 16),
                        top: 2,
                        child: Container(
                          width: 16,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black.withAlpha(100), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(80),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // 3. Hex Input & Real-time Hex Preview
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _hexController,
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  decoration: const InputDecoration(
                    hintText: '#RRGGBB',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: _onHexSubmitted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Preview Circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withAlpha(100),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 4. Vibrant Palette Swatches Grid
        const Text(
          'Preset Palette',
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
          children: _paletteSwatches.map((swatch) {
            final isSelected = activeColor.toARGB32() == swatch.toARGB32();
            return InkWell(
              onTap: () => _onPaletteSelected(swatch),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.black.withAlpha(40),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: swatch.withAlpha(140),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: swatch.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _handle2DPan(Offset localPos, double width, double height) {
    setState(() {
      _saturation = (localPos.dx / width).clamp(0.0, 1.0);
      _value = (1.0 - (localPos.dy / height)).clamp(0.0, 1.0);
    });
    _notifyColor();
  }

  void _handleHuePan(double dx, double width) {
    setState(() {
      _hue = ((dx / width) * 360.0).clamp(0.0, 360.0);
    });
    _notifyColor();
  }
}
