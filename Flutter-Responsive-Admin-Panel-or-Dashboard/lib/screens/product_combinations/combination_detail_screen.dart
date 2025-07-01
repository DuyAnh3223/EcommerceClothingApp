import 'package:flutter/material.dart';
import '../../models/product_combination_model.dart';

class CombinationDetailScreen extends StatelessWidget {
  final ProductCombination combination;
  const CombinationDetailScreen({Key? key, required this.combination}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết tổ hợp')),
      body: Center(child: Text('Tên tổ hợp: [combination.name]')),
    );
  }
} 