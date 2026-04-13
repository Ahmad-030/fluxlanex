class GameConstants {
  // Lanes
  static const int laneCount = 3;
  static const int startLane = 1; // center

  // Speed
  static const double initialSpeed = 280.0; // pixels/sec
  static const double speedIncrement = 18.0; // per 10 seconds
  static const double maxSpeed = 900.0;
  static const double speedInterval = 10.0; // seconds

  // Spawn
  static const double initialSpawnInterval = 1.8; // seconds
  static const double minSpawnInterval = 0.45;
  static const double spawnDecrement = 0.08; // per level

  // Obstacle heights
  static const double staticBlockH = 48.0;
  static const double fluxBlockH = 54.0;
  static const double pulseBarH = 22.0;
  static const double flashWallH = 36.0;

  // Player
  static const double playerW = 42.0;
  static const double playerH = 58.0;
  static const double laneTransitionMs = 130.0;

  // Scoring
  static const double scorePerSecond = 8.0;
  static const int scorePerObstacle = 15;

  // Flux Mode
  static const double fluxModeTime = 30.0; // seconds before flux mode

  // Hit box shrink (forgiveness)
  static const double hitBoxShrink = 10.0;
}
