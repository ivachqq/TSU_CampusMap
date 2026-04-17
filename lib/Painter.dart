import 'package:flutter/material.dart';
class PathPainter extends CustomPainter {
  final List<Offset> path;
  final Color color;

  PathPainter(this.path, {this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pathObj = Path();
    pathObj.moveTo(path.first.dx, path.first.dy);

    for (int i = 1; i < path.length; i++) {
      pathObj.lineTo(path[i].dx, path[i].dy);
    }

    canvas.drawPath(pathObj, paint);
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => oldDelegate.path != path;
}