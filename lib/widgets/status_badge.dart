import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final String? label;

  const StatusBadge({
    super.key,
    required this.isConnected,
    this.isConnecting = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Color dotColor;
    Color bgColor;
    Color textColor;

    if (isConnecting) {
      text = 'CONNECTING...';
      dotColor = AppColors.warningAmber;
      bgColor = AppColors.lightOrange;
      textColor = AppColors.warningAmber;
    } else if (isConnected) {
      text = label ?? 'BT CONNECTED';
      dotColor = AppColors.primaryOrange;
      bgColor = AppColors.lightOrange;
      textColor = AppColors.primaryOrange;
    } else {
      text = 'DISCONNECTED';
      dotColor = AppColors.secondaryText;
      bgColor = AppColors.surfaceMuted;
      textColor = AppColors.secondaryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppColors.primaryOrange.withAlpha(50)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConnecting)
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.warningAmber,
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
