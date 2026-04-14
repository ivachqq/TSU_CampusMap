import 'package:flutter/material.dart';
import 'ant_algoritm.dart';

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
  MapPoint(name: "Главный корпус ТГУ", x: 237, y: 128),
  MapPoint(name: "Мостик через медичку", x: 278, y: 39),
  MapPoint(name: "Памятник крылову и Сергиевской", x: 232, y: 127) //координаты неизвестны
];


class OtherScreen extends StatefulWidget {
  final List<MapPoint> selectedPoints;
  final VoidCallback onChanged;
  final VoidCallback buildOptimizedRoute;
  const OtherScreen({super.key, required this.selectedPoints, required this.onChanged, required this.buildOptimizedRoute});

  @override
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen>{

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          title: Text("Достопримечательности"),
          children: mapPoints.map((point) {
            return CheckboxListTile(
              title: Text(point.name),
              value: widget.selectedPoints.contains(point),
              activeColor: Colors.blue,
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    widget.selectedPoints.add(point);
                  } else {
                    widget.selectedPoints.remove(point);
                  }
                });
              },
            );
          }).toList(),
        ),
        ElevatedButton(
          onPressed: widget.selectedPoints.length > 1 ? () {
            widget.buildOptimizedRoute();
          }: null,
          child: Text("Построить маршрут"),
        )
      ],
    );
  }
}