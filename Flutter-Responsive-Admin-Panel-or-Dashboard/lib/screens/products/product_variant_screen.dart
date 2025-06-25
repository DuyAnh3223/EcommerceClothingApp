import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_edit_variant_screen.dart';

class ProductVariantScreen extends StatefulWidget {
  final int? productId; // If null, show all variants

  const ProductVariantScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<ProductVariantScreen> createState() => _ProductVariantScreenState();
}

class _ProductVariantScreenState extends State<ProductVariantScreen> {
  List<ProductVariant> variants = [];
  Product? productInfo;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  void _loadVariants() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String url;
      if (widget.productId != null) {
        url = 'http://localhost/clothing_project/tonbaongu/API/products/get_variants.php?product_id=${widget.productId}';
      } else {
        url = 'http://localhost/clothing_project/tonbaongu/API/products/get_variants.php';
      }

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<ProductVariant> loadedVariants = (data['variants'] as List)
              .map((item) => ProductVariant.fromJson(item))
              .toList();
          
          setState(() {
            variants = loadedVariants;
            if (data['product'] != null) {
              productInfo = Product.fromJson(data['product']);
            }
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Lỗi không xác định';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Lỗi kết nối API: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi tải biến thể: $e';
        isLoading = false;
      });
    }
  }

  void _deleteVariant(int variantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa biến thể này?'),
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
        final response = await http.post(
          Uri.parse('http://localhost/clothing_project/tonbaongu/API/products/delete_variant.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'variant_id': variantId}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'])),
            );
            _loadVariants();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Lỗi xóa biến thể')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
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
                  "Quản lý biến thể sản phẩm",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.productId != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Thêm biến thể"),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditVariantScreen(
                            productId: widget.productId!,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadVariants();
                      }
                    },
                  ),
              ],
            ),
            if (productInfo != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sản phẩm: ${productInfo!.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Danh mục: ${productInfo!.category}'),
                      Text('Đối tượng: ${productInfo!.genderTarget}'),
                      Text('Tổng biến thể: ${variants.length}'),
                    ],
                  ),
                ),
              ),
            ],
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
                      onPressed: _loadVariants,
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
                      DataColumn(label: Text('Màu sắc')),
                      DataColumn(label: Text('Kích thước')),
                      DataColumn(label: Text('Chất liệu')),
                      DataColumn(label: Text('Giá')),
                      DataColumn(label: Text('Tồn kho')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Hành động')),
                    ],
                    rows: variants.map((variant) {
                      return DataRow(
                        cells: [
                          DataCell(Text(variant.id.toString())),
                          DataCell(Text(variant.color)),
                          DataCell(Text(variant.size)),
                          DataCell(Text(variant.material)),
                          DataCell(Text(variant.priceFormatted)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: variant.isInStock ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                variant.stock.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: variant.isActive ? Colors.blue : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                variant.status,
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
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditVariantScreen(
                                          variant: variant,
                                          productId: widget.productId ?? variant.productId,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadVariants();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteVariant(variant.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 