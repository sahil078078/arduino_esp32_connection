import 'package:flutter/material.dart';

import '../../constants/constant.dart';
import 'custom_icon_btn.dart';

class CustomCloseBtn extends StatelessWidget {
  const CustomCloseBtn({
    super.key,
    this.onClose,
    this.bgColor,
    this.size,
    this.iconColor,
  });
  final GestureTapCallback? onClose;
  final Color? bgColor;
  final double? size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return CustomIconBtn(
      onTap: onClose ?? () => Navigator.of(context).pop(),
      svg: Icon(
        Icons.close_rounded,
        size: (size ?? 30) * 0.55,
        color: iconColor ?? Constants.instance.grey700,
      ),
      bgColor: bgColor ?? Constants.instance.grey100,
      height: size ?? 30,
      width: size ?? 30,
      radius: size ?? 30,
      padding: const EdgeInsets.all(5),
      color: iconColor ?? Constants.instance.black,
    );
  }
}
