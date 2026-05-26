import 'package:freezed_annotation/freezed_annotation.dart';

import 'garden_state.dart';

part 'garden_op_result.freezed.dart';

/// Result of a sandbox mutation (success carries updated [GardenState]).
@freezed
class GardenOpResult with _$GardenOpResult {
  const GardenOpResult._();

  const factory GardenOpResult({
    GardenState? state,
    String? error,
  }) = _GardenOpResult;

  bool get isSuccess => error == null && state != null;

  factory GardenOpResult.success(GardenState state) =>
      GardenOpResult(state: state);

  factory GardenOpResult.failure(String message) =>
      GardenOpResult(error: message);
}
