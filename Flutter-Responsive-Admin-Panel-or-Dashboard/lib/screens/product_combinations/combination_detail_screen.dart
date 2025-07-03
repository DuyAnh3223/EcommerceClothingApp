import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_combination_model.dart';

class CombinationDetailScreen extends StatelessWidget {
  final ProductCombination combination;
  const CombinationDetailScreen({Key? key, required this.combination}) : super(key: key);

  String buildImageUrl(String fileName) {
    // Nếu chạy trên thiết bị/emulator, thay 127.0.0.1 bằng IP LAN của máy chủ
    return 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=$fileName';
  }

  void showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('Hình ảnh: $title'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 8),
                        Text('Lỗi tải hình ảnh', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                child: GestureDetector(
                  onTap: () => showImageDialog(context, buildImageUrl(combination.imageUrl!), combination.name),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: buildImageUrl(combination.imageUrl!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Lỗi tải hình ảnh', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Icon zoom
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        // Hiển thị hình ảnh sản phẩm
                        if (item.productImage != null && item.productImage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: GestureDetector(
                              onTap: () => showImageDialog(context, buildImageUrl(item.productImage!), '${item.productName} - Hình chính'),
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: CachedNetworkImage(
                                        imageUrl: buildImageUrl(item.productImage!),
                                        height: 80,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                    // Icon zoom
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: const Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Hiển thị hình ảnh variant (nếu khác với hình chính)
                        if (item.variantImage != null && item.variantImage!.isNotEmpty && item.variantImage != item.productImage)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hình ảnh variant:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => showImageDialog(context, buildImageUrl(item.variantImage!), '${item.productName} - Variant'),
                                  child: Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.blue.shade300, width: 2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: CachedNetworkImage(
                                            imageUrl: buildImageUrl(item.variantImage!),
                                            height: 60,
                                            width: 60,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                                          ),
                                        ),
                                        // Icon zoom
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(1),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                            child: const Icon(
                                              Icons.zoom_in,
                                              color: Colors.white,
                                              size: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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