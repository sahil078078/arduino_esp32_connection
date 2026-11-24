import 'package:flutter/material.dart';
import '../src/commons/custom_drop_down_btn.dart';
import '../theme/app_colors.dart';

class PwmControlCard extends StatelessWidget {
  final bool isConnected;
  final int pwmPin;
  final List<int> availablePins;
  final ValueChanged<int> onPinChanged;
  final int pwmValue; // 0 to 255
  final ValueChanged<int> onPwmChanged;
  final ValueChanged<int> onPercentPreset;

  const PwmControlCard({
    super.key,
    required this.isConnected,
    required this.pwmPin,
    required this.availablePins,
    required this.onPinChanged,
    required this.pwmValue,
    required this.onPwmChanged,
    required this.onPercentPreset,
  });

  @override
  Widget build(BuildContext context) {
    final percent = ((pwmValue / 255) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pwmValue > 0
              ? AppColors.primaryOrange.withAlpha(90)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Pin Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pwmValue > 0
                            ? AppColors.lightOrange
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: pwmValue > 0
                            ? AppColors.primaryOrange
                            : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PWM Duty Cycle',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'AnalogWrite (0 - 255 Value)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Pin Selector Chip
              CustomDropdownBtn<int>(
                value: availablePins.contains(pwmPin)
                    ? pwmPin
                    : (availablePins.isNotEmpty ? availablePins.first : pwmPin),
                btnDecoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppColors.secondaryText, size: 20),
                items: (Set<int>.from(availablePins)..add(pwmPin)).toList().map((p) {
                  return DropdownMenuItem<int>(
                    value: p,
                    child: Text(
                      'GPIO $p',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (p) {
                  if (p != null) onPinChanged(p);
                },
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Large Value Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Raw: $pwmValue / 255',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Minimal Speed Slider with Orange Active Track
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryOrange,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primaryOrange,
              overlayColor: AppColors.primaryOrange.withAlpha(40),
              trackHeight: 6,
            ),
            child: Slider(
              value: pwmValue.toDouble(),
              min: 0,
              max: 255,
              divisions: 255,
              onChanged: isConnected
                  ? (val) => onPwmChanged(val.round())
                  : null,
            ),
          ),

          const SizedBox(height: 8),

          // Preset Buttons: 0%, 25%, 50%, 75%, 100%
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _presetPill('0%', 0),
              _presetPill('25%', 25),
              _presetPill('50%', 50),
              _presetPill('75%', 75),
              _presetPill('100%', 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetPill(String label, int pct) {
    final isSelected = ((pwmValue / 255) * 100).round() == pct;

    return InkWell(
      onTap: isConnected ? () => onPercentPreset(pct) : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightOrange : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primaryOrange : AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}
