import 'package:flutter/material.dart';
import 'package:focusNexus/goals/dashboard_goals_label.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/screens/onboarding/onboarding_live_stats.dart';

/// Ordered onboarding story beats (programmatic slides, not static screenshots).
enum OnboardingSlideId {
  welcome,
  dashboard,
  goals,
  timeSlots,
  zenGarden,
  rewards,
  personalize,
}

const List<OnboardingSlideId> kOnboardingSlides = OnboardingSlideId.values;

Widget buildOnboardingSlide({
  required OnboardingSlideId id,
  required ThemeBundle bundle,
  required OnboardingLiveStats stats,
}) {
  return _OnboardingSlideFrame(
    bundle: bundle,
    child: switch (id) {
      OnboardingSlideId.welcome => _WelcomeSlide(bundle: bundle),
      OnboardingSlideId.dashboard => _DashboardSlide(bundle: bundle, stats: stats),
      OnboardingSlideId.goals => _GoalsSlide(bundle: bundle),
      OnboardingSlideId.timeSlots => _TimeSlotsSlide(bundle: bundle),
      OnboardingSlideId.zenGarden => _ZenGardenSlide(bundle: bundle),
      OnboardingSlideId.rewards => _RewardsSlide(bundle: bundle),
      OnboardingSlideId.personalize => _PersonalizeSlide(bundle: bundle),
    },
  );
}

/// Full-height slide shell; body scrolls when font size / dyslexia type needs more room.
class _OnboardingSlideFrame extends StatelessWidget {
  const _OnboardingSlideFrame({
    required this.bundle,
    required this.child,
  });

  final ThemeBundle bundle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bundle.accentColor.withValues(alpha: 0.22),
            bundle.secondaryColor,
            Color.alphaBlend(
              bundle.primaryColor.withValues(alpha: 0.06),
              bundle.secondaryColor,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                height: constraints.maxHeight,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingSlideScaffold extends StatelessWidget {
  const _OnboardingSlideScaffold({
    required this.header,
    required this.children,
  });

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SlideHeader extends StatelessWidget {
  const _SlideHeader({
    required this.bundle,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ThemeBundle bundle;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final baseSize = bundle.textStyle.fontSize ?? 16;
    final titleStyle = bundle.textStyle.copyWith(
      fontSize: baseSize + 4,
      fontWeight: FontWeight.w800,
      height: 1.25,
    );
    final subtitleStyle = bundle.textStyle.copyWith(
      height: 1.35,
      color: bundle.primaryColor.withValues(alpha: 0.88),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 44, color: bundle.accentColor),
        const SizedBox(height: 10),
        Text(title, style: titleStyle, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: subtitleStyle, textAlign: TextAlign.center),
      ],
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard({
    required this.bundle,
    required this.child,
    this.accentBorder = false,
  });

  final ThemeBundle bundle;
  final Widget child;
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          bundle.primaryColor.withValues(alpha: 0.04),
          bundle.secondaryColor,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentBorder
              ? bundle.accentColor.withValues(alpha: 0.85)
              : bundle.primaryColor.withValues(alpha: 0.2),
          width: accentBorder ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: bundle.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide({required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final sample = bundle.textStyle.copyWith(fontWeight: FontWeight.w600);
    return _OnboardingSlideScaffold(
      header: _SlideHeader(
        bundle: bundle,
        icon: Icons.spa_outlined,
        title: 'Welcome to FocusNexus',
        subtitle:
            'A calm space for goals, gentle reminders, and rewards that grow with you.',
      ),
      children: [
        _MockCard(
          bundle: bundle,
          accentBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Your text looks like this', style: sample),
              const SizedBox(height: 8),
              Text(
                'Swipe through to see how FocusNexus fits your day. '
                'On the last slide you can tune font size and style.',
                style: bundle.textStyle.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardSlide extends StatelessWidget {
  const _DashboardSlide({
    required this.bundle,
    required this.stats,
  });

  final ThemeBundle bundle;
  final OnboardingLiveStats stats;

  @override
  Widget build(BuildContext context) {
    final label = bundle.textStyle.copyWith(fontWeight: FontWeight.w700);
    final goalsLabel = dashboardGoalsButtonLabel(stats.activeGoals);
    final inSlotLine = dashboardInSlotLine(stats.goalsInSlotNow);
    return _OnboardingSlideScaffold(
      header: _SlideHeader(
        bundle: bundle,
        icon: Icons.dashboard_outlined,
        title: 'Your dashboard',
        subtitle: 'See points and open Goals, Settings, Achievements, and rewards.',
      ),
      children: [
        _MockCard(
          bundle: bundle,
          child: Row(
            children: [
              Icon(Icons.stars, color: bundle.accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Points: ${stats.points}', style: label),
              ),
            ],
          ),
        ),
        if (inSlotLine != null)
          _MockCard(
            bundle: bundle,
            accentBorder: true,
            child: Text(inSlotLine, style: label),
          ),
        _MockCard(
          bundle: bundle,
          accentBorder: inSlotLine == null,
          child: Text(goalsLabel, style: label, textAlign: TextAlign.center),
        ),
        _MockCard(
          bundle: bundle,
          child: Text(
            'The real dashboard uses the same labels and your live point balance.',
            style: bundle.textStyle.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _GoalsSlide extends StatelessWidget {
  const _GoalsSlide({required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = bundle.textStyle.copyWith(fontWeight: FontWeight.w700);
    final subtle = bundle.textStyle.copyWith(
      fontSize: (bundle.textStyle.fontSize ?? 14) * 0.92,
      color: bundle.primaryColor.withValues(alpha: 0.85),
    );
    return _OnboardingSlideScaffold(
      header: _SlideHeader(
        bundle: bundle,
        icon: Icons.flag_outlined,
        title: 'Goals that fit real life',
        subtitle:
            'Deadline goals, multi-step tasks, templates, and filters keep things manageable.',
      ),
      children: [
        _MockCard(
          bundle: bundle,
          accentBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Example: Morning walk', style: titleStyle),
              const SizedBox(height: 4),
              Text('42 pts · Due Friday 18:00', style: subtle),
            ],
          ),
        ),
        _MockCard(
          bundle: bundle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Example: Read one chapter', style: titleStyle),
              const SizedBox(height: 4),
              Text('Step 2/4 · In progress', style: subtle),
            ],
          ),
        ),
        _MockCard(
          bundle: bundle,
          child: Text(
            'Save templates and bulk-create when you are ready.',
            style: bundle.textStyle.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _TimeSlotsSlide extends StatelessWidget {
  const _TimeSlotsSlide({required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final label = bundle.textStyle.copyWith(fontWeight: FontWeight.w700);
    final subtle = bundle.textStyle.copyWith(
      fontSize: (bundle.textStyle.fontSize ?? 14) * 0.92,
      height: 1.35,
    );
    return _OnboardingSlideScaffold(
      header: _SlideHeader(
        bundle: bundle,
        icon: Icons.schedule_outlined,
        title: 'Time-slot goals',
        subtitle:
            'Act during a window that works for you. Repeating slots spawn the next instance automatically.',
      ),
      children: [
        _MockCard(
          bundle: bundle,
          accentBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Example: Stretch break', style: label),
              const SizedBox(height: 6),
              Text('Slot: 21/6 16:50 - 21/6 18:50', style: subtle),
              Text('In slot now', style: subtle),
              Text('Every 1 day', style: subtle),
            ],
          ),
        ),
        _MockCard(
          bundle: bundle,
          child: Text(
            'Reminders open when a slot starts and before long slots end.',
            style: bundle.textStyle.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _ZenGardenSlide extends StatelessWidget {
  const _ZenGardenSlide({required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlideScaffold(
      header: _SlideHeader(
        bundle: bundle,
        icon: Icons.yard_outlined,
        title: 'Zen garden',
        subtitle:
            'Spend points on plants and decor. Grow them over time and chase rare color variants.',
      ),
      children: [
        SizedBox(
          height: 160,
          child: _MockCard(
            bundle: bundle,
            accentBorder: true,
            child: CustomPaint(
              painter: _ZenGardenTeaserPainter(
                sand: bundle.secondaryColor,
                accent: bundle.accentColor,
                primary: bundle.primaryColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        _MockCard(
          bundle: bundle,
          child: Text(
            '5% rare variant chance, +5% each time you restart growth on an object.',
            style: bundle.textStyle.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _ZenGardenTeaserPainter extends CustomPainter {
  _ZenGardenTeaserPainter({
    required this.sand,
    required this.accent,
    required this.primary,
  });

  final Color sand;
  final Color accent;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final sandPaint = Paint()
      ..color = Color.alphaBlend(primary.withValues(alpha: 0.05), sand);
    canvas.drawRect(Offset.zero & size, sandPaint);

    final rake = Paint()
      ..color = primary.withValues(alpha: 0.12)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.15 + i * 0.12);
      canvas.drawArc(
        Rect.fromLTWH(-size.width * 0.2, y, size.width * 1.4, size.height * 0.2),
        0.1,
        2.9,
        false,
        rake,
      );
    }

    final plant = Paint()..color = accent;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.45), 18, plant);
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.38),
      14,
      plant..color = primary.withValues(alpha: 0.5),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.35, size.height * 0.58),
        width: 8,
        height: 36,
      ),
      Paint()..color = primary.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _ZenGardenTeaserPainter oldDelegate) =>
      sand != oldDelegate.sand ||
      accent != oldDelegate.accent ||
      primary != oldDelegate.primary;
}

class _RewardsSlide extends StatelessWidget {
  const _RewardsSlide({required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final label = bundle.textStyle.copyWith(fontWeight: FontWeight.w700);
    return _OnboardingSlideScaffold(
      header: _SlideHeader(
        bundle: bundle,
        icon: Icons.emoji_events_outlined,
        title: 'Earn, then enjoy',
        subtitle:
            'Complete goals for points. Spend them in the zen garden, mini-games, or customization.',
      ),
      children: [
        _MockCard(
          bundle: bundle,
          child: Row(
            children: [
              Icon(Icons.videogame_asset_outlined, color: bundle.accentColor),
              const SizedBox(width: 10),
              Expanded(child: Text('Mini-games break', style: label)),
            ],
          ),
        ),
        _MockCard(
          bundle: bundle,
          child: Row(
            children: [
              Icon(Icons.palette_outlined, color: bundle.accentColor),
              const SizedBox(width: 10),
              Expanded(child: Text('Theme customization', style: label)),
            ],
          ),
        ),
        _MockCard(
          bundle: bundle,
          accentBorder: true,
          child: Text(
            'Achievements quietly track milestones without pressure.',
            style: bundle.textStyle.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _PersonalizeSlide extends StatelessWidget {
  const _PersonalizeSlide({required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final baseSize = bundle.textStyle.fontSize ?? 16;
    return _OnboardingSlideScaffold(
      header: _SlideHeader(
        bundle: bundle,
        icon: Icons.tune_outlined,
        title: 'Make it yours',
        subtitle:
            'Adjust font size, dyslexia-friendly type, contrast, and dark mode below. '
            'Every slide uses your live settings.',
      ),
      children: [
        _MockCard(
          bundle: bundle,
          accentBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sample heading',
                style: bundle.textStyle.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: baseSize + 2,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This paragraph updates as you change settings. '
                'Comfortable reading is part of staying focused.',
                style: bundle.textStyle.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
