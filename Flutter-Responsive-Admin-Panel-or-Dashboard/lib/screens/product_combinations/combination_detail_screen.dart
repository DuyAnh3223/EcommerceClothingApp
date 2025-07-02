import 'package:flutter/material.dart';
import '../../models/product_combination_model.dart';

class CombinationDetailScreen extends StatelessWidget {
  final ProductCombination combination;
  const CombinationDetailScreen({Key? key, required this.combination}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết tổ hợp')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Tên tổ hợp: ${combination.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (combination.description != null && combination.description!.isNotEmpty)
              Text(
                'Mô tả: ${combination.description}',
                style: const TextStyle(fontSize: 16),
              ),
            if (combination.imageUrl != null && combination.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Image.network(
                  combination.imageUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Các sản phẩm trong tổ hợp:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (combination.items == null || combination.items.isEmpty)
              const Text('Không có sản phẩm nào trong tổ hợp này.'),
            if (combination.items != null && combination.items.isNotEmpty)
              ...combination.items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$idx. ${item.productName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (item.productImage != null && item.productImage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Image.network(
                              item.productImage!,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        if (item.variantImage != null && item.variantImage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Image.network(
                              item.variantImage!,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24),
                            ),
                          ),
                        Text('Giá: ${(item.priceInCombination ?? item.originalPrice)?.toStringAsFixed(0) ?? 'N/A'} đ'),
                        if (item.color != null && item.color!.isNotEmpty) Text('Màu: ${item.color}'),
                        if (item.size != null && item.size!.isNotEmpty) Text('Size: ${item.size}'),
                        if (item.brand != null && item.brand!.isNotEmpty) Text('Thương hiệu: ${item.brand}'),
                        if (item.sku != null && item.sku!.isNotEmpty) Text('SKU: ${item.sku}'),
                        if (item.genderTarget != null && item.genderTarget!.isNotEmpty) Text('Giới tính: ${item.genderTarget}'),
                        if (item.productCategory.isNotEmpty) Text('Danh mục: ${item.productCategory}'),
                        Text('Số lượng: ${item.quantity}'),
                        Text('Tồn kho: ${item.stock}'),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}