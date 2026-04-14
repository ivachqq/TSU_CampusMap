import 'package:flutter/material.dart';
import 'other_screen.dart';

class SelectedPointsLayer extends StatelessWidget {
  final List<MapPoint> selectedPoints;
  final int gridW;
  final int gridH;
  final double mapWidth;
  final double mapHeight;

  const SelectedPointsLayer({
    super.key,
    required this.selectedPoints,
    required this.gridW,
    required this.gridH,
    this.mapWidth = 320,
    this.mapHeight = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (gridW == 0 || gridH == 0 || selectedPoints.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: selectedPoints.map((point) {
          final double drawX = (point.x / gridW) * mapWidth;
          final double drawY = (point.y / gridH) * mapHeight;

          return Positioned(
            left: drawX - 4,
            top: drawY - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
