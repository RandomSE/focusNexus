import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/widgets/reward_types_multi_select.dart';

void main() {
  testWidgets('reward types subtitle scales from user textStyle', (tester) async {
    const base = TextStyle(fontSize: 20, color: Colors.black);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RewardTypesMultiSelect(
            selected: const ['Mini-games'],
            onChanged: (_) {},
            textStyle: base,
            activeColor: Colors.teal,
            subtitle: 'Enable one or more. At least one must stay on.',
          ),
        ),
      ),
    );

    final subtitle = tester.widget<Text>(
      find.text('Enable one or more. At least one must stay on.'),
    );
    expect(subtitle.style?.fontSize, closeTo(17.0, 0.01));
  });
}
