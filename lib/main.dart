import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'map_data_HD.dart';
import 'path.dart';
import 'other_screen.dart';
import 'cluster.dart';
import 'cafe_data.dart';
import 'drow_points.dart';
import 'ant_algoritm.dart';
import 'dop.dart';
import 'Main.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'Painter.dart' as my_painter;
import 'three.dart';

enum AppMode { A, clustering }
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
  List<Offset> pathPoints = [];
  final List<MapPoint> _selectedPoints = [];

  void _handleUpdate() {
    setState(() {});
  }







  //для муравьинного
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






  @override
  Widget build(BuildContext context) {
    final List<Widget> screen = [
      NavigationScreen(selectedPoints: _selectedPoints, pathPoints: pathPoints),
      FoodScreen(),
      DecisionTreeScreen(),
      OtherScreen(
        selectedPoints: _selectedPoints,
        onChanged: _handleUpdate,
        buildOptimizedRoute: _buildOptimizedRoute,
      ),
    ];
    //внизу
    return Scaffold(
      appBar: AppBar(title: const Text("TSU map")),
      body: screen[IndexPage],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: IndexPage,
        onTap: (index) => setState(() => IndexPage = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Навигация'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Еда'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Помощник'),
          BottomNavigationBarItem(icon: Icon(Icons.devices_other), label: 'Остальное'),
        ],
      ),
    );
  }
}



class NavigationScreen extends StatefulWidget {
  final List<MapPoint> selectedPoints;
  final List<Offset> pathPoints;
  const NavigationScreen({super.key, required this.selectedPoints, required this.pathPoints});
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
  bool _isDragging = false;
  Offset? _tapDownPosition;
  static const double _dragThreshold = 8.0;
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





  void _handleTapFromPosition(Offset localPosition, Size mapSize) {
    double x = localPosition.dx;
    double y = localPosition.dy;

    if (currentMode == AppMode.A) {
      int targetX = ((x / mapSize.width) * gridW).floor();//тут переводим в номер клетки на карте
      int targetY = ((y / mapSize.height) * gridH).floor();

      int? finalX;
      int? finalY;
      double minDistance = 999;

      for (int dy = -4; dy <= 4; dy++) {//проверяем ближайшмие, чтоб точно попасть
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
          if (points.length >= 2) {//сбрасываем старый маршрут
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
            List<Offset> gridPath = AStarSolver.findPath(startGridX!, startGridY!, finalX!, finalY!);//запуск самого A*
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
    } else {//для кластеров
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
  //для кластеров
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
        //кнопка A* - кластеры
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
            // кнопки кластеров
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
            // контроллер нажатий

            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.symmetric(vertical: 200, horizontal: 200),
            minScale: 2.5,
            maxScale: 8.0,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Listener(
                onPointerDown: (event) {
                  _tapDownPosition = event.localPosition;
                  _isDragging = false;
                },
                onPointerMove: (event) {
                  if (_tapDownPosition != null) {
                    final delta = event.localPosition - _tapDownPosition!;
                    if (delta.distance > _dragThreshold) {
                      _isDragging = true;
                    }
                  }
                },
                onPointerUp: (event) {
                  if (!_isDragging && _tapDownPosition != null) {
                    _handleTapFromPosition(_tapDownPosition!, const Size(320, 240));//запуск алгоритма
                  }
                  _tapDownPosition = null;
                  _isDragging = false;
                },
                onPointerCancel: (event) {
                  _tapDownPosition = null;
                  _isDragging = false;
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

                        ...widget.pathPoints.map((p) => Positioned(//для муравьинного
                          left: p.dx - 1,
                          top: p.dy - 1,
                          child: Container(
                            width: 2, height: 2,
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          ),
                        )).toList(),

                        CustomPaint(// отрисовка построения маршрута
                          size: const Size(320, 240),
                          painter: my_painter.PathPainter(pathPoints),
                        ),


                        SelectedPointsLayer(
                          selectedPoints: widget.selectedPoints,
                          gridW: gridW,
                          gridH: gridH,
                        ),

                        ...points.map((p) => Positioned(// отрисовка старт финишь
                          left: p.dx - 2,
                          top: p.dy - 2,
                          child: Container(
                            width: 5, height: 5,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        )),



                        // далее только кластеры
                        if (currentMode == AppMode.clustering)
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
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: clusterColors[index % clusterColors.length],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.star, color: Colors.white, size: 8),
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
