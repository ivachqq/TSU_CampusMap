import 'package:flutter/material.dart';
import 'package:tsu_app/search_coworkings.dart';
import 'map_data_HD.dart';
import 'path.dart';
import 'other_screen.dart';
import 'cluster.dart';
import 'cafe_data.dart';
import 'drow_points.dart';
import 'ant_algoritm.dart';

enum AppMode { A, clustering, Ant }
void main() => runApp(const TSUApp());

class TSUApp extends StatelessWidget {
  const TSUApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainNavigation(),
    );
  }
}
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int IndexPage = 0;
  int groupSize = 0;
  AppMode currentMode = AppMode.Ant;
  MapPoint? startPoint;
  List<Offset> pathPoints = [];
  List<Offset> pathPointsAnt = [];
  final List<MapPoint> _selectedPoints = [];
  
  void _handleUpdate() {
    setState(() {});
  }

  void _buildOptimizedRoute() {
    if (_selectedPoints.length < 2) return;

    setState(() {
      List<MapPoint> optimizedPoints = AntSolver.solveACO(_selectedPoints);

      List<Offset> fullPath = [];
      for (int i = 0; i < optimizedPoints.length - 1; i++) {
        var segment = AStarSolver.findPath(
          optimizedPoints[i].x, optimizedPoints[i].y,
          optimizedPoints[i + 1].x, optimizedPoints[i + 1].y,
        );

        fullPath.addAll(segment.map((p) => Offset(
          (p.dx / RoshaMap.width) * 320,
          (p.dy / RoshaMap.height) * 240,
        )));
      }

      this.pathPoints = fullPath;
      IndexPage = 0;
    });
  }

  void buildOptimizedRouteForGroup() {
    if (startPoint == null) return;

    setState(() {
      List<Coworkings> selectedCoworkings = CoworkingSolver.solveStudentDistribution(
        coworkings,
        groupSize,
      );

      List<MapPoint> optimizedPoints = selectedCoworkings.map((c) =>
          MapPoint(name: c.name, x: c.x, y: c.y)
      ).toList();

      optimizedPoints.insert(0, startPoint!);

      List<Offset> fullPath = [];
      for (int i = 0; i < optimizedPoints.length - 1; i++) {
        var segment = AStarSolver.findPath(
          optimizedPoints[i].x, optimizedPoints[i].y,
          optimizedPoints[i + 1].x, optimizedPoints[i + 1].y,
        );

        fullPath.addAll(segment.map((p) => Offset(
          (p.dx / RoshaMap.width) * 320,
          (p.dy / RoshaMap.height) * 240,
        )));
      }

      this.pathPoints = fullPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screen = [
      NavigationScreen(selectedPoints: _selectedPoints, pathPoints: pathPoints, groupSize: groupSize),
      const FoodScreen(),
      OtherScreen(
        selectedPoints: _selectedPoints,
        onChanged: _handleUpdate,
        buildOptimizedRoute: _buildOptimizedRoute,
        onGroupSizeSelected: (int students) {
          setState(() {
            groupSize = students;
            currentMode = AppMode.Ant;
            IndexPage = 0;
          });
        }
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text("TSU map")),
      body: screen[IndexPage],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: IndexPage,
        onTap: (index) => setState(() => IndexPage = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Навигация'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Еда'),
          BottomNavigationBarItem(icon: Icon(Icons.devices_other), label: 'Остальное'),
        ],
      ),
    );
  }
}


class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});
  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

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
  FoodPlace("Ярче", const Offset(305, 40), ["Посуда", "Сэндвич"], 20),
  FoodPlace("ГК ТГУ", const Offset(255, 60), ["Обед"], 16),
  FoodPlace("Магнит", const Offset(50, 76), ["Энергетик"], 22),
];

class _FoodScreenState extends State<FoodScreen> {
  final TransformationController _transformationController = TransformationController();

  AppMode currentMode = AppMode.clustering;

  final List<String> dishes = ["Блины", "Кофе", "Посуда", "Сэндвич", "Обед", "Энергетик"];
  Set<String> selectedDishes = {};

  bool isCalculating = false;
  List<Offset> gaRoute = [];

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

  Future<void> runGeneticAlgorithm() async {
    setState(() {
      currentMode = AppMode.A;
      isCalculating = true;
      gaRoute.clear();
    });

    Offset startPos = const Offset(135, 170);

    List<FoodPlace> targets = roshaPlaces.where((p) {
      return p.menu.any((item) => selectedDishes.contains(item));
    }).toList();

    int generations = 40;

    for (int g = 0; g < generations; g++) {
      //targets.shuffle();
      List<Offset> rawWaypoints = [startPos, ...targets.map((e) => e.pos)];

      List<Offset> realPath = _buildFullPath(rawWaypoints);

      setState(() {
        gaRoute = realPath;
      });

      await Future.delayed(const Duration(milliseconds: 50));
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
                painter: PathPainter(gaRoute, color: Colors.orange),
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
class NavigationScreen extends StatefulWidget {
  final List<MapPoint> selectedPoints;
  final List<Offset> pathPoints;
  final int groupSize;
  const NavigationScreen({
    super.key,
    required this.selectedPoints,
    required this.pathPoints,
    required this.groupSize,
  });
  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final TransformationController _transformationController = TransformationController();
  AppMode currentMode = AppMode.A;  
  List<Offset> points = [];
  List<Offset> pathPoints = [];
  final int gridW = RoshaMap.width;
  final int gridH = RoshaMap.height;

  MapPoint? startPoint;
  List<Coworkings> routeCoworkings = [];
  List<Offset> routeOffsets = [];

  int? startGridX;
  int? startGridY;
  
  List<Offset> centroids = [];
  int k = 3;
  List<Cafe> cafes = List.from(allCafes);
  bool isClustered = false;
  final List<Color> clusterColors = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.brown,];

  @override
  void initState() {
    super.initState();
    double zoom = 2.5;

  int k = 3;  
  List<Cafe> cafes = List.from(allCafes);
  bool isClustered = false;  
  final List<Color> clusterColors = [];


    double offsetX = (320 / 1.5) * (1 - zoom);
    double offsetY = (240*1.4) * (1 - zoom);
    _transformationController.value = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(zoom);
  }
  void _handleTap(TapDownDetails details, Size mapSize) {
    double x = details.localPosition.dx;
    double y = details.localPosition.dy;

    //для поиска коотрдинат точек на карте

    int targetX = ((x / mapSize.width) * gridW).floor();
    int targetY = ((y / mapSize.height) * gridH).floor();
    print('Точка, х: $targetX, y: $targetY');

    if (currentMode==AppMode.A) {
      int targetX = ((x / mapSize.width) * gridW).floor();
      int targetY = ((y / mapSize.height) * gridH).floor();

      int? finalX;
      int? finalY;

      double minDistance = 999;

      for (int dy = -4; dy <= 4; dy++) {
        for (int dx = -4; dx <= 4; dx++) {
          int checkX = targetX + dx;
          int checkY = targetY + dy;

          if (checkX >= 0 && checkX < gridW && checkY >= 0 && checkY < gridH) {
            int index = checkY * gridW + checkX;
            if (RoshaMap.grid[index] == 0) {
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
      if (finalX != null && finalY != null) {
        setState(() {
          if (points.length >= 2) {
            points.clear();
            pathPoints.clear();
            startGridX = null;
            startGridY = null;
          }

          double drawX = (finalX! / gridW) * mapSize.width;
          double drawY = (finalY! / gridH) * mapSize.height;
          points.add(Offset(drawX, drawY));
          if (points.length == 1) {
            startGridX = finalX;
            startGridY = finalY;
          } else if (points.length == 2) {

            List<Offset> gridPath = AStarSolver.findPath(startGridX!, startGridY!, finalX!, finalY!);
            if (gridPath.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Путь не доступен")),
              );
            } else {
              pathPoints = gridPath.map((p) => Offset(
                (p.dx / gridW) * mapSize.width,
                (p.dy / gridH) * mapSize.height,
              )).toList();
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Это не дорога")),
        );
      }
    }
    else if(currentMode == AppMode.Ant) {
      int mapX = (x / mapSize.width * gridW).floor();
      int mapY = (y / mapSize.height * gridH).floor();

      if (mapX < 0 || mapX >= gridW || mapY < 0 || mapY >= gridH || RoshaMap.grid[mapY * gridW + mapX] != 0){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Это не дорога")),
        );
        return;
      }
      setState((){
        startPoint = MapPoint(
          name: "Старт",
          x: mapX,
          y: mapY,
        );
        print("StartPoint: ${startPoint!.x}, ${startPoint!.y}");
        final mainnav = _MainNavigationState();
        mainnav.buildOptimizedRouteForGroup();
      });
    }
    else {
      if (x < 0 || x > mapSize.width || y < 0 || y > mapSize.height) return;

      if (isClustered) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Сначала очистите результат (кнопка Заново)")),
        );
        return;
      }
      setState(() {
        centroids.add(Offset(x, y));
      });
    }
  }

  void runClustering() {
  if (centroids.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Сначала поставьте центроиды на карте!")),
    );
    return;
  }
  if (centroids.length > allCafes.length) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Количество центроидов превышает количество кафе! Переделайте центроиды!")),
    );
    return;
  }
  KMeanClustering kmeans = KMeanClustering();
  List<Cafe> workingCafes = kmeans.cluster(
    cafes,
    centroids,
    gridW,
    gridH,
    320.0,
    240.0,
  );

  setState(() {
    cafes = workingCafes;
    isClustered = true;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Кластеризация завершена! ${centroids.length} кластеров")),
  );
}

void resetClustering() {
  setState(() {
    for (var cafe in cafes) {
      cafe.clusterId = null;
    }
    cafes = List.from(allCafes);
    centroids.clear();
    isClustered = false;
  });
}


Color getCafeColor(Cafe cafe) {
  if (!isClustered) return Colors.grey;
  int id = cafe.clusterId ?? 0;
  return clusterColors[id % clusterColors.length];
}

double gridToPixelX(int gridX) {
  return (gridX / gridW) * 320;
}

double gridToPixelY(int gridY) {
  return (gridY / gridH) * 240;
}


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                borderRadius: BorderRadius.horizontal(left: Radius.circular(25)),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
              ),
              child: Text("A* маршрут", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                borderRadius: BorderRadius.horizontal(right: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text("Кластеризация", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      if (currentMode == AppMode.clustering)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Центроидов: ${centroids.length}"),
                  const SizedBox(width: 16),
                  if (!isClustered && centroids.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => centroids.clear()),
                      child: const Text("Очистить"),
                    ),
                  if (isClustered)
                    TextButton(
                      onPressed: resetClustering,
                      child: const Text("Заново"),
                    ),
                ],
              ),
              if (!isClustered && centroids.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ElevatedButton(
                    onPressed: runClustering,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text("Кластеризовать"),
                  ),
                ),
            ],
          ),

        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text("Карта Рощи:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),]
        ),

        Expanded(
            child: InteractiveViewer(

              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.symmetric(vertical: 200, horizontal: 200),
              minScale: 2.5,
              maxScale: 8.0,
              child: FittedBox(
              fit: BoxFit.contain,
              child: GestureDetector(
                onTapDown: (details) {
                  _handleTap(details, const Size(320, 240));
                },
                child: SizedBox(
                  width: 320,
                  height: 240,
                  child: Stack(
                  children: [
                    SizedBox(
                      width: 320, height: 240,
                      child: Image.asset('assets/images/MAP.png', fit: BoxFit.fill),
                    ),
                    ...widget.pathPoints.map((p) => Positioned(
                      left: p.dx - 1,
                      top: p.dy - 1,
                      child: Container(
                        width: 2, height: 2,
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      ),
                    )).toList(),
                    CustomPaint(
                      size: const Size(320, 240),
                      painter: PathPainter(pathPoints),
                    ),
                    SelectedPointsLayer(
                      selectedPoints: widget.selectedPoints,
                      gridW: gridW,
                      gridH: gridH,
                    ),
                    ...points.map((p) => Positioned(
                      left: p.dx - 2,
                      top: p.dy - 2,
                      child: Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                )),
                if (currentMode == AppMode.clustering && !isClustered)
                  ...cafes.map((cafe) => Positioned(
                    left: gridToPixelX(cafe.gridX) - 6,
                    top: gridToPixelY(cafe.gridY) - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: getCafeColor(cafe),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Tooltip(
                        message: cafe.name,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  )),
                if (currentMode == AppMode.clustering)
                  ...centroids.asMap().entries.map((entry) => Positioned(
                    left: entry.value.dx - 8,
                    top: entry.value.dy - 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          "${entry.key + 1}",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  )),
                  if (currentMode == AppMode.clustering && isClustered)
                  ...List.generate(centroids.length, (index) {
                    List<Cafe> clusterCafes = cafes.where((c) => c.clusterId == index).toList();
                    if (clusterCafes.isEmpty) return const SizedBox();
                    double sumX = 0;
                    double sumY = 0;
                    for (var cafe in clusterCafes) {
                      sumX += cafe.gridX;
                      sumY += cafe.gridY;
                    }
                    double centerX = (sumX / clusterCafes.length) / gridW * 320;
                    double centerY = (sumY / clusterCafes.length) / gridH * 240;
                    return Positioned(
                      left: centerX - 10,
                      top: centerY - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: clusterColors[index % clusterColors.length],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.star, color: Colors.white, size: 12),
                        ),
                      ),
                    );
                  }),
              ],
            )
          ),
              ),
              ),
            ),
        ),
      ],
    );
  }
}
class PathPainter extends CustomPainter {
  final List<Offset> path;
  final Color color;

  PathPainter(this.path, {this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pathObj = Path();
    pathObj.moveTo(path.first.dx, path.first.dy);

    for (int i = 1; i < path.length; i++) {
      pathObj.lineTo(path[i].dx, path[i].dy);
    }

    canvas.drawPath(pathObj, paint);
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => oldDelegate.path != path;
}
