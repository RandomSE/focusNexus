/// Kind of placeable entity in a progressive visual sandbox.
enum SandboxEntityKind {
  /// Theme-specific primary growth object (plant, coral polyp, star, …).
  primary,

  /// Purchasable / inventory decoration.
  decoration,
}

/// Lightweight reference to a picked sandbox entity.
class SandboxEntityRef {
  const SandboxEntityRef({
    required this.id,
    required this.kind,
  });

  final String id;
  final SandboxEntityKind kind;

  bool get isPrimary => kind == SandboxEntityKind.primary;

  bool get isDecoration => kind == SandboxEntityKind.decoration;
}

/// Shared shape for anything placed on the sandbox canvas.
abstract interface class SandboxPlaceable {
  String get id;
  double get positionX;
  double get positionY;
  int get stageIndex;
  SandboxEntityKind get entityKind;
}
