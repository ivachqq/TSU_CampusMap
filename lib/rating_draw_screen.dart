import 'package:flutter/material.dart';

class RatingDrawScreen extends StatefulWidget {
  const RatingDrawScreen({super.key});

  @override
  State<RatingDrawScreen> createState() => _RatingDrawScreenState();
}

class _RatingDrawScreenState extends State<RatingDrawScreen> {
  List<List<int>> grid = [
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ];
  void changePixel(int row, int col) {
    setState(() {
      if (grid[row][col] == 0) {
        grid[row][col] = 1;
      } else {
        grid[row][col] = 0;
      }
    });
  }
  void clearAll() {
    setState(() {
      grid = [
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
      ];
    });
  }
  void recognize() {
    List<int> allPixels = [];
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        allPixels.add(grid[row][col]);
      }
    }
    print(allPixels);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Оценка заведению'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 5,
              padding: EdgeInsets.all(16),
              children: [
                for (int row = 0; row < 5; row++)
                  for (int col = 0; col < 5; col++)
                    GestureDetector(
                      onTap: () {
                        changePixel(row, col);
                      },
                      child: Container(
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: grid[row][col] == 1 ? Colors.black : Colors.white,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: clearAll,
                    child: Text('Очистить'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: recognize,
                    child: Text('Распознать'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}