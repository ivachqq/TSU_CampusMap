import 'package:flutter/material.dart';
import 'dart:math';


// Создаем ноду
class DecisionNode {
  String? feature;
  Map<String, DecisionNode>? children;
  String? result;
  DecisionNode({this.feature, this.children, this.result});
  bool get isLeaf => result != null;
}

class DecisionTreeScreen extends StatefulWidget {
  const DecisionTreeScreen({super.key});
  @override
  State<DecisionTreeScreen> createState() => _DecisionTreeScreenState();
}
class _DecisionTreeScreenState extends State<DecisionTreeScreen> {
  // находим самый оптимальный вопрос
  String _getBestFeature(List<Map<String, String>> data, List<String> features) {
    double baseEntropy = _entropy(data);
    String bestFeature = features[0];
    double maxGain = -1.0;
    for (int i = 0; i < features.length; i++) {
      String currentFeat = features[i];
      double currentFeatEntropy = 0;
      Set<String> uniqueValues = {};
      for (int j = 0; j < data.length; j++) {
        String val = data[j][currentFeat]!;
        uniqueValues.add(val);
      }
      for (String val in uniqueValues) {
        List<Map<String, String>> subset = [];
        for (int k = 0; k < data.length; k++) {
          if (data[k][currentFeat] == val) {
            subset.add(data[k]);
          }
        }
        double weight = subset.length / data.length;
        currentFeatEntropy = currentFeatEntropy + (weight * _entropy(subset));
      }
      double gain = baseEntropy - currentFeatEntropy;
      if (gain > maxGain) {
        maxGain = gain;
        bestFeature = currentFeat;
      }
    }
    return bestFeature;
  }
  // функция мощнсти вопроса
  double _entropy(List<Map<String, String>> data) {
    if (data.isEmpty) return 0;

    Map<String, int> counts = {};
    for (var row in data) {
      String res = row['recommended_place']!;
      counts[res] = (counts[res] ?? 0) + 1;
    }

    double entropy = 0;
    for (var count in counts.values) {
      double p = count / data.length;
      entropy -= p * (log(p) / log(2));
    }
    return entropy;
  }
  //csv файл
  final String _rawTrainingData =
      "location,budget,time_available,food_type,queue_tolerance,weather,recommended_place\n"
      "main_building,low,medium,full_meal,medium,good,Main_Cafeteria\n"
      "main_building,low,short,snack,low,good,Yarche\n"
      "main_building,medium,short,coffee,low,good,Bus_Stop_Coffee\n"
      "main_building,high,medium,coffee,medium,good,Starbooks\n"
      "second_building,low,very_short,snack,low,good,Vending_Machine\n"
      "second_building,medium,short,coffee,medium,good,Second_Building_Cafe\n"
      "second_building,medium,medium,full_meal,medium,good,Main_Cafeteria\n"
      "second_building,low,short,snack,low,bad,Vending_Machine\n"
      "campus_center,medium,short,pancakes,medium,good,Siberian_Pancakes";

  DecisionNode? root;
  String resultPlace = "";
  List<String> decisionPath = [];
  String treeStructure = "";

  Map<String, String> userInputs = {
    'location': 'main_building',
    'budget': 'low',
    'time_available': 'medium',
    'food_type': 'full_meal',
    'queue_tolerance': 'medium',
    'weather': 'good'
  };

  @override
  void initState() {
    super.initState();
    _initAlgorithm();
  }

  void _initAlgorithm() {
    try {
      _buildTree();
      _generateTreeVisual();
    } catch (e) {
      print("Ошибка при сборке дерева: $e");
    }
  }

  void _predict() {
    List<String> path = [];
    DecisionNode? current = root;

    if (current == null) return;

    while (current != null && !current.isLeaf) {
      String? attr = current.feature;
      String? userChoice = userInputs[attr];

      if (attr == null || userChoice == null) break;

      path.add("Признак: [$attr] → Выбрали: '$userChoice'");

      if (current.children != null && current.children!.containsKey(userChoice)) {
        current = current.children![userChoice];
      } else {
        path.add("⚠ Ветка '$userChoice' не найдена в обучении");
        current = null;
      }
    }

    setState(() {
      decisionPath = path;
      resultPlace = (current != null && current.isLeaf) ? current.result! : "Неизвестно (мало данных)";
    });
  }

  // проверка
  Widget _buildSafePicker(String label, String key, List<String> options) {
    if (!options.contains(userInputs[key])) {
      userInputs[key] = options.first;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          DropdownButton<String>(
            value: userInputs[key],
            style: const TextStyle(color: Colors.blue, fontSize: 13),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => userInputs[key] = val);
            },
          ),
        ],
      ),
    );
  }
  //тоже визуал
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("СТРУКТУРА ДЕРЕВА", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(treeStructure, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black87)),
            ),
            const Divider(height: 32),

            const Text("НАСТРОЙКИ ВЫБОРА", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),


            _buildSafePicker("Местоположение", "location", ["main_building", "second_building", "campus_center", "bus_stop"]),
            _buildSafePicker("Бюджет", "budget", ["low", "medium", "high"]),
            _buildSafePicker("Время", "time_available", ["very_short", "short", "medium"]),
            _buildSafePicker("Тип еды", "food_type", ["full_meal", "snack", "pancakes", "coffee"]),
            _buildSafePicker("Очередь", "queue_tolerance", ["low", "medium", "high"]),
            _buildSafePicker("Погода", "weather", ["good", "bad"]),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _predict,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("РАССЧИТАТЬ ПУТЬ", style: TextStyle(color: Colors.white)),
              ),
            ),

            if (resultPlace.isNotEmpty) _buildResultSection(),
          ],
        ),
      ),
    );
  }
  //тож визуал
  Widget _buildResultSection() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ИТОГОВОЕ РЕШЕНИЕ:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(resultPlace.replaceAll('_', ' '), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
          const Divider(height: 24),
          const Text("ЛОГИЧЕСКИЙ ПУТЬ ПО УЗЛАМ:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...decisionPath.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.arrow_right, size: 16, color: Colors.blue),
                Expanded(child: Text(step, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // визуал дерева
  void _generateTreeVisual() {
    String buffer = "";
    void walk(DecisionNode node, String indent) {
      if (node.isLeaf) {
        buffer += "$indent└── () ${node.result}\n";
        return;
      }
      buffer += "$indent? ${node.feature}\n";
      node.children?.forEach((val, child) {
        buffer += "$indent  ├─ '$val':\n";
        walk(child, "$indent  │  ");
      });
    }
    if (root != null) walk(root!, "");
    setState(() => treeStructure = buffer);
  }
// парсим csv и заполняем словари
  void _buildTree() {
    List<String> lines = _rawTrainingData.trim().split('\n');
    List<String> headers = lines[0].split(',');
    List<Map<String, String>> data = [];
    for (int i = 1; i < lines.length; i++) {
      var vals = lines[i].split(',');
      Map<String, String> row = {};
      for (int j = 0; j < headers.length; j++) {
        String key = headers[j].trim();
        String value = vals[j].trim();
        row[key] = value;
      }
      data.add(row);
    }
    root = _calculateID3(data, headers.sublist(0, headers.length - 1));
  }
  //сама функция
  DecisionNode _calculateID3(List<Map<String, String>> data, List<String> features) {
    Set<String> uniqueResults = {};
    for (int i = 0; i < data.length; i++) {
      String place = data[i]['recommended_place']!;
      uniqueResults.add(place);
    }

    if (uniqueResults.length == 1) {
      return DecisionNode(result: uniqueResults.first);
    }
    if (features.isEmpty) {
      return DecisionNode(result: "Не определено");
    }

    String bestFeat = _getBestFeature(data, features);

    Map<String, DecisionNode> branches = {};

    Set<String> possibleValues = {};
    for (int i = 0; i < data.length; i++) {
      String value = data[i][bestFeat]!;
      possibleValues.add(value);
    }

    for (String val in possibleValues) {

      List<Map<String, String>> subset = [];
      for (int i = 0; i < data.length; i++) {
        if (data[i][bestFeat] == val) {
          subset.add(data[i]);
        }
      }

      if (subset.isEmpty) continue;

      List<String> remainingFeatures = [];
      for (int i = 0; i < features.length; i++) {
        if (features[i] != bestFeat) {
          remainingFeatures.add(features[i]);
        }
      }
      DecisionNode nextNode = _calculateID3(subset, remainingFeatures);
      branches[val] = nextNode;
    }
    return DecisionNode(feature: bestFeat, children: branches);
  }
}