import 'package:flutter/material.dart';
import 'map_data_HD.dart';
import 'path.dart';
import 'dart:math';
import 'main.dart';
import 'Painter.dart' as my_painter;


class FoodPlace {
  final String name;
  final Offset pos;
  final List<String> menu;
  final int closeHour;

  FoodPlace(this.name, this.pos, this.menu, this.closeHour);
}


final List<FoodPlace> roshaPlaces = [
  FoodPlace("СибБлины", const Offset(135, 140), ["Блины", "Обед"], 20),
  FoodPlace("Starbucks", const Offset(133, 120), ["Кофе"], 22),
  FoodPlace("Ярче", const Offset(305, 40), ["Посуда", "Сэндвич"], 23),
  FoodPlace("ГК ТГУ", const Offset(255, 60), ["Обед"], 16),
  FoodPlace("Магнит", const Offset(50, 76), ["Энергетик"], 22),
];





class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});
  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final TransformationController _transformationController = TransformationController();

  AppMode currentMode = AppMode.clustering;

  final List<String> dishes = ["Блины", "Кофе", "Посуда", "Сэндвич", "Обед", "Энергетик"];
  Set<String> selectedDishes = {};

  bool isCalculating = false;
  List<Offset> gaRoute = [];



  // подсчет
  double _calculateFitness(List<FoodPlace> route, Offset start) {
    double dist = 0;
    Offset currentPos = start;

    double currentTime = DateTime.now().hour * 60.0 + DateTime.now().minute;
    double penalty = 0;

    for (var place in route) {
      double d = (place.pos - currentPos).distance;
      dist += d;
      currentTime += (d / 83.3) + 5;
      if (currentTime > (place.closeHour * 60)) {
        penalty += 10000;
      }

      double minToClose = (place.closeHour * 60) - currentTime;
      if (minToClose < 30 && minToClose > 0) penalty -= 200;

      currentPos = place.pos;
    }
    return dist + penalty;
  }



  List<FoodPlace> _crossover(List<FoodPlace> p1, List<FoodPlace> p2) {
    int split = Random().nextInt(p1.length);
    List<FoodPlace> child = p1.sublist(0, split);
    for (var item in p2) {
      if (!child.contains(item)) child.add(item);
    }
    return child;
  }


  void _mutate(List<FoodPlace> ind) {
    if (ind.length < 2) return;
    int i = Random().nextInt(ind.length);
    int j = Random().nextInt(ind.length);
    var temp = ind[i];
    ind[i] = ind[j];
    ind[j] = temp;
  }


  @override
  void initState() {
    super.initState();
    double zoom = 2.5;
    double offsetX = (320 / 1.5) * (1 - zoom);
    double offsetY = (240 * 1.4) * (1 - zoom);
    _transformationController.value = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(zoom);
  }


  // сам алгоритм
  Future<void> runGeneticAlgorithm() async {

    setState(() {
      currentMode = AppMode.A;
      isCalculating = true;
      gaRoute.clear();
    });

    Offset startPos = const Offset(135, 170);

    List<FoodPlace> targets = [];
    for (int i = 0; i < roshaPlaces.length; i++) {
      FoodPlace place = roshaPlaces[i];
      bool hasSelectedDish = false;
      for (int j = 0; j < place.menu.length; j++) {
        if (selectedDishes.contains(place.menu[j])) {
          hasSelectedDish = true;
          break;
        }
      }
      if (hasSelectedDish) {
        targets.add(place);
      }
    }

    int populationSize = 15;
    int generations = 50;
    double mutationRate = 0.2;

    List<List<FoodPlace>> population = [];
    for (int i = 0; i < populationSize; i++) {
      List<FoodPlace> individual = List.from(targets);
      individual.shuffle();
      population.add(individual);
    }

    for (int g = 0; g  < generations; g++) {

      population.sort((a, b) {
        double fitnessA = _calculateFitness(a, startPos);
        double fitnessB = _calculateFitness(b, startPos);
        return fitnessA.compareTo(fitnessB);
      });

      List<FoodPlace> bestIndividual = population[0];

      setState(() {
        List<Offset> waypoints = [];
        waypoints.add(startPos);
        for (int i = 0; i < bestIndividual.length; i++) {
          waypoints.add(bestIndividual[i].pos);
        }
        gaRoute = _buildFullPath(waypoints);
      });

      List<List<FoodPlace>> nextGen = [];
      nextGen.add(population[0]);

      while (nextGen.length < populationSize) {

        var parent1 = population[Random().nextInt(5)];
        var parent2 = population[Random().nextInt(5)];

        var child = _crossover(parent1, parent2);

        if (Random().nextDouble() < mutationRate) {
          _mutate(child);
        }
        nextGen.add(child);
      }
      population = nextGen;

      await Future.delayed(const Duration(milliseconds: 100));
    }
    setState(() {
      isCalculating = false;
    });
  }





  Offset? _getNearestRoad(int targetX, int targetY, int gridW, int gridH) {
    int? finalX;
    int? finalY;
    double minDistance = 999;

    for (int dy = -2; dy <= 2; dy++) {
      for (int dx = -2; dx <= 2; dx++) {
        int checkX = targetX + dx;
        int checkY = targetY + dy;

        if (checkX >= 0 && checkX < gridW && checkY >= 0 && checkY < gridH) {
          int index = checkY * gridW + checkX;
          if (RoshaMap.grid[index] == 0) { // 0 - это дорога
            double dist = (dx * dx + dy * dy).toDouble();
            if (dist < minDistance) {
              minDistance = dist;
              finalX = checkX;
              finalY = checkY;
            }
          }
        }
      }
    }
    if (finalX != null && finalY != null) return Offset(finalX.toDouble(), finalY.toDouble());
    return null;
  }




  List<Offset> _buildFullPath(List<Offset> waypoints) {
    List<Offset> fullRoute = [];

    final int gridW = RoshaMap.width;
    final int gridH = RoshaMap.height;
    final double mapWidth = 320.0;
    final double mapHeight = 240.0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      Offset start = waypoints[i];
      Offset goal = waypoints[i + 1];


      int startX = ((start.dx / mapWidth) * gridW).floor();
      int startY = ((start.dy / mapHeight) * gridH).floor();
      int goalX = ((goal.dx / mapWidth) * gridW).floor();
      int goalY = ((goal.dy / mapHeight) * gridH).floor();

      Offset? validStart = _getNearestRoad(startX, startY, gridW, gridH);
      Offset? validGoal = _getNearestRoad(goalX, goalY, gridW, gridH);

      List<Offset> segment = [];

      if (validStart != null && validGoal != null) {
        List<Offset> gridPath = AStarSolver.findPath(
            validStart.dx.toInt(), validStart.dy.toInt(),
            validGoal.dx.toInt(), validGoal.dy.toInt()
        );

        if (gridPath.isNotEmpty) {

          segment = gridPath.map((p) => Offset(
            (p.dx / gridW) * mapWidth,
            (p.dy / gridH) * mapHeight,
          )).toList();
        }
      }

      if (segment.isNotEmpty) {
        fullRoute.add(start);

        if (fullRoute.length > 1) segment.removeAt(0);
        fullRoute.addAll(segment);

        fullRoute.add(goal);
      } else {
        fullRoute.add(start);
        fullRoute.add(goal);
      }
    }

    return fullRoute;
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => currentMode = AppMode.A),
              child: Container(
                width: 150,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: currentMode == AppMode.A ? Colors.blue : Colors.grey[400],
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(25)),
                ),
                child: const Text("Карта", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => currentMode = AppMode.clustering),
              child: Container(
                width: 150,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: currentMode == AppMode.clustering ? Colors.blue : Colors.grey[400],
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(25)),
                ),
                child: const Text("Выбор еды", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Expanded(
          child: currentMode == AppMode.A ? _buildMapView() : _buildSelectionView(),
        ),
      ],
    );
  }

  Widget _buildSelectionView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Что вы хотите купить?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: dishes.map((dish) {
              final isSelected = selectedDishes.contains(dish);
              return FilterChip(
                label: Text(dish),
                selected: isSelected,
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
                onSelected: (bool value) {
                  setState(() {
                    value ? selectedDishes.add(dish) : selectedDishes.remove(dish);
                  });
                },
              );
            }).toList(),
          ),
          const Spacer(),
          Center(
            child: ElevatedButton(
              onPressed: selectedDishes.isEmpty || isCalculating ? null : runGeneticAlgorithm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: isCalculating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("РАССЧИТАТЬ ПУТЬ", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.symmetric(vertical: 200, horizontal: 200),
      minScale: 2.5,
      maxScale: 8.0,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 320,
          height: 240,
          child: Stack(
            children: [
              Image.asset(
                'assets/images/MAP.png',
                width: 320,
                height: 240,
                fit: BoxFit.fill,
              ),
              CustomPaint(
                size: const Size(320, 240),
                painter: my_painter.PathPainter(gaRoute, color: Colors.orange),
              ),
              ...roshaPlaces.map((p) => Positioned(
                left: p.pos.dx - 3,
                top: p.pos.dy - 3,
                child: Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              )),
              if (gaRoute.isNotEmpty)
                Positioned(
                  left: gaRoute.first.dx - 4,
                  top: gaRoute.first.dy - 4,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

  }
}