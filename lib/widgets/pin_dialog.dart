import 'package:flutter/material.dart';
import '../models/bluetooth_device_model.dart';
import '../src/commons/btn/custom_btn.dart';
import '../theme/app_colors.dart';

class PinDialog extends StatefulWidget {
  final BluetoothDeviceModel device;
  final ValueChanged<String> onConnect;

  const PinDialog({
    super.key,
    required this.device,
    required this.onConnect,
  });

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  late TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController(text: widget.device.defaultPin);
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bluetooth Pairing PIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device: ${widget.device.name}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.device.address,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: AppColors.primaryText,
            ),
            decoration: InputDecoration(
              labelText: 'Pairing Password / PIN',
              hintText: '1234 or 0000',
              prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.primaryOrange),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Standard PIN for HC-05 & HC-06 is usually 1234 or 0000.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
      actions: [
        CustomBtn(
          onTap: () => Navigator.of(context).pop(),
          text: 'Cancel',
          bgColor: Colors.transparent,
          borderColor: Colors.transparent,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        CustomBtn(
          onTap: () {
            final pin = _pinController.text.trim();
            Navigator.of(context).pop();
            widget.onConnect(pin.isEmpty ? '1234' : pin);
          },
          text: 'Pair & Connect',
          bgColor: AppColors.primaryOrange,
          borderColor: AppColors.primaryOrange,
          radius: 10,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
