import 'package:flutter/material.dart';
import '../../../models/product_combination_model.dart';

class CombinationDetailScreen extends StatelessWidget {
  final ProductCombination combination;
  const CombinationDetailScreen({Key? key, required this.combination}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(combination.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (combination.imageUrl != null)
              Center(
                child: Image.network(combination.imageUrl!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(combination.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (combination.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(combination.description!),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (combination.discountPrice != null)
                  Text('Giá ưu đãi: \\${combination.discountPrice!.toStringAsFixed(0)}đ', style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                if (combination.originalPrice != null)
                  Text('Giá gốc: \\${combination.originalPrice!.toStringAsFixed(0)}đ', style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (combination.categories.isNotEmpty)
              Text('Danh mục: ' + combination.categories.join(', '), style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            const Text('Sản phẩm trong combo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...combination.items.map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: item.productImage != null
                    ? Image.network(item.productImage!, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 50),
                title: Text(item.productName ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.sku != null) Text('SKU: ' + item.sku!),
                    if (item.priceInCombination != null)
                      Text('Giá trong combo: \\${item.priceInCombination!.toStringAsFixed(0)}đ'),
                    if (item.originalPrice != null)
                      Text('Giá lẻ: \\${item.originalPrice!.toStringAsFixed(0)}đ', style: const TextStyle(decoration: TextDecoration.lineThrough)),
                    Text('Số lượng: \\${item.quantity}'),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Thêm vào giỏ hàng
                },
                child: const Text('Thêm combo vào giỏ hàng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 