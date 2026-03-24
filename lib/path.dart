import 'dart:ui';
import 'map_data_HD.dart';

class Node {
  final int x, y;
  double g = 0;
  double h = 0;
  Node? parent;

  Node(this.x, this.y, {this.parent});

  double get f => g + h;

  @override
  bool operator ==(Object other) => other is Node && x == other.x && y == other.y;
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class AStarSolver {
  static List<Offset> findPath(int startX, int startY, int endX, int endY) {
    List<Node> openList = [];
    Set<Node> closedList = {};

    Node startNode = Node(startX, startY);
    Node endNode = Node(endX, endY);

    openList.add(startNode);

    while (openList.isNotEmpty) {
      Node currentNode = openList.reduce((a, b) => a.f < b.f ? a : b);

      if (currentNode == endNode) {
        return _buildPath(currentNode);
      }

      openList.remove(currentNode);
      closedList.add(currentNode);

      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;

          int nx = currentNode.x + dx;
          int ny = currentNode.y + dy;

          if (nx < 0 || nx >= RoshaMap.width || ny < 0 || ny >= RoshaMap.height) continue;
          if (RoshaMap.grid[ny * RoshaMap.width + nx] != 0) continue;

          Node neighbor = Node(nx, ny, parent: currentNode);
          if (closedList.contains(neighbor)) continue;

          double moveCost = (dx == 0 || dy == 0) ? 1.0 : 1.4;
          double tentativeG = currentNode.g + moveCost;

          Node? existingNode = openList.firstWhere(
                  (n) => n == neighbor,
              orElse: () => Node(-1, -1)
          );

          if (existingNode.x == -1 || tentativeG < existingNode.g) {
            neighbor.g = tentativeG;
            neighbor.h = ((neighbor.x - endNode.x).abs() + (neighbor.y - endNode.y).abs()).toDouble();

            if (existingNode.x == -1) openList.add(neighbor);
          }
        }
      }
    }
    return [];
  }

  static List<Offset> _buildPath(Node? endNode) {
    List<Offset> path = [];
    Node? temp = endNode;
    while (temp != null) {
      path.add(Offset(temp.x.toDouble(), temp.y.toDouble()));
      temp = temp.parent;
    }
    return path.reversed.toList();
  }
}