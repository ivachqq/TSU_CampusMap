import 'package:flutter/material.dart';

class RatingDrawScreen extends StatefulWidget {
  const RatingDrawScreen({super.key});

  @override
  State<RatingDrawScreen> createState() => _RatingDrawScreenState();
}

class _RatingDrawScreenState extends State<RatingDrawScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оценка заведению'),
      ),
      body: Center(
        child: Text('Здесь будет рисовалка 5×5'),
      ),
    );
  }
}