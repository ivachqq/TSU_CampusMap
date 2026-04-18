import 'dart:math';
import 'package:flutter/material.dart';
import 'other_screen.dart';
import 'drow_points.dart';
import 'path.dart';

class Ant {
  final int numPoints;
  List<int> path = [];
  Set<int> unvisited = {};
  double totalDistance = 0;
  int students = 0;

  Ant(this.numPoints, int startNode) {
    path.add(startNode);
    for (int i = 0; i < numPoints; i++) {
      if (i != startNode) unvisited.add(i);
    }
  }

  void visit(int node, double distance) {
    path.add(node);
    unvisited.remove(node);
    totalDistance += distance;
  }
}

class AntSolver{
  static const double alpha = 1.0; //жадность к феромонам
  static const double beta = 2.0; //жадность к пути
  static const double evaporation = 0.5;
  static const double Q = 100.0;
  static const int iterations = 100;

  static List<MapPoint> solveACO(List<MapPoint> selectedPoints) {
    int n = selectedPoints.length;
    if (n < 2) return selectedPoints;

    var distMatrix = calculateDistanceMatrix(selectedPoints);

    var pheromones = List.generate(n, (_) => List.filled(n, 0.1));

    List<int> bestPath = [];
    double bestDistance = double.infinity;

    final random = Random();

    for (int iter = 0; iter < iterations; iter++) {
      List<Ant> ants = List.generate(n, (i) => Ant(n, i));

      for (var ant in ants) {
        while (ant.unvisited.isNotEmpty) {
          int nextNode = _selectNextNode(ant, distMatrix, pheromones, random);
          ant.visit(nextNode, distMatrix[ant.path.last][nextNode]);
        }

        ant.totalDistance += distMatrix[ant.path.last][ant.path.first];

        if (ant.totalDistance < bestDistance) {
          bestDistance = ant.totalDistance;
          bestPath = List.from(ant.path);
        }
      }

      _updatePheromones(pheromones, ants);
    }

    return bestPath.map((index) => selectedPoints[index]).toList();
  }

  static int _selectNextNode(Ant ant, List<List<double>> dists, List<List<double>> phero, Random rand) {
    int current = ant.path.last;
    Map<int, double> probabilities = {};
    double sum = 0.0;

    for (int next in ant.unvisited) {
      double p = pow(phero[current][next], alpha).toDouble() * pow(1.0 / dists[current][next], beta).toDouble();
      probabilities[next] = p;
      sum += p;
    }

    double threshold = rand.nextDouble() * sum;
    double cumulative = 0.0;

    for (var entry in probabilities.entries) {
      cumulative += entry.value;
      if (cumulative >= threshold) return entry.key;
    }
    return ant.unvisited.first;
  }

  static void _updatePheromones(List<List<double>> phero, List<Ant> ants) {
    int n = phero.length;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        phero[i][j] *= (1.0 - evaporation);
      }
    }

    for (var ant in ants) {
      double deposit = Q / ant.totalDistance;
      for (int i = 0; i < ant.path.length - 1; i++) {
        int from = ant.path[i];
        int to = ant.path[i + 1];
        phero[from][to] += deposit;
      }
    }
  }

  static List<List<double>> calculateDistanceMatrix(List<MapPoint> points) {
    int n = points.length;
    List<List<double>> matrix = List.generate(n, (_) => List.filled(n, 0.0));

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i == j) continue;

        var path = AStarSolver.findPath(
            points[i].x, points[i].y,
            points[j].x, points[j].y
        );

        matrix[i][j] = path.isNotEmpty ? path.length.toDouble() : 999999.0;
      }
    }
    return matrix;
  }
}