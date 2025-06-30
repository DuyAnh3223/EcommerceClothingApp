import 'package:flutter/material.dart';
import '../../models/agency_product_model.dart';
import '../../services/agency_service.dart';
import 'add_edit_agency_product_screen.dart';
import 'components/agency_product_table.dart';

class AgencyProductScreen extends StatefulWidget {
  const AgencyProductScreen({Key? key}) : super(key: key);

  @override
  State<AgencyProductScreen> createState() => _AgencyProductScreenState();
}

class _AgencyProductScreenState extends State<AgencyProductScreen> {
  List<AgencyProduct> products = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await AgencyService.getProducts(status: selectedStatus);
      
      if (!mounted) return;
      
      if (result['success']) {
        final List<AgencyProduct> loadedProducts = result['products'];
        setState(() {
          products = loadedProducts;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Lỗi không xác định';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Lỗi tải sản phẩm: ${e.toString()}';
          isLoading = false;
        });
      }
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await AgencyService.deleteProduct(productId: productId);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          _loadProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Lỗi xóa sản phẩm')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _submitForApproval(int productId) async {
    try {
      final result = await AgencyService.submitForApproval(productId: productId);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Lỗi gửi duyệt'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Quản lý sản phẩm Agency",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm sản phẩm"),
                  onPressed: _addProduct,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Filter buttons
            Row(
              children: [
                const Text('Lọc theo trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: selectedStatus == 'all',
                  onSelected: (selected) {
                    setState(() {
                      selectedStatus = 'all';
                    });
                    _loadProducts();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Chờ duyệt'),
                  selected: selectedStatus == 'pending',
                  onSelected: (selected) {
                    setState(() {
                      selectedStatus = 'pending';
                    });
                    _loadProducts();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đã duyệt'),
                  selected: selectedStatus == 'approved',
                  onSelected: (selected) {
                    setState(() {
                      selectedStatus = 'approved';
                    });
                    _loadProducts();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Từ chối'),
                  selected: selectedStatus == 'rejected',
                  onSelected: (selected) {
                    setState(() {
                      selectedStatus = 'rejected';
                    });
                    _loadProducts();
                  },
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
                  child: AgencyProductTable(
                    products: products,
                    onReload: _loadProducts,
                    onEdit: _editProduct,
                    onDelete: _deleteProduct,
                    onSubmitForApproval: _submitForApproval,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 