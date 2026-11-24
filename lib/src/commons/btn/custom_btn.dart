import 'package:flutter/material.dart';
import '../../helper/app_extensions.dart';
import '../../constants/constant.dart';
import '../../helper/app_text_style.dart';
import '../custom_loading_indicator.dart';

class CustomBtn extends StatelessWidget {
  final double? width, height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? style;
  final GestureTapCallback? onTap;
  final Widget? prefix, suffix;
  final double prefixDistance, suffixDistance, radius, borderWidth;
  final String? text;
  final Color? bgColor, borderColor, loadingIndicatorColor;
  final bool isLoading;
  final Widget? child;
  const CustomBtn({
    super.key,
    this.width,
    this.height,
    this.onTap,
    this.padding,
    this.style,
    this.prefix,
    this.suffix,
    this.prefixDistance = 10,
    this.suffixDistance = 10,
    this.radius = 6,
    this.borderWidth = 1.8,
    this.text,
    this.child,
    this.bgColor,
    this.borderColor,
    this.isLoading = false,
    this.loadingIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 40,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          padding: padding ?? const EdgeInsets.only(left: 15, right: 15, top: 8, bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: borderColor ?? Constants.instance.primary, width: borderWidth),
          ),
          backgroundColor: bgColor ?? Constants.instance.primary,
          disabledBackgroundColor: (bgColor ?? Constants.instance.primary).withAlpha(128),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        child: isLoading
            ? CustomLoadingIndicator(color: loadingIndicatorColor ?? Constants.instance.white)
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefix != null) ...[prefix!, Constants.instance.square.copyWith(height: 0, width: prefixDistance)],
                  Flexible(
                    child: child ??
                        Text(
                          text ?? "Save",
                          style: style ?? AppTextStyle.bold.copyWith(fontSize: 14, color: Constants.instance.white),
                        ),
                  ),
                  if (suffix != null) ...[Constants.instance.square.copyWith(height: 0, width: suffixDistance), suffix!],
                ],
              ),
      ),
    );
  }
}
