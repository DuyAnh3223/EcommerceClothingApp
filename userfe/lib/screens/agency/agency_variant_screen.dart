import 'package:flutter/material.dart';
import '../../models/agency_product_model.dart';
import '../../services/agency_service.dart';
import 'add_edit_agency_variant_screen.dart';

class AgencyVariantScreen extends StatefulWidget {
  final int? productId; // If null, show all variants

  const AgencyVariantScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<AgencyVariantScreen> createState() => _AgencyVariantScreenState();
}

class _AgencyVariantScreenState extends State<AgencyVariantScreen> {
  List<AgencyProductVariant> variants = [];
  AgencyProduct? productInfo;
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
      Map<String, dynamic> result;
      if (widget.productId != null) {
        result = await AgencyService.getProductVariants(productId: widget.productId!);
      } else {
        result = await AgencyService.getAllVariants();
      }

      if (result['success']) {
        final List<AgencyProductVariant> loadedVariants = result['variants'];
        
        setState(() {
          variants = loadedVariants;
          if (result['product'] != null) {
            productInfo = AgencyProduct.fromJson(result['product']);
          }
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
        final result = await AgencyService.deleteVariant(variantId: variantId);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          _loadVariants();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi xóa biến thể'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý biến thể sản phẩm Agency"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Refresh product data when going back
            Navigator.pop(context, true);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Quản lý biến thể sản phẩm Agency",
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
                          builder: (context) => AddEditAgencyVariantScreen(
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
                      Text('Trạng thái: ${productInfo!.status}'),
                      Text('Phí nền tảng: ${productInfo!.platformFeeRate}%'),
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
                      DataColumn(label: Text('Hình ảnh')),
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('Thuộc tính')),
                      DataColumn(label: Text('Giá')),
                      DataColumn(label: Text('Tồn kho')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Hành động')),
                    ],
                    rows: variants.map((variant) {
                      return DataRow(
                        cells: [
                          DataCell(Text(variant.id.toString())),
                          DataCell(
                            GestureDetector(
                              onTap: () {
                                if (variant.imageUrl != null && variant.imageUrl!.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AppBar(
                                              title: Text('Hình ảnh: ${variant.sku}'),
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
                                              child: Image.network(
                                                'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${variant.imageUrl!}',
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) => const Center(
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
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    (variant.imageUrl != null && variant.imageUrl!.isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${variant.imageUrl!}',
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
                                    // Icon zoom khi có hình ảnh
                                    if (variant.imageUrl != null && variant.imageUrl!.isNotEmpty)
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
                          DataCell(Text(variant.sku)),
                          DataCell(Text(variant.attributesDisplay)),
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
                                        builder: (context) => AddEditAgencyVariantScreen(
                                          variant: variant,
                                          productId: (widget.productId ?? variant.productId) ?? -1,
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