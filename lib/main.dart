import 'package:flutter/material.dart';
import 'map_data_HD.dart';
import 'path.dart';
import 'other_screen.dart';
import 'cluster.dart';
import 'cafe_data.dart';
import 'ant_algoritm.dart';

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
  final List<MapPoint> _selectedPoints = [];
  void _handleUpdate(){
    setState((){});
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> screen = [
      NavigationScreen(selectedPoints: _selectedPoints),
      const Center(child: Text("Тут еда будет")),
      OtherScreen(selectedPoints: _selectedPoints, onChanged: _handleUpdate),
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
class NavigationScreen extends StatefulWidget {
  final List<MapPoint> selectedPoints;
  const NavigationScreen({super.key, required this.selectedPoints});
  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
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
  Colors.brown,
];


  void _handleTap(TapDownDetails details, Size mapSize) {
    double x = details.localPosition.dx;
    double y = details.localPosition.dy;

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
              decoration: BoxDecoration(
                color: currentMode == AppMode.A ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
              ),
              child: Text("A* маршрут", style: TextStyle(color: Colors.white)),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => currentMode = AppMode.clustering),
            child: Container(
              decoration: BoxDecoration(
                color: currentMode == AppMode.clustering ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
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

          Container(
            margin: const EdgeInsets.fromLTRB(10, 40, 10, 10),

            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(10),
              minScale: 1.0,
              maxScale: 8.0,
              child: GestureDetector(
                onTapDown: (details) {
                  _handleTap(details, const Size(320, 240));
                },
                child: Stack(
                  children: [
                    SizedBox(
                      width: 320, height: 240,
                      child: Image.asset('assets/images/MAP.png', fit: BoxFit.fill),
                    ),
                    ...pathPoints.map((p) => Positioned(
                      left: p.dx - 1,
                      top: p.dy - 1,
                      child: Container(
                        width: 2, height: 2,
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      ),
                    )).toList(),
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
    ],
  );
}
}