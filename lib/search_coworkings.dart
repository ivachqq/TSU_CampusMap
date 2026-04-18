import 'dart:math';

import 'package:flutter/material.dart';
import 'other_screen.dart';
import 'path.dart';
import 'ant_algoritm.dart';

class Coworkings{
  final String name;
  final int x;
  final int y;
  final int comfort;
  final int capacity; //вместимость
  int currentStudents;

  Coworkings({
    required this.name,
    required this.x,
    required this.y,
    required this.comfort,
    required this.capacity,
    this.currentStudents = 0
  });
}

List<Coworkings> coworkings = [
  Coworkings(name: "Пространство IDO", x: 203, y: 248, comfort: 10, capacity: 5),
  Coworkings(name: "Пространство ИТ-школы", x: 203, y: 256, comfort: 8, capacity: 15),
  Coworkings(name: "Переход к главному корпусу", x: 239, y: 226, comfort: 8, capacity: 7),
  Coworkings(name: "Коворкинг ВК", x: 204, y: 253, comfort: 9, capacity: 20),
];

class CoworkingSolver {
  static const double alpha = 1.0; //жадность к феромонам
  static const double beta = 2.0; //жадность к пути
  static const double evaporation = 0.5;
  static const double Q = 100.0;
  static const int iterations = 100;

  static List<Coworkings> solveStudentDistribution (List<Coworkings> coworkings, int groupSize){
    int n = coworkings.length;

    var points = coworkings.map((c) => MapPoint(name: c.name, x: c.x, y: c.y)).toList();
    var distMatrix = AntSolver.calculateDistanceMatrix(points);
    var pheromones = List.generate(n, (_) => List.filled(n, 0.1));
    final random = Random();
    List<Ant> bestAnts = [];

    for (int iter = 0; iter < iterations; iter++) {
      List<Ant> ants = List.generate(n, (i){
        var ant = Ant(n, i);
        ant.students = groupSize;
        return ant;
      });
      for (var ant in ants) {
        while (ant.unvisited.isNotEmpty && ant.students > 0) {
          int nextNode = _selectNextCoworking(ant, distMatrix, pheromones, coworkings, random);
          if (nextNode == -1) break;

          int assignable = min(ant.students, coworkings[nextNode].capacity - coworkings[nextNode].currentStudents);
          if (assignable <= 0) {
            ant.unvisited.remove(nextNode);
            continue;
          }

          coworkings[nextNode].currentStudents += assignable;
          ant.students -= assignable;
          ant.visit(nextNode, distMatrix[ant.path.last][nextNode]);
        }
        bestAnts.add(ant);
      }

      _updatePheromonesForCoworkings(pheromones, bestAnts, coworkings);
    }

    return coworkings.where((c) => c.currentStudents > 0).toList();
  }

  static int _selectNextCoworking(Ant ant, List<List<double>> dists, List<List<double>> phero,
      List<Coworkings> coworkings, Random rand) {
    int current = ant.path.last;
    Map<int, double> probabilities = {};
    double sum = 0.0;

    for (int next in ant.unvisited) {
      int availableSeats = max(0, coworkings[next].capacity - coworkings[next].currentStudents);
      if (availableSeats <= 0) continue;

      double heuristic = (availableSeats / coworkings[next].capacity) * coworkings[next].comfort / (dists[current][next] + 1e-6);
      double p = pow(phero[current][next], alpha).toDouble() * pow(heuristic, beta).toDouble();

      probabilities[next] = p;
      sum += p;
    }

    if (sum == 0) return -1;

    double threshold = rand.nextDouble() * sum;
    double cumulative = 0.0;
    for (var entry in probabilities.entries) {
      cumulative += entry.value;
      if (cumulative >= threshold) return entry.key;
    }

    return -1;
  }

  static void _updatePheromonesForCoworkings(List<List<double>> phero, List<Ant> ants, List<Coworkings> coworkings) {
    int n = phero.length;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        phero[i][j] *= (1.0 - evaporation);
      }
    }

    for (var ant in ants) {
      for (int i = 0; i < ant.path.length - 1; i++) {
        int from = ant.path[i];
        int to = ant.path[i + 1];
        double comfortFactor = coworkings[to].comfort * (coworkings[to].currentStudents / coworkings[to].capacity);
        phero[from][to] += (Q / (ant.totalDistance + 1e-6)) * comfortFactor;
      }
    }
  }
}