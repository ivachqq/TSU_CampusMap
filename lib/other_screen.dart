import 'package:flutter/material.dart';

class MapPoint {
  final String name;
  final int x;
  final int y;

  const MapPoint({
    required this.name,
    required this.x,
    required this.y,
  });
}
const List<MapPoint> mapPoints = [
  MapPoint(name: "Геофизический центр Евразии", x: 298, y: 128),
  MapPoint(name: "Каменные бабы (слева)", x: 251, y: 153),
  MapPoint(name: "Каменные бабы (справа)", x: 250, y: 105),
  MapPoint(name: "Главный корпус ТГУ", x: 232, y: 127),
  MapPoint(name: "Мостик через медичку", x: 232, y: 127), //координаты пока неизвестны
  MapPoint(name: "Памятник крылову и Сергиевской", x: 232, y: 127) //координаты неизвестны
];

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Здесь будет раздел 'Другое'"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              print("Нажали кнопку");
            },
            child: Text("Нажми меня"),
          ),
        ],
      ),
    );
  }
}