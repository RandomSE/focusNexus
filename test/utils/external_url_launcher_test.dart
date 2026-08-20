import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/external_url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('openExternalUrl launches with externalApplication by default', () async {
    Uri? capturedUri;
    LaunchMode? capturedMode;
    final ok = await openExternalUrl(
      'https://discord.gg/aHUgcbdvr',
      launcher: (uri, {mode = LaunchMode.platformDefault}) async {
        capturedUri = uri;
        capturedMode = mode;
        return true;
      },
    );
    expect(ok, isTrue);
    expect(capturedUri, Uri.parse('https://discord.gg/aHUgcbdvr'));
    expect(capturedMode, LaunchMode.externalApplication);
  });

  test('openExternalUrl returns false when launcher fails', () async {
    final ok = await openExternalUrl(
      'https://discord.gg/aHUgcbdvr',
      launcher: (uri, {mode = LaunchMode.platformDefault}) async => false,
    );
    expect(ok, isFalse);
  });

  test('openExternalUrl returns false when launcher throws', () async {
    final ok = await openExternalUrl(
      'https://discord.gg/aHUgcbdvr',
      launcher: (uri, {mode = LaunchMode.platformDefault}) async {
        throw StateError('no handler');
      },
    );
    expect(ok, isFalse);
  });

  test('openExternalUrl rejects non-http(s) schemes', () async {
    var called = false;
    final ok = await openExternalUrl(
      'file:///tmp/x',
      launcher: (uri, {mode = LaunchMode.platformDefault}) async {
        called = true;
        return true;
      },
    );
    expect(ok, isFalse);
    expect(called, isFalse);
  });
}
