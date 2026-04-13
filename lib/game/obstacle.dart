import 'dart:math';
import 'game_constants.dart';

enum ObstacleType { staticBlock, fluxBlock, pulseBar, flashWall }

class Obstacle {
  double y;
  int lane; // 0=left, 1=center, 2=right
  final ObstacleType type;
  double width;
  double height;

  // For flux block — which lane it will move TO next
  double fluxTimer = 0;
  double fluxInterval = 1.8;
  int fluxDirection = 1;
  /// The lane this fluxBlock will jump to on next shift.
  /// Shown as an arrow indicator on the block so the player can react.
  int nextLane = 1;

  // For pulse bar
  double pulseScale = 1.0;
  double pulseTimer = 0;

  // For flash wall (spans 2 lanes)
  int flashSpan = 2;
  int flashStartLane = 0;

  bool passed = false;
  bool active = true;

  Obstacle({
    required this.y,
    required this.lane,
    required this.type,
    required this.width,
    required this.height,
    this.flashSpan = 2,
    this.flashStartLane = 0,
  }) {
    final rng = Random();
    fluxInterval = 1.2 + rng.nextDouble() * 0.8;
    // Start direction: away from edges so it always has room to move
    if (lane == 0) {
      fluxDirection = 1;
    } else if (lane == 2) {
      fluxDirection = -1;
    } else {
      fluxDirection = rng.nextBool() ? 1 : -1;
    }
    // Pre-compute where we'll go first
    nextLane = (lane + fluxDirection).clamp(0, 2);
  }

  factory Obstacle.random(double startY, double laneWidth, double gameSpeed) {
    final rng = Random();
    final types = ObstacleType.values;

    // Weight: static most common, flash wall least
    final weights = [40, 30, 20, 10];
    final int total = weights.fold(0, (a, b) => a + b);
    int pick = rng.nextInt(total);
    ObstacleType chosenType = ObstacleType.staticBlock;
    int cumulative = 0;
    for (int i = 0; i < types.length; i++) {
      cumulative += weights[i];
      if (pick < cumulative) {
        chosenType = types[i];
        break;
      }
    }

    if (chosenType == ObstacleType.flashWall) {
      const int span = 2;
      final int startLane = rng.nextInt(2); // 0 or 1 (so it never overflows)
      return Obstacle(
        y: startY,
        lane: startLane,
        type: ObstacleType.flashWall,
        width: laneWidth * span,
        height: GameConstants.flashWallH,
        flashSpan: span,
        flashStartLane: startLane,
      );
    }

    // FIX: start flux/static/pulse blocks fully off the top of the screen
    // so they don't "pop in" mid-screen. Use startY (already –80 from caller).
    final int randomLane = rng.nextInt(3);
    return Obstacle(
      y: startY,
      lane: randomLane,
      type: chosenType,
      width: laneWidth * 0.82,
      height: chosenType == ObstacleType.staticBlock
          ? GameConstants.staticBlockH
          : chosenType == ObstacleType.fluxBlock
          ? GameConstants.fluxBlockH
          : GameConstants.pulseBarH,
    );
  }

  void update(double dt) {
    if (type == ObstacleType.fluxBlock) {
      fluxTimer += dt;
      if (fluxTimer >= fluxInterval) {
        fluxTimer = 0;
        // Perform the jump
        lane = (lane + fluxDirection).clamp(0, 2);
        // Bounce direction at edges
        if (lane == 0 || lane == 2) fluxDirection = -fluxDirection;
        // Update the signal for the NEXT upcoming jump
        nextLane = (lane + fluxDirection).clamp(0, 2);
      }
    } else if (type == ObstacleType.pulseBar) {
      pulseTimer += dt;
      pulseScale = 1.0 + 0.35 * sin(pulseTimer * 3.5);
    }
  }

  // Effective lanes blocked for collision detection
  List<int> get blockedLanes {
    if (type == ObstacleType.flashWall) {
      return List.generate(flashSpan, (i) => flashStartLane + i);
    }
    return [lane];
  }

  /// Progress 0..1 of flux timer (used to draw the warning indicator).
  double get fluxProgress =>
      type == ObstacleType.fluxBlock ? (fluxTimer / fluxInterval).clamp(0.0, 1.0) : 0.0;
}