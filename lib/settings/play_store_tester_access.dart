/// Play Console tester complimentary access.
///
/// Paid unlock is not wired in this sweep. Later purchase checks should call
/// [grantsComplimentaryPaidAccess].
abstract final class PlayStoreTesterAccess {
  static const complimentaryAccessUsername =
      'scokologhunjmentlogdirfirelogsabndbasmnbjjxcbbxbsjjasldasljdaskjdwn';

  static bool grantsComplimentaryPaidAccess(String? username) =>
      (username ?? '').trim() == complimentaryAccessUsername;
}
