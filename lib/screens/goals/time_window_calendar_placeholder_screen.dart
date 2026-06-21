import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';

class TimeWindowCalendarPlaceholderScreen extends ConsumerWidget {
  const TimeWindowCalendarPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(themeBundleProvider);
    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        backgroundColor: bundle.secondaryColor,
        appBar: AppBar(
          title: Text('Calendar create', style: bundle.textStyle),
          backgroundColor: bundle.secondaryColor,
          iconTheme: IconThemeData(color: bundle.primaryColor),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Create from calendar is coming soon.',
              style: bundle.textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
