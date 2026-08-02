import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/widgets/mini_game_hud_chrome.dart';
import 'package:focusNexus/widgets/mini_game_themed_hud.dart';

void main() {
  ThemeBundle bundle({String? fontFamily}) {
    return ThemeBundle(
      themeData: ThemeData.dark(),
      textStyle: TextStyle(
        inherit: false,
        color: Colors.white,
        fontSize: 24,
        fontFamily: fontFamily,
      ),
      primaryColor: const Color(0xFFFFB7C5),
      secondaryColor: const Color(0xFF0A0F18),
      accentColor: const Color(0xFFFFB7C5),
      buttonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(const Color(0xFFFFB7C5)),
      ),
    );
  }

  testWidgets('topBar shows score label timer and back', (tester) async {
    final hud = MiniGameThemedHud(bundle(fontFamily: 'OpenDyslexic'));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              MiniGameHudChrome.topBar(
                hud: hud,
                onBack: () {},
                center: MiniGameHudChrome.scoreColumn(
                  hud: hud,
                  label: 'Score',
                  value: '12',
                  streakLabel: 'Streak',
                  streakValue: '2',
                ),
                timerLabel: '90s',
                onEnd: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Score'), findsOneWidget);
    expect(find.text('12'), findsWidgets);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('90s'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    final screenWidth = tester.getSize(find.byType(Scaffold)).width;
    final scoreCenter = tester.getCenter(find.text('Score'));
    final timerLeft = tester.getTopLeft(find.text('90s')).dx;
    expect(scoreCenter.dx, closeTo(screenWidth / 2, 48));
    expect(timerLeft, greaterThan(screenWidth * 0.55));
  });

  testWidgets('endScoreBody shows title value and Done', (tester) async {
    final hud = MiniGameThemedHud(bundle());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniGameHudChrome.endScoreBody(
            hud: hud,
            title: 'Score',
            value: '42',
            secondaryLabel: 'Streak',
            secondaryValue: '3',
            onDone: () {},
          ),
        ),
      ),
    );

    expect(find.text('Score'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
