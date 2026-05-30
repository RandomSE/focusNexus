import 'package:flutter/material.dart';

/// Whether [style] uses the bundled OpenDyslexic family.
bool usesOpenDyslexic(TextStyle style) => style.fontFamily == 'OpenDyslexic';

double _fontSize(TextStyle style) => style.fontSize ?? 14.0;

double _lineHeight(TextStyle style) => style.height ?? 1.2;

/// Extra space below form rows so tall dyslexia labels/values do not overlap.
double formFieldBottomSpacing(TextStyle style) {
  if (!usesOpenDyslexic(style)) return 0;
  return _fontSize(style) * _lineHeight(style) * 0.65;
}

/// Minimum height for text fields and dropdown fields (label above + value).
double formFieldMinHeight(TextStyle style) {
  final size = _fontSize(style);
  final line = _lineHeight(style);
  final dyslexia = usesOpenDyslexic(style);
  if (!dyslexia) return kMinInteractiveDimension;
  // Label is outside the box; room for value + padding (and optional multiline input).
  return (size * line * 2.8 + 20).clamp(64.0, 140.0);
}

/// Closed dropdown button height (must fit wrapped selected value).
double dropdownButtonClosedHeight(TextStyle style) {
  final size = _fontSize(style);
  final line = _lineHeight(style);
  final dyslexia = usesOpenDyslexic(style);
  if (!dyslexia) return kMinInteractiveDimension;
  return (size * line * 3 + 32).clamp(80.0, 220.0);
}

/// Dropdown menu row height.
double dropdownItemHeight(TextStyle style) {
  final size = _fontSize(style);
  final line = _lineHeight(style);
  final dyslexia = usesOpenDyslexic(style);
  if (!dyslexia) return kMinInteractiveDimension;
  return dropdownButtonClosedHeight(style);
}

EdgeInsets formFieldContentPadding(TextStyle style, {bool isDropdown = false}) {
  final size = _fontSize(style);
  final dyslexia = usesOpenDyslexic(style);
  if (isDropdown && !dyslexia) {
    // Room below the floating label so the value can sit vertically centered.
    return EdgeInsets.fromLTRB(12, size * 0.65, 12, size * 0.35);
  }
  final vertical = dyslexia ? size * 0.45 : size * 0.3;
  return EdgeInsets.symmetric(horizontal: 12, vertical: vertical);
}

/// Vertical alignment for the closed dropdown value.
AlignmentGeometry formDropdownSelectedAlignment(TextStyle style) {
  if (usesOpenDyslexic(style)) return AlignmentDirectional.topStart;
  return AlignmentDirectional.centerStart;
}

FloatingLabelBehavior formFloatingLabelBehavior(TextStyle style) {
  // Dyslexia labels are rendered above the field via [labeledFormField].
  if (usesOpenDyslexic(style)) return FloatingLabelBehavior.never;
  return FloatingLabelBehavior.auto;
}

Widget? formLabelWidget(String? label, TextStyle textStyle) {
  if (label == null || label.isEmpty) return null;
  final dyslexia = usesOpenDyslexic(textStyle);
  return Text(
    label,
    style: textStyle,
    maxLines: dyslexia ? 4 : 1,
    softWrap: true,
    overflow: dyslexia ? TextOverflow.visible : TextOverflow.ellipsis,
  );
}

InputDecoration formInputDecoration({
  required String? label,
  required TextStyle textStyle,
  Color? fillColor,
  bool filled = false,
  bool isDropdown = false,
}) {
  final dyslexia = usesOpenDyslexic(textStyle);
  final minHeight = isDropdown && dyslexia
      ? dropdownButtonClosedHeight(textStyle)
      : formFieldMinHeight(textStyle);
  return InputDecoration(
    labelText: dyslexia ? null : label,
    labelStyle: dyslexia ? null : textStyle,
    floatingLabelStyle: dyslexia ? null : textStyle,
    floatingLabelBehavior: formFloatingLabelBehavior(textStyle),
    alignLabelWithHint: !dyslexia,
    isDense: false,
    contentPadding: formFieldContentPadding(textStyle, isDropdown: isDropdown),
    constraints: BoxConstraints(minHeight: minHeight),
    border: const OutlineInputBorder(),
    filled: filled,
    fillColor: fillColor,
  );
}

/// Outlines list rows so adjacent template entries stay visually distinct.
Widget outlinedFormRow(Widget child, TextStyle textStyle) {
  final size = _fontSize(textStyle);
  final borderColor = textStyle.color ?? Colors.black87;
  return Padding(
    padding: EdgeInsets.only(bottom: size * 0.2),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    ),
  );
}

/// Wraps a form control with dyslexia-friendly vertical spacing.
Widget wrapFormField(Widget child, TextStyle textStyle) {
  final gap = formFieldBottomSpacing(textStyle);
  if (gap <= 0) return child;
  return Padding(
    padding: EdgeInsets.only(bottom: gap),
    child: child,
  );
}

/// Puts the label above the control when dyslexia is on (avoids in-field clipping).
Widget labeledFormField({
  required String? label,
  required TextStyle textStyle,
  required Widget field,
}) {
  final dyslexia = usesOpenDyslexic(textStyle);
  if (!dyslexia || label == null || label.isEmpty) {
    return wrapFormField(field, textStyle);
  }
  final size = _fontSize(textStyle);
  return wrapFormField(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        formLabelWidget(label, textStyle)!,
        SizedBox(height: size * 0.2),
        field,
      ],
    ),
    textStyle,
  );
}

/// Selected value / menu item text (no ellipsis when dyslexia is on).
Widget formFieldText(String text, TextStyle style, {bool selected = false}) {
  final dyslexia = usesOpenDyslexic(style);
  return Text(
    text,
    style: style,
    maxLines: dyslexia ? (selected ? null : 3) : 1,
    softWrap: true,
    overflow: dyslexia ? TextOverflow.visible : TextOverflow.ellipsis,
  );
}

/// Closed dropdown selected value (top-aligned when dyslexia wraps text).
Widget formDropdownSelectedValue(String text, TextStyle style) {
  return SizedBox(
    width: double.infinity,
    child: Align(
      alignment: formDropdownSelectedAlignment(style),
      child: formFieldText(text, style, selected: true),
    ),
  );
}

/// Menu item for dropdown lists.
Widget formMenuItemText(String text, TextStyle style) {
  return Padding(
    padding: EdgeInsets.symmetric(
      vertical: usesOpenDyslexic(style) ? 8 : 0,
    ),
    child: formFieldText(text, style),
  );
}
