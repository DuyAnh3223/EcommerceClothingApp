import 'package:flutter/material.dart';
import '../../models/pending_product_model.dart';
import '../../services/pending_product_service.dart';

class ApprovedProductsScreen extends StatefulWidget {
  final VoidCallback? onProductReviewed;

  const ApprovedProductsScreen({Key? key, this.onProductReviewed}) : super(key: key);

  @override
  State<ApprovedProductsScreen> createState() => _ApprovedProductsScreenState();
}

class _ApprovedProductsScreenState extends State<ApprovedProductsScreen> {
  List<PendingProduct> products = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await PendingProductService.getProductsByStatus('approved');
      if (result['success']) {
        setState(() {
          products = result['products'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Lỗi không xác định';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi tải sản phẩm: $e';
        isLoading = false;
      });
    }
  }

  void _viewProductDetails(PendingProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.mainImage != null && product.mainImage!.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'http://127.0.0.1/EcommerceClothingApp/API/uploads/${product.mainImage}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text('ID: ${product.id}'),
              Text('Danh mục: ${product.category}'),
              Text('Đối tượng: ${product.genderTarget}'),
              Text('Mô tả: ${product.description}'),
              Text('Agency: ${product.agencyName}'),
              Text('Email: ${product.agencyEmail}'),
              Text('Số biến thể: ${product.variants.length}'),
              if (product.reviewerName != null) Text('Người duyệt: ${product.reviewerName}'),
              if (product.reviewedAt != null) Text('Ngày duyệt: ${product.reviewedAt}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sản phẩm đã duyệt',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                tooltip: 'Làm mới',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Center(
              child: Column(
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadProducts,
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            )
          else if (products.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có sản phẩm nào đã duyệt',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: (product.mainImage != null && product.mainImage!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  'http://127.0.0.1/EcommerceClothingApp/API/uploads/${product.mainImage}',
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
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Danh mục: ${product.category}'),
                          Text('Đối tượng: ${product.genderTarget}'),
                          Text('Agency: ${product.agencyName}'),
                          Text('Số biến thể: ${product.variants.length}'),
                          if (product.reviewerName != null) Text('Người duyệt: ${product.reviewerName}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _viewProductDetails(product),
                        tooltip: 'Xem chi tiết',
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 