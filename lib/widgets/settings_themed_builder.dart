import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/repositories/app_repositories.dart';

typedef SettingsThemedWidgetBuilder = Widget Function(
  BuildContext context,
  ThemeBundle bundle,
);

/// Rebuilds when [AppSettings] changes; derives [ThemeBundle] from the live snapshot.
class SettingsThemedBuilder extends StatefulWidget {
  const SettingsThemedBuilder({
    super.key,
    required this.builder,
    this.startupDelay = Duration.zero,
  });

  final SettingsThemedWidgetBuilder builder;
  final Duration startupDelay;

  @override
  State<SettingsThemedBuilder> createState() => _SettingsThemedBuilderState();
}

class _SettingsThemedBuilderState extends State<SettingsThemedBuilder> {
  final _settings = AppRepositories.instance.settings;
  final _theme = AppRepositories.instance.theme;
  bool _delayComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.startupDelay == Duration.zero) {
      _delayComplete = true;
    } else {
      Future<void>.delayed(widget.startupDelay, () {
        if (mounted) setState(() => _delayComplete = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_settings.isLoaded || !_delayComplete) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final bundle = _theme.bundleFromSnapshot(_settings.snapshot);
        return widget.builder(context, bundle);
      },
    );
  }
}
