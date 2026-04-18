import 'package:flutter/material.dart';
import 'ant_algoritm.dart';
import 'rating_draw_screen.dart';

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
  MapPoint(name: "Главный корпус ТГУ", x: 289, y: 201),
  MapPoint(name: "Профессор Белкин", x: 293, y: 185)
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
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: ListTile(
            title: Text(
              "Оставить оценку заведению",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RatingDrawScreen(),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
      ],
    );
  }
}