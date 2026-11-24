import 'package:flutter/material.dart';
import '../constants/constant.dart';
import '../helper/app_text_style.dart';
import 'custom_rich_text.dart';

class CustomDropdownBtn<T> extends StatelessWidget {
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final Widget? hint;
  final String? hintText, label;
  final double? btnWidth, btnHeight, dropDownMaxHeight;
  final bool isRequiredMark;
  final TextStyle? labelStyle;
  final BoxDecoration? btnDecoration;
  final EdgeInsetsGeometry? contentPadding;
  final bool isExpanded;
  final Widget? icon;

  const CustomDropdownBtn({
    super.key,
    required this.items,
    this.onChanged,
    this.value,
    this.hint,
    this.hintText,
    this.btnWidth,
    this.btnHeight,
    this.dropDownMaxHeight,
    this.label,
    this.labelStyle,
    this.isRequiredMark = false,
    this.btnDecoration,
    this.contentPadding,
    this.isExpanded = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = Container(
      width: btnWidth,
      height: btnHeight,
      padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: btnDecoration ??
          BoxDecoration(
            color: Constants.instance.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Constants.instance.primary, width: 1.2),
          ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: isExpanded,
          menuMaxHeight: dropDownMaxHeight ?? 380,
          dropdownColor: Constants.instance.white,
          borderRadius: BorderRadius.circular(10),
          icon: icon ??
              Icon(
                Icons.arrow_drop_down,
                color: Constants.instance.primary,
                size: 20,
              ),
          hint: hint ??
              (hintText != null
                  ? Text(
                      hintText!,
                      style: AppTextStyle.regular.copyWith(
                        fontSize: 12.5,
                        color: Constants.instance.grey500,
                      ),
                    )
                  : null),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );

    if (label == null) {
      return dropdown;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: CustomRichText(
            text1: "$label",
            text2: isRequiredMark ? "*" : null,
            style: labelStyle ??
                AppTextStyle.medium.copyWith(
                  fontSize: 13,
                  color: Constants.instance.black,
                ),
            style2: AppTextStyle.medium.copyWith(
              fontSize: 17,
              height: 0.5,
              color: Constants.instance.red,
            ),
          ),
        ),
        dropdown,
      ],
    );
  }
}
