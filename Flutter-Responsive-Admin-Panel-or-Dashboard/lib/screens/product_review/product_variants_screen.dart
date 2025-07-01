import 'package:flutter/material.dart';
import '../../models/pending_product_model.dart';

class ProductVariantsScreen extends StatelessWidget {
  final PendingProduct product;

  const ProductVariantsScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biến thể - ${product.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: (product.mainImage != null && product.mainImage!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${product.mainImage}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('ID: ${product.id}'),
                          Text('Danh mục: ${product.category}'),
                          Text('Đối tượng: ${product.genderTarget}'),
                          Text('Agency: ${product.agencyName}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Variants count
            Row(
              children: [
                const Text(
                  'Danh sách biến thể',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${product.variants.length} biến thể',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Variants list
            Expanded(
              child: product.variants.isEmpty
                  ? const Center(
                      child: Column(
                        children: [
                          Icon(Icons.inventory, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Không có biến thể nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: product.variants.length,
                      itemBuilder: (context, index) {
                        final variant = product.variants[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Variant header
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: (variant.imageUrl != null && variant.imageUrl!.isNotEmpty)
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${variant.imageUrl}',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.image,
                                                  size: 30,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              size: 30,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Biến thể ${index + 1}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          Text('ID: ${variant.variantId}'),
                                          Text('SKU: ${variant.sku}'),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(variant.variantStatus),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(variant.variantStatus),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Variant details
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailCard(
                                        'Giá',
                                        '${variant.price.toStringAsFixed(0)} VNĐ',
                                        Icons.attach_money,
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDetailCard(
                                        'Tồn kho',
                                        variant.stock.toString(),
                                        Icons.inventory,
                                        variant.stock > 0 ? Colors.blue : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      case 'pending':
        return 'Chờ duyệt';
      default:
        return status;
    }
  }
} 