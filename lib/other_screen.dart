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
  MapPoint(name: "Геофизический центр Евразии", x: 349, y: 200),
  MapPoint(name: "Каменные бабы (слева)", x: 298, y: 232),
  MapPoint(name: "Каменные бабы (справа)", x: 296, y: 167),
  MapPoint(name: "Главный корпус ТГУ", x: 289, y: 201)
];

class OtherScreen extends StatefulWidget {
  final List<MapPoint> selectedPoints;
  final VoidCallback onChanged;
  final VoidCallback buildOptimizedRoute;
  final void Function(int students)? onGroupSizeSelected;

  const OtherScreen({
    super.key,
    required this.selectedPoints,
    required this.onChanged,
    required this.buildOptimizedRoute,
    this.onGroupSizeSelected,
  });

  @override
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen>{
  final TextEditingController _studentsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          title: Text("Достопримечательности"),
          children: [
            ...mapPoints.map((point) {
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: widget.selectedPoints.length > 1 ? () {
                widget.buildOptimizedRoute();
              }: null,
              child: Text("Построить маршрут"),
            ),
          ),
        ],
        ),
        ExpansionTile(
          title: Text("Найти коворкинг"),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _studentsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Количество студентов",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  int students = int.tryParse(_studentsController.text) ?? 0;
                  if (students > 0) {
                    widget.onGroupSizeSelected?.call(students);
                  }
                },
                child: Text("Поставить стартовую точку и найти коворкинг"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}