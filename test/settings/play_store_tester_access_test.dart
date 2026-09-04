import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/settings/play_store_tester_access.dart';

void main() {
  const testerUsername =
      'scokologhunjmentlogdirfirelogsabndbasmnbjjxcbbxbsjjasldasljdaskjdwn';

  test('exact tester username grants complimentary paid access', () {
    expect(
      PlayStoreTesterAccess.grantsComplimentaryPaidAccess(testerUsername),
      isTrue,
    );
  });

  test('trimmed tester username grants complimentary paid access', () {
    expect(
      PlayStoreTesterAccess.grantsComplimentaryPaidAccess('  $testerUsername  '),
      isTrue,
    );
  });

  test('other usernames do not grant complimentary paid access', () {
    expect(
      PlayStoreTesterAccess.grantsComplimentaryPaidAccess('tester'),
      isFalse,
    );
    expect(PlayStoreTesterAccess.grantsComplimentaryPaidAccess(''), isFalse);
    expect(PlayStoreTesterAccess.grantsComplimentaryPaidAccess(null), isFalse);
    expect(
      PlayStoreTesterAccess.grantsComplimentaryPaidAccess(' $testerUsername x'),
      isFalse,
    );
  });
}
