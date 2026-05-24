import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Paths under [onboardingImagesDir] bundled in the app.
const onboardingImagesDir = 'assets/images/onboarding_images/';

const _imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

/// Loads onboarding image asset paths from the asset manifest, sorted by name.
Future<List<String>> loadOnboardingImagePaths() async {
  final manifest =
      json.decode(await rootBundle.loadString('AssetManifest.json'))
          as Map<String, dynamic>;
  final paths =
      manifest.keys
          .where(
            (path) =>
                path.startsWith(onboardingImagesDir) &&
                _imageExtensions.any((ext) => path.toLowerCase().endsWith(ext)),
          )
          .toList()
        ..sort();
  return paths;
}
