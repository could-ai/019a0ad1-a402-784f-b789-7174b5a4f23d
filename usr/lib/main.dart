import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disciple Run',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double playerWidth = 60.0;
  static const double playerHeight = 100.0;
  static const double obstacleWidth = 50.0;
  static const double obstacleHeight = 50.0;
  static const double groundHeight = 50.0;

  double playerX = -0.8;
  double playerY = 1.0; // Positioned on the ground
  double playerVelocityY = 0;
  final double gravity = 1.5;
  final double jumpStrength = -20.0;
  bool isJumping = false;

  List<Offset> obstacles = [];
  double gameSpeed = 8.0;
  int score = 0;
  bool gameOver = false;

  late Timer gameLoopTimer;
  late Timer obstacleTimer;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    setState(() {
      playerY = 1.0;
      playerVelocityY = 0;
      isJumping = false;
      obstacles.clear();
      score = 0;
      gameOver = false;
      gameSpeed = 8.0;
    });

    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (gameOver) {
        timer.cancel();
        obstacleTimer.cancel();
        return;
      }
      gameLoop();
    });

    obstacleTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (gameOver) {
        timer.cancel();
        return;
      }
      spawnObstacle();
    });
  }

  void gameLoop() {
    setState(() {
      // Player physics
      if (isJumping) {
        playerVelocityY += gravity;
        playerY += playerVelocityY * 0.02; // Adjust for timer interval

        if (playerY >= 1.0) {
          playerY = 1.0;
          isJumping = false;
          playerVelocityY = 0;
        }
      }

      // Move obstacles
      for (int i = 0; i < obstacles.length; i++) {
        obstacles[i] = Offset(obstacles[i].dx - gameSpeed * 0.02, obstacles[i].dy);
      }

      // Remove off-screen obstacles and increase score
      obstacles.removeWhere((obstacle) {
        if (obstacle.dx < -1.5) {
          score++;
          // Increase speed over time
          if (score % 5 == 0) {
            gameSpeed += 0.5;
          }
          return true;
        }
        return false;
      });

      // Collision detection
      if (checkCollision()) {
        setState(() {
          gameOver = true;
        });
      }
    });
  }

  void jump() {
    if (!isJumping) {
      setState(() {
        isJumping = true;
        playerVelocityY = jumpStrength;
      });
    }
  }

  void spawnObstacle() {
    setState(() {
      obstacles.add(Offset(1.5, 1.0)); // Spawn on the ground
    });
  }

  bool checkCollision() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final playerLeft = (playerX + 1) / 2 * screenWidth;
    final playerRight = playerLeft + playerWidth;
    final playerTop = (playerY + 1) / 2 * screenHeight - playerHeight;
    final playerBottom = playerTop + playerHeight;

    for (final obstacle in obstacles) {
      final obstacleLeft = (obstacle.dx + 1) / 2 * screenWidth;
      final obstacleRight = obstacleLeft + obstacleWidth;
      final obstacleTop = (obstacle.dy + 1) / 2 * screenHeight - obstacleHeight - groundHeight;
      final obstacleBottom = obstacleTop + obstacleHeight;

      if (playerRight > obstacleLeft &&
          playerLeft < obstacleRight &&
          playerBottom > obstacleTop &&
          playerTop < obstacleBottom) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    gameLoopTimer.cancel();
    obstacleTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: jump,
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.lightBlue, Colors.blueAccent],
                ),
              ),
            ),
            // Ground
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: groundHeight,
                color: Colors.green[800],
              ),
            ),
            // Player
            AnimatedContainer(
              duration: const Duration(milliseconds: 0),
              alignment: Alignment(playerX, playerY - (playerHeight / MediaQuery.of(context).size.height * 2)),
              child: Player(
                width: playerWidth,
                height: playerHeight,
              ),
            ),
            // Obstacles
            ...obstacles.map((obstacle) {
              return Align(
                alignment: Alignment(obstacle.dx, obstacle.dy - (obstacleHeight / MediaQuery.of(context).size.height * 2) - (groundHeight / MediaQuery.of(context).size.height)),
                child: Obstacle(
                  width: obstacleWidth,
                  height: obstacleHeight,
                ),
              );
            }).toList(),
            // Score
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                'Score: $score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Game Over Screen
            if (gameOver)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Game Over',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your Score: $score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: startGame,
                        child: const Text('Restart'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Player extends StatelessWidget {
  final double width;
  final double height;

  const Player({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(child: Text("Disciple", style: TextStyle(color: Colors.white))),
    );
  }
}

class Obstacle extends StatelessWidget {
  final double width;
  final double height;

  const Obstacle({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
