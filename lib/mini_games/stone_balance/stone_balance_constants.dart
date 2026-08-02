import 'package:flutter/material.dart';

/// Shared ids and tunables for Stone Balance.
abstract final class StoneBalanceConstants {
  static const String gameId = 'stone_balance';
  static const String title = 'Stone Balance';
  static const String description =
      'Drag or tap to aim, then release to drop. Stack high before the tower topples.';

  static const String aimHint = 'Drag or tap to aim · release to drop';

  static const int durationSeconds = 90;
  static const int unlockCost = 300;
  static const int playCost = 100;
  static const int endlessCost = 150;
  static const double baseDifficulty = 1.0;

  /// Stone width as fraction of canvas width (randomized per stone).
  static const double stoneWidthMinFraction = 0.28;
  static const double stoneWidthMaxFraction = 0.42;

  /// Absolute stone height range (logical px).
  static const double stoneHeightMin = 28;
  static const double stoneHeightMax = 44;

  /// Center offset / support width above this -> tower begins collapsing.
  static const double overhangUnstable = 0.18;

  /// Center offset / support width above this -> immediate topple.
  static const double overhangImmediateTopple = 0.28;

  /// How long an unstable stack leans before full topple.
  static const double unstableFallSeconds = 0.35;

  /// Extra lean (radians) from overhang on top of the support stone's tilt.
  static const double maxStableTilt = 0.12;

  /// Tower centroid may drift this far from the foundation stone (screen width).
  static const double towerLeanMaxScreenFraction = 0.20;

  static const double fallGravity = 2400;
  static const double fallMaxSpeed = 1100;

  /// Slow descent during the topple cascade (offender walking down the tower).
  static const double toppleFallGravity = 420;
  static const double toppleFallMaxSpeed = 280;

  /// Sim time scale when the offender is near the ground / during finale.
  static const double toppleNearGroundTimeScale = 1 / 3;

  /// Start slow-mo when offender bottom is within this fraction of play height
  /// above the grass line.
  static const double toppleNearGroundBandFraction = 0.35;

  /// Pause after bounce settles before the offender explodes.
  static const double topplePostBounceBeforeExplode = 0.22;

  /// How long the explode burst plays before the fail end screen.
  static const double toppleExplodeDuration = 0.55;

  static const double spawnInterval = 0.35;
  static const double scatterLife = 2.4;

  /// Horizontal inset for player-aimed stones.
  static const double aimMarginFraction = 0.10;

  /// Extra inset for the auto first stone (no wall shenanigans).
  static const double firstStoneMarginFraction = 0.22;

  static const double spawnYFraction = 0.10;

  /// Keep stack top this far down from the top of the screen (0.67 ~= 33% up
  /// from the bottom).
  static const double cameraFollowBand = 0.67;
  static const double cameraEase = 8.0;
  static const double cameraLandSnap = 0.85;

  /// Green grass line (sand top). Must match backdrop ground band.
  /// Bottom ~10% of the canvas so early stacks have room before camera follow.
  static const double grassLineFraction = 0.90;

  /// Height of the three base platform stones (logical px).
  static const double platformStoneHeight = 22;

  /// Height at which garden ground / platform stops rendering, and the camera
  /// begins following the stack upward (world cameraY goes negative).
  static const int groundGoneHeight = 16;

  /// Background phase cross-fade duration.
  static const double backgroundCrossfadeSeconds = 1.5;

  static const Color stoneTop = Color(0xFFC8B89A);
  static const Color stoneSide = Color(0xFF8A7A62);
  static const Color stoneOutline = Color(0xFF6A5A48);
  static const Color stoneGrain = Color(0xFF9A8A72);
  static const Color platform = Color(0xFF8A7A62);
}
