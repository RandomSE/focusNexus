import 'package:url_launcher/url_launcher.dart';

/// Injectable launcher for unit tests (no network / platform channel).
typedef ExternalUrlLauncher = Future<bool> Function(
  Uri uri, {
  LaunchMode mode,
});

/// Opens [url] in an external browser/app.
///
/// Returns `false` for invalid schemes, launcher failure, or thrown errors.
Future<bool> openExternalUrl(
  String url, {
  ExternalUrlLauncher? launcher,
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return false;
  }

  final launch = launcher ??
      ((Uri u, {LaunchMode mode = LaunchMode.platformDefault}) =>
          launchUrl(u, mode: mode));

  try {
    return await launch(uri, mode: mode);
  } catch (_) {
    return false;
  }
}
