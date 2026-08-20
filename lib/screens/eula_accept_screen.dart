import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/legal/legal_documents.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/legal_links_section.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Re-acceptance gate when the stored EULA version is outdated.
class EulaAcceptScreen extends ConsumerStatefulWidget {
  const EulaAcceptScreen({super.key});

  @override
  ConsumerState<EulaAcceptScreen> createState() => _EulaAcceptScreenState();
}

class _EulaAcceptScreenState extends ConsumerState<EulaAcceptScreen> {
  bool _accepted = false;
  bool _ageConfirmed = false;
  bool _busy = false;

  void _onContinuePressed(TextStyle textStyle) {
    if (_busy) return;
    if (!_accepted || !_ageConfirmed) {
      CommonUtils.showSnackBar(
        context,
        !_accepted
            ? 'Please agree to the End User License Agreement, Privacy Policy, and Intellectual Property notice to continue.'
            : 'Please confirm you are 13 or older to continue.',
        textStyle.copyWith(fontWeight: FontWeight.normal),
        4000,
        16,
      );
      return;
    }
    unawaited(_continue(textStyle));
  }

  Future<void> _continue(TextStyle textStyle) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final settings = ref.read(appSettingsProvider.notifier).service;
      await settings.acceptCurrentEula();
      if (!mounted) return;
      ref.resetToRoute(context, AppRouteGuard.initialFor(settings));
    } catch (_) {
      if (!mounted) return;
      CommonUtils.showSnackBar(
        context,
        'Could not save acceptance. Please try again.',
        textStyle.copyWith(fontWeight: FontWeight.normal),
        4000,
        16,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final textStyle = bundle.textStyle;
        final primaryColor = bundle.primaryColor;
        final secondaryColor = bundle.secondaryColor;
        final canTapContinue = _accepted && _ageConfirmed && !_busy;

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: secondaryColor,
            appBar: AppBar(
              title: Text('Updated terms', style: textStyle),
              backgroundColor: secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor(primaryColor),
              automaticallyImplyLeading: false,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'FocusNexus requires acceptance of the current End User '
                  'License Agreement (version $kLegalDocsVersion) before you continue.',
                  style: textStyle.copyWith(fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 16),
                LegalLinksSection.buttons(
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  textStyle: textStyle,
                  eulaButtonLabel: 'Read End User License Agreement',
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _accepted,
                  activeColor: primaryColor,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I have read and agree to the End User License '
                        'Agreement, Privacy Policy, and Intellectual Property notice:',
                        style: textStyle.copyWith(fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(height: 4),
                      LegalLinksSection.textLinks(
                        linkStyle: textStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: primaryColor,
                        ),
                        includeEula: true,
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _accepted = value ?? false),
                ),
                CheckboxListTile(
                  value: _ageConfirmed,
                  activeColor: primaryColor,
                  title: Text(
                    'I confirm I am 13 or older',
                    style: textStyle.copyWith(fontWeight: FontWeight.normal),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: _busy
                      ? null
                      : (value) =>
                          setState(() => _ageConfirmed = value ?? false),
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: canTapContinue ? 1.0 : 0.55,
                  child: CommonUtils.buildElevatedButton(
                    'Continue',
                    primaryColor,
                    secondaryColor,
                    textStyle,
                    12,
                    8,
                    canTapContinue
                        ? () => _onContinuePressed(textStyle)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
