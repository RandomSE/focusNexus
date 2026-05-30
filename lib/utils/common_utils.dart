// .../utils/common_utils.dart
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'form_field_metrics.dart';
import 'notification_schedule_utils.dart';

class CommonUtils {

  static Color getDefaultPrimaryColor() {
    return Colors.black87;

  }

  static Color getDefaultSecondaryColor() {
    return Colors.white70;
  }

  static TextStyle getDefaultTextStyle() {
      return TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: getDefaultPrimaryColor()
      );
  }

  static Future<void> waitForMilliseconds(int milliseconds) async {
    // Mostly use seconds, but this is more dynamic (as there are areas I use < 1 second)
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  static tz.TZDateTime newTimeMinusHours(tz.TZDateTime time, int hours) {
    return time.subtract(Duration(hours: hours));
  }

  static Future<tz.TZDateTime?> tzDateTimeFromHHmm(
    String hhmm, {
    tz.Location? location,
  }) async {
    if (NotificationScheduleUtils.parseClock(hhmm.trim()) == null) {
      return null;
    }
    return NotificationScheduleUtils.nextTriggerFromHHmm(
      NotificationScheduleUtils.normalizeHHmm(hhmm),
      location: location,
    );
  }

  static int scoreFromLevel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 1;
      default:
        return 0;
    }
  }

  static int scoreFromTime(int minutes) {
    if (minutes >= 600) return 5;
    if (minutes >= 300) return 4;
    if (minutes >= 150) return 3;
    if (minutes >= 90) return 2;
    if (minutes >= 30) return 1;
    return 0;
  }

  static int scoreFromSteps(int steps) {
    if (steps >= 50) return 5;
    if (steps >= 25) return 4;
    if (steps >= 15) return 3;
    if (steps >= 8) return 2;
    if (steps > 3) return 1;
    return 0;
  }

  static Widget buildCenteredButton(
      BuildContext context,
        String label,
        VoidCallback onPressed,
        TextStyle style,
        Color backgroundColor,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
            ),
            child: Text(label, style: style, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  static Widget buildDropdownButton<T>(
    T value,
    List<T> options,
    TextStyle textStyle,
    Color dropdownColor,
    ValueChanged<T?> onChanged, {
    String Function(T)? displayText,
  }) {
    final itemLabels = options
        .map((e) => displayText != null ? displayText(e) : e.toString())
        .toList();

    return wrapFormField(
      DropdownButton<T>(
        value: value,
        dropdownColor: dropdownColor,
        isExpanded: true,
        itemHeight: dropdownItemHeight(textStyle),
        onChanged: onChanged,
        selectedItemBuilder: (context) {
          return itemLabels
              .map((text) => formDropdownSelectedValue(text, textStyle))
              .toList();
        },
        items: options.map((e) {
          final text = displayText != null ? displayText(e) : e.toString();
          return DropdownMenuItem<T>(
            value: e,
            child: formMenuItemText(text, textStyle),
          );
        }).toList(),
      ),
      textStyle,
    );
  }

  static Widget buildDropdownButtonFormField<T>(
    String label,
    T value,
    List<T> options,
    TextStyle textStyle,
    Color dropdownColor,
    ValueChanged<T?> onChanged, {
    String? Function(String?)? validator,
    String Function(T)? displayText,
  }) {
    final itemLabels = options
        .map((e) => displayText != null ? displayText(e) : e.toString())
        .toList();

    return labeledFormField(
      label: label,
      textStyle: textStyle,
      field: DropdownButtonFormField<T>(
        isExpanded: true,
        isDense: false,
        dropdownColor: dropdownColor,
        value: value,
        itemHeight: dropdownButtonClosedHeight(textStyle),
        decoration: formInputDecoration(
          label: label,
          textStyle: textStyle,
          isDropdown: true,
        ),
        selectedItemBuilder: (context) {
          return itemLabels
              .map((text) => formDropdownSelectedValue(text, textStyle))
              .toList();
        },
        items: options
            .map(
              (e) => DropdownMenuItem<T>(
                value: e,
                child: formMenuItemText(
                  displayText != null ? displayText(e) : e.toString(),
                  textStyle,
                ),
              ),
            )
            .toList(),
        style: textStyle,
        onChanged: onChanged,
      ),
    );
  }

  static ElevatedButton buildElevatedButton(
      String text,
      Color primaryColor,
      Color secondaryColor,
      TextStyle textStyle,
      double paddingPixels,
      double radius,
      VoidCallback? onPressed, //  nullable, for conditional buttons.
      ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(vertical: paddingPixels),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: Text(text, style: textStyle),
    );
  }

  static Widget buildSwitch(
      bool value,
      void Function(bool)? onChanged,
      Color color
      ) {
    return Switch(value: value, onChanged: onChanged, activeColor: color);
  }

  static Widget buildSwitchListTile(
    String text,
    TextStyle textStyle,
    bool value,
    void Function(bool)? onChanged,
    Color tileColor, {
    bool dense = false,
    int titleMaxLines = 1,
  }) {
    final dyslexia = usesOpenDyslexic(textStyle);
    return SwitchListTile(
      dense: dyslexia ? false : dense,
      contentPadding: dyslexia
          ? EdgeInsets.symmetric(
              vertical: (textStyle.fontSize ?? 14) * 0.2,
            )
          : (dense ? EdgeInsets.zero : null),
      title: Text(
        text,
        style: textStyle,
        maxLines: dyslexia ? 4 : titleMaxLines,
        softWrap: true,
        overflow: dyslexia ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: tileColor,
    );
  }

  static Text buildText(String text, TextStyle style) {
    return Text(text, style: style);
  }

  static Widget buildListTile({
    required String title,
    required TextStyle textStyle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final dyslexia = usesOpenDyslexic(textStyle);
    final size = textStyle.fontSize ?? 14;
    return outlinedFormRow(
      ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: dyslexia ? size * 0.15 : 0,
        ),
        minVerticalPadding: dyslexia ? size * 0.35 : 12,
        title: Text(
          title,
          style: textStyle,
          maxLines: dyslexia ? 3 : 1,
          softWrap: true,
          overflow: dyslexia ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        trailing: trailing,
        onTap: onTap,
      ),
      textStyle,
    );
  }

  static Widget buildCheckboxListTile({
    required String title,
    required TextStyle textStyle,
    required bool value,
    required Color activeColor,
    required Color checkColor,
    required ValueChanged<bool?>? onChanged,
  }) {
    final dyslexia = usesOpenDyslexic(textStyle);
    return outlinedFormRow(
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          title,
          style: textStyle,
          maxLines: dyslexia ? 4 : 1,
          softWrap: true,
          overflow: dyslexia ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        value: value,
        activeColor: activeColor,
        checkColor: checkColor,
        onChanged: onChanged,
      ),
      textStyle,
    );
  }

  static Widget buildTextField(
      TextEditingController? controller,
      String text,
      TextStyle textStyle, {
      bool hideText = false,
  }) {
    return labeledFormField(
      label: text,
      textStyle: textStyle,
      field: TextField(
        style: textStyle,
        controller: controller,
        decoration: formInputDecoration(label: text, textStyle: textStyle),
        obscureText: hideText,
        minLines: usesOpenDyslexic(textStyle) ? 1 : null,
        maxLines: usesOpenDyslexic(textStyle) ? 3 : 1,
      ),
    );
  }

  static Widget buildTextFormField(
    TextEditingController? controller,
    String? label,
    TextStyle? textStyle,
    Color? fillColor,
    bool filled,
    String? Function(String?)? validator, {
    bool hideText = false,
    TextInputType? keyboardType,
  }) {
    keyboardType ??= TextInputType.text;
    final fieldStyle = textStyle ?? getDefaultTextStyle();
    return labeledFormField(
      label: label,
      textStyle: fieldStyle,
      field: TextFormField(
        controller: controller,
        style: fieldStyle,
        keyboardType: keyboardType,
        decoration: formInputDecoration(
          label: label,
          textStyle: fieldStyle,
          filled: filled,
          fillColor: fillColor,
        ),
        validator: validator,
        obscureText: hideText,
        minLines: usesOpenDyslexic(fieldStyle) ? 1 : null,
        maxLines: usesOpenDyslexic(fieldStyle) ? 3 : 1,
      ),
    );
  }

  static Widget buildTextButton(
    VoidCallback? onPressed,
    String text,
    TextStyle textStyle,
  ) {
    return TextButton(
      onPressed: onPressed,
      child: Text(text, style: textStyle),
    );
  }

  static Widget buildIconButton(
      String tooltipText,
      IconData icon,
      Color color,
      VoidCallback? onPressed,
      ) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color), tooltip: tooltipText,
    );
  }



  static void showBasicAlertDialog(
      BuildContext context,
      String titleText,
      String bodyText,
      TextStyle textStyle,
      Color backgroundColor,
      ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(titleText, style: textStyle),
        content: Text(bodyText, style: textStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: textStyle),
          ),

        ],
      ),
    );
  }

  static Future<bool?> showInteractableAlertDialog(
      BuildContext context,
      String titleText,
      String bodyText,
      TextStyle textStyle,
      Color backgroundColor, {
        List<Widget>? actions,
        Widget? content,
        bool barrierDismissible = true,
      }) {
    content ??= SingleChildScrollView(
      child: Text(bodyText, style: textStyle),
    );
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => PopScope(
        canPop: barrierDismissible,
        child: AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(titleText, style: textStyle),
        content: content,
        actions: actions,
        ),
      ),
    );
  }


  static void showDialogWidget(
      BuildContext context,
      String titleText,
      TextStyle textStyle,
      Color backgroundColor,
      ) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
        backgroundColor: backgroundColor,
        child: Text(
          '$titleText Click anywhere to close this pop-up.',
          style: textStyle,
        ),
      ),
    );
  }

  static void showSnackBar(
      BuildContext context,
      String text,
      TextStyle textStyle,
      int durationMilliseconds,
      int margin,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: textStyle),
        duration: Duration(milliseconds: durationMilliseconds),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(margin.toDouble()),
      ),
    );
  }

}
