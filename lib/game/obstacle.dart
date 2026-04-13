import 'dart:math';
import 'game_constants.dart';

enum ObstacleType { staticBlock, fluxBlock, pulseBar, flashWall }

class Obstacle {
  double y;
  int lane; // 0=left, 1=center, 2=right
  final ObstacleType type;
  double width;
  double height;

  // For flux block
  double fluxTimer = 0;
  double fluxInterval = 1.8;
  int fluxDirection = 1;

  // For pulse bar
  double pulseScale = 1.0;
  double pulseTimer = 0;

  // For flash wall (spans 2 or 3 lanes)
  int flashSpan = 2; // how many lanes blocked
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
    fluxInterval = 1.2 + Random().nextDouble() * 0.8;
    fluxDirection = Random().nextBool() ? 1 : -1;
  }

  factory Obstacle.random(double startY, double laneWidth, double gameSpeed) {
    final rng = Random();
    final types = ObstacleType.values;
    // Weight: static most common early
    final weights = [40, 30, 20, 10];
    int total = weights.fold(0, (a, b) => a + b);
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
      int span = rng.nextBool() ? 2 : 2;
      int startLane = rng.nextInt(2); // 0 or 1
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

    return Obstacle(
      y: startY,
      lane: rng.nextInt(3),
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
        lane = (lane + fluxDirection).clamp(0, 2);
        if (lane == 0 || lane == 2) fluxDirection = -fluxDirection;
      }
    } else if (type == ObstacleType.pulseBar) {
      pulseTimer += dt;
      pulseScale = 1.0 + 0.35 * sin(pulseTimer * 3.5);
    }
  }

  // Effective lanes blocked
  List<int> get blockedLanes {
    if (type == ObstacleType.flashWall) {
      return List.generate(flashSpan, (i) => flashStartLane + i);
    }
    return [lane];
  }
}
