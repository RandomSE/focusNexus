// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_balance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pointsBalanceHash() => r'812fccca1d61384fcd54d336368d804ba8808da6';

/// Live wallet balance; refreshes when [PointsRepository] balance changes.
///
/// Copied from [PointsBalance].
@ProviderFor(PointsBalance)
final pointsBalanceProvider =
    AsyncNotifierProvider<PointsBalance, int>.internal(
      PointsBalance.new,
      name: r'pointsBalanceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pointsBalanceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PointsBalance = AsyncNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
