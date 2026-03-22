import 'package:flutter/material.dart';

void main() => runApp(const TSUApp());

class TSUApp extends StatelessWidget {
  const TSUApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue), // Стиль ТГУ
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
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Row(
        children: [
          Padding(padding:  EdgeInsetsGeometry.fromLTRB(180, 0, 0, 0)),
          Text("Карта:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    ),
        Row(
      children: [
        Padding(padding:  EdgeInsetsGeometry.fromLTRB(145, 0, 0, 100)),
      FloatingActionButton.extended(
      onPressed: () {
      print("Кнопка нажата");
      },
      label: const Text("Найти путь"),
      icon: const Icon(Icons.directions),
      ),
    ],
      )



      ],
    );
  }
}

