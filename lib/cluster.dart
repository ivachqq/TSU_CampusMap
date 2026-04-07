import 'dart:math';
import 'dart:ui';
import 'cafe_data.dart';

class Point {
  final double x;
  final double y;
  Point(this.x, this.y);
}

class KMeanClustering 
 {
  List<Cafe> cluster(
    List<Cafe> cafes,
    List<Offset> pixelCentroids,
    int gridW,
    int gridH,
    double mapWidth,
    double mapHeight,
  ) {
     if (cafes.isEmpty || pixelCentroids.isEmpty) return cafes;
     int k = pixelCentroids.length;
     List<Point> centers = pixelCentroids.map((p) {
      double gridX = (p.dx / mapWidth) * gridW; //перевод пикселя в координаты сетки
      double gridY = (p.dy / mapHeight) * gridH;
      return Point(gridX, gridY);
    }).toList();

    bool changed = true;
    int maxIterations = 100;
    int iteration = 0; 

    while (changed && iteration < maxIterations) {
      changed = false;
      for (int i = 0; i < cafes.length; i++) {
        int nearest = findNearestCenter(cafes[i], centers);
        if (cafes[i].clusterId != nearest) {
          cafes[i].clusterId = nearest;
          changed = true;
        }
      }
      centers = recalculateCenters(cafes, k);
      iteration++;
  }
  return cafes;
}

  int findNearestCenter(Cafe cafe, List<Point> centers) {
    int nearest = 0;
    double minDist = distance(cafe.gridX, cafe.gridY, centers[0].x, centers[0].y);
    
    for (int i = 1; i < centers.length; i++) {
      double dist = distance(cafe.gridX, cafe.gridY, centers[i].x, centers[i].y);
      if (dist < minDist) {
        minDist = dist;
        nearest = i;
      }
    }
    return nearest;
  }

  List<Point> recalculateCenters(List<Cafe> cafes, int k) {
    List<Point> newCenters = [];
    
    for (int cluster = 0; cluster < k; cluster++) {
      List<Cafe> clusterCafes = cafes.where((c) => c.clusterId == cluster).toList();
      
      if (clusterCafes.isEmpty) {
        newCenters.add(Point(0, 0));
      } else {
        double sumX = 0;
        double sumY = 0;
        for (var cafe in clusterCafes) {
          sumX += cafe.gridX;
          sumY += cafe.gridY;
        }
        newCenters.add(Point(sumX / clusterCafes.length, sumY / clusterCafes.length));
      }
    }
    return newCenters;
  }
  double distance(int x1, int y1, double x2, double y2) {
    double dx = x1 - x2;
    double dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }
}


