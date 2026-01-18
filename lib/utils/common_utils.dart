// .../utils/common_utils.dart
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

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
    final loc = location ?? tz.local;
    final parts = hhmm.trim().split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    final now = tz.TZDateTime.now(loc);
    var candidate = tz.TZDateTime(
      loc,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
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
    return DropdownButton<T>(
      value: value,
      dropdownColor: dropdownColor,
      isExpanded: true,
      onChanged: onChanged,
      items:
          options.map((e) {
            final text = displayText != null ? displayText(e) : e.toString();
            return DropdownMenuItem<T>(
              value: e,
              child: Text(
                text,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
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
  }
  ) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      dropdownColor: dropdownColor,
      value: value,
      decoration: InputDecoration(labelText: label, labelStyle: textStyle),
      items:
          options
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(e.toString(), style: textStyle),
                ),
              )
              .toList(),
      style: textStyle,
      onChanged: onChanged,
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
      Color tileColor
  ) {
    return SwitchListTile(title: Text(text, style: textStyle), value: value, onChanged:onChanged,  tileColor: tileColor);
  }

  static Text buildText(String text, TextStyle style) {
    return Text(text, style: style);
  }

  static Widget buildTextField(
      TextEditingController? controller,
      String text,
      TextStyle textStyle, {
      bool hideText = false,
  }) {
    return TextField(
      style: textStyle,
      controller: controller,
      decoration: InputDecoration(labelText: text, labelStyle: textStyle),
      obscureText: hideText
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
    return TextFormField(
      controller: controller,
      style: textStyle,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textStyle,
        filled: filled,
        fillColor: fillColor,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      obscureText: hideText,
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
        SingleChildScrollView? content,
      }) {
    content ??= Text(bodyText, style: textStyle) as SingleChildScrollView?;
    return showDialog<bool>(
      // TODO: Cont here
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(titleText, style: textStyle),
        content: content,
        actions: actions,
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
