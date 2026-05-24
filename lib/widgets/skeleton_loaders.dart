import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/utils/screen_theme.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/utils/user_prefs_codec.dart';

/// Default scaffold fill before settings are applied (light preset).
const Color kDefaultScaffoldColor = Color(0xFFF2EFE6);

Color resolveScaffoldBackground([UserPrefsSnapshot? snapshot]) {
  final snap = snapshot ?? AppRepositories.instance.settings.snapshot;
  return ThemeStyles.resolveSecondaryColor(
    isDark: snap.isDark,
    highContrast: snap.highContrastMode,
    prefs: snap,
  );
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    required this.background,
    required this.foreground,
    this.height = 16,
    this.width,
    this.borderRadius = 8,
  });

  final Color background;
  final Color foreground;
  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Themed scaffold with placeholder blocks (no spinner).
class ThemedSkeletonScaffold extends StatelessWidget {
  const ThemedSkeletonScaffold({
    super.key,
    this.title,
    this.child,
    this.bundle,
  });

  final String? title;
  final Widget? child;
  final ThemeBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final live = bundle ??
        (AppRepositories.instance.settings.isLoaded
            ? currentThemeBundle()
            : null);
    final bg = live?.secondaryColor ?? resolveScaffoldBackground();
    final fg = live?.primaryColor ?? Colors.black87;
    final shimmer = fg.withValues(alpha: 0.25);

    return Scaffold(
      backgroundColor: bg,
      appBar: title != null
          ? AppBar(
              backgroundColor: bg,
              title: SkeletonBlock(
                background: bg,
                foreground: shimmer,
                height: 22,
                width: 160,
              ),
            )
          : null,
      body: child ??
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SkeletonBlock(background: bg, foreground: shimmer, height: 48),
              const SizedBox(height: 16),
              for (var i = 0; i < 6; i++) ...[
                SkeletonBlock(background: bg, foreground: shimmer, height: 52),
                const SizedBox(height: 12),
              ],
            ],
          ),
    );
  }
}

class SettingsListSkeleton extends StatelessWidget {
  const SettingsListSkeleton({super.key, required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final bg = bundle.secondaryColor;
    final fg = bundle.primaryColor.withValues(alpha: 0.25);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonBlock(background: bg, foreground: fg, height: 40),
        const SizedBox(height: 16),
        for (var i = 0; i < 8; i++) ...[
          SkeletonBlock(background: bg, foreground: fg, height: 56),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key, required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final bg = bundle.secondaryColor;
    final fg = bundle.primaryColor.withValues(alpha: 0.25);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonBlock(background: bg, foreground: fg, height: 28, width: 120),
        const SizedBox(height: 60),
        for (var i = 0; i < 5; i++) ...[
          SkeletonBlock(background: bg, foreground: fg, height: 52),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class GoalsSkeleton extends StatelessWidget {
  const GoalsSkeleton({super.key, required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final bg = bundle.secondaryColor;
    final fg = bundle.primaryColor.withValues(alpha: 0.25);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonBlock(background: bg, foreground: fg, height: 48),
        const SizedBox(height: 12),
        SkeletonBlock(background: bg, foreground: fg, height: 120),
        const SizedBox(height: 16),
        for (var i = 0; i < 4; i++) ...[
          SkeletonBlock(background: bg, foreground: fg, height: 72),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class OnboardingSkeleton extends StatelessWidget {
  const OnboardingSkeleton({super.key, required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final bg = bundle.secondaryColor;
    final fg = bundle.primaryColor.withValues(alpha: 0.25);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SkeletonBlock(
              background: bg,
              foreground: fg,
              height: double.infinity,
              borderRadius: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBlock(background: bg, foreground: fg, height: 44, width: 90),
              SkeletonBlock(background: bg, foreground: fg, height: 44, width: 90),
              SkeletonBlock(background: bg, foreground: fg, height: 44, width: 70),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomizationSkeleton extends StatelessWidget {
  const CustomizationSkeleton({super.key, required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    final bg = bundle.secondaryColor;
    final fg = bundle.primaryColor.withValues(alpha: 0.25);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonBlock(background: bg, foreground: fg, height: 48),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            8,
            (_) => SkeletonBlock(
              background: bg,
              foreground: fg,
              height: 48,
              width: 48,
              borderRadius: 24,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SkeletonBlock(background: bg, foreground: fg, height: 100),
      ],
    );
  }
}
