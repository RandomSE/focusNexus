import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/common_utils.dart';

void main() {
  testWidgets('showSnackBar wraps long text at font size 24', (tester) async {
    const style = TextStyle(fontSize: 24, fontFamily: 'OpenDyslexic');
    const message =
        'Please fill or fix: Goal Title, Time Required in minutes, and Steps.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  CommonUtils.showSnackBar(
                    context,
                    message,
                    style,
                    4000,
                    12,
                  );
                },
                child: const Text('go'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();

    final text = tester.widget<Text>(find.text(message));
    expect(text.softWrap, isTrue);
    expect(text.maxLines, greaterThanOrEqualTo(4));
    expect(text.overflow, TextOverflow.visible);
    expect(tester.takeException(), isNull);
  });
}
