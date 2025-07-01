import 'package:flutter/material.dart';
import '../../models/agency_product_model.dart';
import '../../services/agency_service.dart';
import 'add_edit_agency_product_screen.dart';
import 'agency_product_variant_screen.dart';

class AgencyProductScreen extends StatefulWidget {
  const AgencyProductScreen({Key? key}) : super(key: key);

  @override
  State<AgencyProductScreen> createState() => _AgencyProductScreenState();
}

class _AgencyProductScreenState extends State<AgencyProductScreen> {
  List<AgencyProduct> products = [];
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
      final result = await AgencyService.getProducts();
      
      if (result['success']) {
        final productsList = result['products'] ?? [];
        setState(() {
          products = productsList;
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

  void _addProduct() async {
    final newProduct = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAgencyProductScreen()),
    );
    if (newProduct != null) {
      _loadProducts();
    }
  }

  void _editProduct(AgencyProduct product) async {
    final updatedProduct = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAgencyProductScreen(product: product),
      ),
    );
    if (updatedProduct != null) {
      _loadProducts();
    }
  }

  void _deleteProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này? Tất cả biến thể của sản phẩm cũng sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final result = await AgencyService.deleteProduct(productId);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Xóa sản phẩm thành công'), backgroundColor: Colors.green),
          );
          _loadProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Lỗi xóa sản phẩm'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Kiểm tra sản phẩm có đủ điều kiện để gửi duyệt không
  bool _canSubmitForApproval(AgencyProduct product) {
    // Kiểm tra thông tin sản phẩm
    if (product.name.isEmpty ||
        product.category.isEmpty ||
        product.genderTarget.isEmpty ||
        product.mainImage == null ||
        product.mainImage!.isEmpty) {
      return false;
    }

    // Kiểm tra có biến thể nào không
    if (product.variants.isEmpty) {
      return false;
    }

    // Kiểm tra từng biến thể
    for (var variant in product.variants) {
      if (variant.sku.isEmpty ||
          variant.price <= 0 ||
          variant.stock <= 0 ||
          variant.status != 'active' ||
          variant.attributes.isEmpty) {
        return false;
      }
    }

    // Kiểm tra trạng thái sản phẩm (chỉ cho phép gửi khi inactive hoặc rejected)
    if (!product.canSubmit) {
      return false;
    }

    return true;
  }

  // Lấy danh sách lỗi validation
  List<String> _getValidationErrors(AgencyProduct product) {
    List<String> errors = [];

    // Kiểm tra thông tin sản phẩm
    if (product.name.isEmpty) {
      errors.add('Tên sản phẩm không được để trống');
    }
    if (product.category.isEmpty) {
      errors.add('Danh mục không được để trống');
    }
    if (product.genderTarget.isEmpty) {
      errors.add('Đối tượng không được để trống');
    }
    if (product.mainImage == null || product.mainImage!.isEmpty) {
      errors.add('Hình ảnh sản phẩm không được để trống');
    }

    // Kiểm tra biến thể
    if (product.variants.isEmpty) {
      errors.add('Sản phẩm phải có ít nhất 1 biến thể');
    } else {
      for (int i = 0; i < product.variants.length; i++) {
        var variant = product.variants[i];
        if (variant.sku.isEmpty) {
          errors.add('Biến thể ${i + 1}: SKU không được để trống');
        }
        if (variant.price <= 0) {
          errors.add('Biến thể ${i + 1}: Giá phải lớn hơn 0');
        }
        if (variant.stock <= 0) {
          errors.add('Biến thể ${i + 1}: Tồn kho phải lớn hơn 0');
        }
        if (variant.status != 'active') {
          errors.add('Biến thể ${i + 1}: Trạng thái phải là active');
        }
        if (variant.attributes.isEmpty) {
          errors.add('Biến thể ${i + 1}: Phải có ít nhất 1 thuộc tính');
        }
      }
    }

    // Kiểm tra trạng thái sản phẩm
    if (!product.canSubmit) {
      errors.add('Chỉ có thể gửi duyệt sản phẩm ở trạng thái không hoạt động hoặc từ chối');
    }

    return errors;
  }

  void _submitForApproval(int productId) async {
    // Tìm sản phẩm
    final product = products.firstWhere((p) => p.id == productId);
    
    // Kiểm tra điều kiện trước khi gửi
    if (!_canSubmitForApproval(product)) {
      final errors = _getValidationErrors(product);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Không thể gửi duyệt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sản phẩm chưa đủ điều kiện để gửi duyệt:'),
              const SizedBox(height: 8),
              ...errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $error', style: const TextStyle(fontSize: 12)),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận gửi duyệt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn gửi sản phẩm "${product.name}" để admin duyệt?'),
            const SizedBox(height: 8),
            Text('• Sản phẩm sẽ chuyển sang trạng thái "Chờ duyệt"'),
            Text('• Tổng số biến thể: ${product.variants.length}'),
            Text('• Tổng tồn kho: ${product.variants.fold<int>(0, (sum, v) => sum + v.stock)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Gửi duyệt'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Hiển thị loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final result = await AgencyService.submitForApproval(productId);
        
        // Đóng loading
        Navigator.pop(context);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gửi duyệt thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProducts(); // Reload danh sách sản phẩm
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi gửi duyệt'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Đóng loading nếu có lỗi
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewProduct(AgencyProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.mainImage != null && product.mainImage!.isNotEmpty)
                Image.network(
                  'http://127.0.0.1/EcommerceClothingApp/API/uploads/${product.mainImage}',
                  height: 180,
                  fit: BoxFit.contain,
                ),
              const SizedBox(height: 8),
              Text('Danh mục: ${product.category}'),
              Text('Đối tượng: ${product.genderTarget}'),
              Text('Mô tả: ${product.description}'),
              Text('Trạng thái: ${product.statusDisplay}'),
              Text('Tổng tồn kho: ${product.variants.fold<int>(0, (sum, v) => sum + (v.stock ?? 0))}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý sản phẩm Agency"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm sản phẩm"),
                  onPressed: _addProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Hình ảnh')),
                      DataColumn(label: Text('Tên sản phẩm')),
                      DataColumn(label: Text('Danh mục')),
                      DataColumn(label: Text('Đối tượng')),
                      DataColumn(label: Text('Tổng tồn kho')),
                      DataColumn(label: Text('Số biến thể')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Hành động')),
                    ],
                    rows: products.map((product) {
                      final variants = product.variants;
                      final totalStock = variants.fold<int>(0, (sum, v) => sum + (v.stock ?? 0));
                      return DataRow(cells: [
                        DataCell(Text(product.id.toString())),
                        DataCell(
                          GestureDetector(
                            onTap: () => _viewProduct(product),
                            child: Container(
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
                                        width: 60,
                                        height: 60,
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
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if ((product.description).isNotEmpty)
                                Text(
                                  product.description,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        DataCell(Text(product.category)),
                        DataCell(Text(product.genderTarget)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: totalStock > 0 ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              totalStock.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(Text(variants.length.toString())),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(product.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              product.statusDisplay,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editProduct(product),
                                tooltip: 'Sửa sản phẩm',
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AgencyProductVariantScreen(
                                        productId: product.id,
                                        productName: product.name,
                                      ),
                                    ),
                                  ).then((_) => _loadProducts());
                                },
                                tooltip: 'Thêm biến thể',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProduct(product.id),
                                tooltip: 'Xóa sản phẩm',
                              ),
                              if (_canSubmitForApproval(product))
                                IconButton(
                                  icon: const Icon(Icons.send, color: Colors.orange),
                                  onPressed: () => _submitForApproval(product.id),
                                  tooltip: 'Gửi duyệt',
                                ),
                              if (!_canSubmitForApproval(product) && product.canSubmit)
                                IconButton(
                                  icon: const Icon(Icons.send, color: Colors.grey),
                                  onPressed: () => _submitForApproval(product.id),
                                  tooltip: 'Chưa đủ điều kiện gửi duyệt',
                                ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'inactive':
        return Colors.grey;
      case 'approved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
} 