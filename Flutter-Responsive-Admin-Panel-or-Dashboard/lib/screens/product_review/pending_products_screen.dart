import 'package:flutter/material.dart';
import '../../models/pending_product_model.dart';
import '../../services/pending_product_service.dart';
import 'product_variants_screen.dart';
import 'review_product_dialog.dart';

class PendingProductsScreen extends StatefulWidget {
  final VoidCallback? onProductReviewed;

  const PendingProductsScreen({Key? key, this.onProductReviewed}) : super(key: key);

  @override
  State<PendingProductsScreen> createState() => _PendingProductsScreenState();
}

class _PendingProductsScreenState extends State<PendingProductsScreen> {
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
      final result = await PendingProductService.getProductsByStatus('pending');
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
                      'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${product.mainImage}',
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

  void _viewVariants(PendingProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductVariantsScreen(
          product: product,
        ),
      ),
    );
  }

  void _reviewProduct(PendingProduct product, String action) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReviewProductDialog(
        product: product,
        action: action,
      ),
    );

    if (result != null && result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Thao tác thành công'),
          backgroundColor: Colors.green,
        ),
      );
      _loadProducts(); // Reload danh sách sản phẩm
      widget.onProductReviewed?.call(); // Update counts
    } else if (result != null && !result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Thao tác thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                'Sản phẩm chờ duyệt',
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
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có sản phẩm nào chờ duyệt',
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
                                  'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${product.mainImage}',
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
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () => _viewProductDetails(product),
                            tooltip: 'Xem chi tiết',
                          ),
                          IconButton(
                            icon: const Icon(Icons.list, color: Colors.green),
                            onPressed: () => _viewVariants(product),
                            tooltip: 'Xem biến thể',
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _reviewProduct(product, 'approve'),
                            tooltip: 'Duyệt',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _reviewProduct(product, 'reject'),
                            tooltip: 'Từ chối',
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
    );
  }
} 