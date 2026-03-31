import 'package:flutter/material.dart';
import 'map_data_HD.dart';
import 'path.dart';

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
  final List<Widget> screen = [
    const NavigationScreen(),
    const Center(child: Text("Тут еда будет")),
    const Center(child: Text("Тут все остальное будет")),
  ];

  @override
  Widget build(BuildContext context) {
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
  const NavigationScreen({super.key});
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
  @override
  void initState() {
    super.initState();
    double zoom = 2.5;

    double offsetX = (320 / 1.5) * (1 - zoom);
    double offsetY = (240*1.4) * (1 - zoom);
    _transformationController.value = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(zoom);
  }
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
      setState(() {
        centroids.add(Offset(x, y));
      });
    }
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
                  color: Colors.black.withOpacity(0.15), // Легкая черная тень
                  blurRadius: 6, // Насколько тень размыта
                  offset: Offset(0, 3), // Сдвиг тени вниз
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
          padding: EdgeInsets.all(4),
          child: Text("Центроидов: ${centroids.length}"),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text("Карта Рощи:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),]
        ),

        Expanded(
            child: InteractiveViewer(

              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.symmetric(vertical: -180, horizontal: 0),// <--- НИКАКИХ ПУСТОТ ПО КРАЯМ
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
                    Image.asset(
                    'assets/images/MAP.png',
                      width: 320,
                    height: 240,
                      fit: BoxFit.fill,
                      ),
                    ...pathPoints.map((p) => Positioned(
                      left: p.dx - 1,
                      top: p.dy - 1,
                      child: Container(
                        width: 2, height: 2,
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      ),
                    )),
                    ...points.map((p) => Positioned(
                      left: p.dx - 2,
                      top: p.dy - 2,
                      child: Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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