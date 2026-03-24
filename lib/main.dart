import 'package:flutter/material.dart';
import 'map_data_HD.dart';
import 'path.dart';

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
  List<Offset> points = [];
  List<Offset> pathPoints = [];
  final int gridW = RoshaMap.width;
  final int gridH = RoshaMap.height;

  int? startGridX;
  int? startGridY;

  void _handleTap(TapDownDetails details, Size mapSize) {
    double x = details.localPosition.dx;
    double y = details.localPosition.dy;

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
              const SnackBar(content: Text("Путь не достпен")),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Text("Карта Рощи:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),]
        ),

          Container(
            margin: const EdgeInsets.fromLTRB(10, 150, 10, 10),

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
                    )),
                    ...points.map((p) => Positioned(
                      left: p.dx - 2,
                      top: p.dy - 2,
                      child: Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    )),
                  ],
                )
              ),
            ),
          ),

      ],
    );
  }
}