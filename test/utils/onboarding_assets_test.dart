import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/onboarding_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadOnboardingImagePaths returns sorted onboarding asset paths', () async {
    final paths = await loadOnboardingImagePaths();
    for (var i = 1; i < paths.length; i++) {
      expect(paths[i].compareTo(paths[i - 1]), greaterThanOrEqualTo(0));
    }
    for (final path in paths) {
      expect(path.startsWith(onboardingImagesDir), isTrue);
    }
  });
}
