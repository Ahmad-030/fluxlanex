import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'game_constants.dart';
import 'obstacle.dart';
import 'particle_system.dart';

enum GameState { playing, paused, gameOver, idle }

class GameController extends ChangeNotifier {
  GameState state = GameState.idle;

  double gameWidth = 0;
  double gameHeight = 0;
  double laneWidth = 0;

  // Player
  int playerLane = GameConstants.startLane;
  double playerTargetX = 0;
  double playerCurrentX = 0;
  double playerY = 0;

  // Motion trail
  final List<Offset> trailPoints = [];

  // Obstacles
  final List<Obstacle> obstacles = [];
  final Random _rng = Random();

  // Timers
  double _gameTime = 0;
  double _spawnTimer = 0;
  double _speedTimer = 0;
  double _spawnInterval = GameConstants.initialSpawnInterval;
  double _currentSpeed = GameConstants.initialSpeed;

  // Scoring
  int score = 0;
  int highScore = 0;
  double _scoreAccumulator = 0;

  // Flux mode
  bool fluxMode = false;
  double _fluxOffset = 0;

  // Particles
  final ParticleSystem particles = ParticleSystem();

  // Lane animation
  double _laneAnimT = 1.0;
  static const double _laneAnimDuration = GameConstants.laneTransitionMs / 1000;

  // Background scroll
  double bgOffset = 0;
  double _bgAccum = 0;

  // Game loop
  Ticker? _ticker;
  Duration? _lastTick;

  void setup(double width, double height, int savedHighScore) {
    gameWidth = width;
    gameHeight = height;
    laneWidth = width / GameConstants.laneCount;
    highScore = savedHighScore;
    _resetPlayerPosition();
  }

  void _resetPlayerPosition() {
    playerLane = GameConstants.startLane;
    playerTargetX = _laneCenter(playerLane);
    playerCurrentX = playerTargetX;
    // Player sits at 78% down the screen
    playerY = gameHeight * 0.78;
  }

  double _laneCenter(int lane) {
    return laneWidth * lane + laneWidth / 2.0;
  }

  void startGame() {
    state = GameState.playing;
    _gameTime = 0;
    _spawnTimer = 0;
    _speedTimer = 0;
    _spawnInterval = GameConstants.initialSpawnInterval;
    _currentSpeed = GameConstants.initialSpeed;
    score = 0;
    _scoreAccumulator = 0;
    fluxMode = false;
    _fluxOffset = 0;
    obstacles.clear();
    particles.particles.clear();
    trailPoints.clear();
    _bgAccum = 0;
    bgOffset = 0;
    _resetPlayerPosition();
    _lastTick = null;
    notifyListeners();
  }

  void attachTicker(Ticker ticker) {
    _ticker = ticker;
    if (!_ticker!.isActive) _ticker!.start();
  }

  void tick(Duration elapsed) {
    if (state != GameState.playing) {
      _lastTick = elapsed;
      return;
    }
    final double dt = _lastTick == null
        ? 0.016
        : (elapsed - _lastTick!).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    _update(dt.clamp(0.0, 0.05));
  }

  void _update(double dt) {
    _gameTime += dt;

    // Speed up every interval
    _speedTimer += dt;
    if (_speedTimer >= GameConstants.speedInterval) {
      _speedTimer = 0;
      _currentSpeed = (_currentSpeed + GameConstants.speedIncrement)
          .clamp(0.0, GameConstants.maxSpeed);
      _spawnInterval = (_spawnInterval - GameConstants.spawnDecrement)
          .clamp(GameConstants.minSpawnInterval, double.infinity);
    }

    // Flux mode
    if (_gameTime >= GameConstants.fluxModeTime && !fluxMode) {
      fluxMode = true;
    }
    if (fluxMode) {
      _fluxOffset = sin(_gameTime * 1.8) * 6.0;
    }

    // Lane lerp
    if (_laneAnimT < 1.0) {
      _laneAnimT = (_laneAnimT + dt / _laneAnimDuration).clamp(0.0, 1.0);
    }
    playerCurrentX =
        _lerp(playerCurrentX, playerTargetX, _laneAnimT.clamp(0.0, 1.0));

    // Trail
    trailPoints.add(Offset(playerCurrentX, playerY));
    if (trailPoints.length > 14) trailPoints.removeAt(0);

    // Spawn
    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnObstacle();
    }

    // Move obstacles downward
    for (final obs in obstacles) {
      obs.y += _currentSpeed * dt;
      obs.update(dt);
    }

    // Remove off-screen obstacles
    obstacles.removeWhere((o) => o.y > gameHeight + 100);

    // Score: passed obstacles
    for (final obs in obstacles) {
      // FIX: obstacle is "passed" only when its BOTTOM edge is fully below the player TOP edge
      // This prevents scoring while obstacle is still beside the player
      if (!obs.passed && (obs.y + obs.height) > (playerY + GameConstants.playerH + 10)) {
        obs.passed = true;
        score += GameConstants.scorePerObstacle;
      }
    }

    // Score per second of survival
    _scoreAccumulator += GameConstants.scorePerSecond * dt;
    if (_scoreAccumulator >= 1.0) {
      score += _scoreAccumulator.floor();
      _scoreAccumulator -= _scoreAccumulator.floor();
    }

    // Background scroll
    _bgAccum += _currentSpeed * dt * 0.4;
    bgOffset = _bgAccum % 80.0;

    // Collision detection
    _checkCollisions();

    // Particles
    particles.update(dt);

    notifyListeners();
  }

  void _spawnObstacle() {
    final obs = Obstacle.random(-80, laneWidth, _currentSpeed);
    obstacles.add(obs);
  }

  void _checkCollisions() {
    // Player hitbox: centered on playerCurrentX, top at playerY
    final double shrink = GameConstants.hitBoxShrink / 2.0;
    final double px = playerCurrentX - GameConstants.playerW / 2.0 + shrink;
    final double py = playerY + shrink;
    final double pw = GameConstants.playerW - GameConstants.hitBoxShrink;
    final double ph = GameConstants.playerH - GameConstants.hitBoxShrink;

    for (final obs in obstacles) {
      if (!obs.active) continue;

      // FIX: Only check collision when obstacle is actually overlapping the
      // player's Y band. If obstacle has already passed below, skip entirely.
      // This stops the "passing beside" false collision.
      final double obsBottom = obs.y + obs.height;
      final double obsTop = obs.y;

      // Obstacle must overlap player vertically
      if (obsBottom < py || obsTop > py + ph) continue;

      final List<int> blockedLanes = obs.blockedLanes;

      for (final lane in blockedLanes) {
        final double obsCenterX = laneWidth * lane + laneWidth / 2.0;
        // Use the pulse scale for pulse bars
        final double effectiveWidth = obs.type == ObstacleType.pulseBar
            ? obs.width * obs.pulseScale
            : obs.width;
        final double ox = obsCenterX - effectiveWidth / 2.0;
        final double ow = effectiveWidth;

        if (_rectsOverlap(px, py, pw, ph, ox, obsTop, ow, obs.height)) {
          particles.burst(Offset(playerCurrentX, playerY + ph / 2));
          _endGame();
          return;
        }
      }
    }
  }

  bool _rectsOverlap(
      double ax, double ay, double aw, double ah,
      double bx, double by, double bw, double bh,
      ) {
    return ax < bx + bw &&
        ax + aw > bx &&
        ay < by + bh &&
        ay + ah > by;
  }

  void _endGame() {
    state = GameState.gameOver;
    if (score > highScore) highScore = score;
    notifyListeners();
  }

  void moveLeft() {
    if (state != GameState.playing) return;
    if (playerLane > 0) {
      playerLane--;
      playerTargetX = _laneCenter(playerLane);
      _laneAnimT = 0.0;
    }
  }

  void moveRight() {
    if (state != GameState.playing) return;
    if (playerLane < 2) {
      playerLane++;
      playerTargetX = _laneCenter(playerLane);
      _laneAnimT = 0.0;
    }
  }

  void pauseGame() {
    if (state == GameState.playing) {
      state = GameState.paused;
      notifyListeners();
    }
  }

  void resumeGame() {
    if (state == GameState.paused) {
      state = GameState.playing;
      _lastTick = null;
      notifyListeners();
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double get fluxLaneOffset => _fluxOffset;
  double get gameTime => _gameTime;
  double get currentSpeed => _currentSpeed;
  int get speedLevel => (_gameTime / GameConstants.speedInterval).floor() + 1;
}