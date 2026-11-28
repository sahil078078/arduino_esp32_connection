import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board_model.dart';
import '../providers/bluetooth_provider.dart';
import '../src/commons/btn/custom_close_btn.dart';
import '../theme/app_colors.dart';

class BoardSelectionDialog extends StatelessWidget {
  const BoardSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BoardSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothProvider>();
    final currentBoard = bt.selectedBoard;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
          const SizedBox(height: 14),

          // Title & Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.developer_board_rounded,
                        color: AppColors.primaryOrange, size: 22),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Select Microcontroller Board',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CustomCloseBtn(size: 28),
            ],
          ),
          const Text(
            'Pins, PWM channels, DAC, ADC, and Touch sensors adapt automatically.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),

          // Boards list
          ...MicrocontrollerBoard.allBoards.map((board) {
            final isSelected = board.type == currentBoard.type;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.lightOrange.withAlpha(120)
                    : AppColors.appBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  bt.setBoard(board.type);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${board.name}. Default GPIO pins updated!'),
                      backgroundColor: AppColors.primaryOrange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Badge, Name, Active Radio
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              board.badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              board.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primaryOrange,
                              size: 20,
                            )
                          else
                            const Icon(
                              Icons.radio_button_unchecked_rounded,
                              color: AppColors.secondaryText,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Specs Row (Voltage, Clock, Chip)
                      Text(
                        '${board.chipFamily} • ${board.clockSpeed} • ${board.logicVoltage}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Feature Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildTag(
                            'Builtin LED: GPIO ${board.defaultBuiltinLedPin}',
                            Icons.lightbulb_outline,
                          ),
                          _buildTag(
                            '${board.pwmPins.length} PWM Pins',
                            Icons.tune,
                          ),
                          if (board.hasDac)
                            _buildTag(
                              '${board.dacPins.length}x 8-bit DAC (GPIO 25, 26)',
                              Icons.waves,
                              highlight: true,
                            ),
                          if (board.hasTouch)
                            _buildTag(
                              '${board.touchPins.length} Touch Pins',
                              Icons.touch_app_outlined,
                              highlight: true,
                            ),
                          _buildTag(
                            '${board.adcPins.length} ADC Inputs',
                            Icons.analytics_outlined,
                          ),
                          _buildTag(
                            board.hasClassicBt ? 'Classic BT SPP' : 'HC-05 / BLE',
                            Icons.bluetooth,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryOrange.withAlpha(25)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight
              ? AppColors.primaryOrange.withAlpha(80)
              : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: highlight
                  ? AppColors.primaryOrange
                  : AppColors.secondaryText),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight
                  ? AppColors.primaryOrange
                  : AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
