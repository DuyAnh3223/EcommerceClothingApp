import 'package:flutter/material.dart';
import '../../models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    // Lấy product từ arguments khi mở màn hình
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    // ... (existing code)

    return Scaffold(
      // ... (existing code)

      body: Column(
        // ... (existing code)

        children: [
          // ... (existing code)

          // Hiển thị danh sách biến thể với giá BACoin nếu có
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Biến thể:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...product.variants.map((v) => Row(
                children: [
                  Text('SKU: ${v.sku}'),
                  SizedBox(width: 8),
                  Text('Giá: ${v.price.toStringAsFixed(0)} VNĐ'),
                  if (v.priceBacoin != null && v.priceBacoin! > 0) ...[
                    SizedBox(width: 8),
                    Text('Giá BACoin: BA ${v.priceBacoin!.toInt()}'),
                  ],
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
} 