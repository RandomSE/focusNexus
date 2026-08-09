import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/widgets/section_title_actions.dart';

void main() {
  testWidgets('title stays wide beside large-font actions', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const style = TextStyle(fontSize: 24, color: Colors.black);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SectionTitleActions(
              title: 'Active queue',
              titleStyle: style,
              actions: [
                Text('Build set', style: style),
                Text('Save preset', style: style),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.text('Active queue'));
    expect(size.height, lessThan(72));
    expect(size.width, greaterThan(80));
  });
}
