import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/agency_product_combo_model.dart';
import '../../../services/agency_product_combo_service.dart';
import 'agency_add_edit_combo_screen.dart';
import 'agency_combo_detail_screen.dart';

class ProductCombinationsScreen extends StatefulWidget {
  const ProductCombinationsScreen({Key? key}) : super(key: key);

  @override
  State<ProductCombinationsScreen> createState() => _ProductCombinationsScreenState();
}

class _ProductCombinationsScreenState extends State<ProductCombinationsScreen> {
  List<ProductCombination> combinations = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'all';
  String selectedCreatorType = 'all';
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;

  String buildImageUrl(String fileName) {
    // Nếu chạy trên thiết bị/emulator, thay 127.0.0.1 bằng IP LAN của máy chủ
    return 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=$fileName';
  }

  String? getCombinationImageUrl(ProductCombination combination) {
    // Ưu tiên hình ảnh tổ hợp nếu có
    if (combination.imageUrl != null && combination.imageUrl!.isNotEmpty) {
      return buildImageUrl(combination.imageUrl!);
    }
    
    // Nếu không có hình ảnh tổ hợp, lấy hình ảnh của sản phẩm đầu tiên
    if (combination.items != null && combination.items.isNotEmpty) {
      final firstItem = combination.items.first;
      
      // Ưu tiên hình ảnh variant nếu có
      if (firstItem.variantImage != null && firstItem.variantImage!.isNotEmpty) {
        return buildImageUrl(firstItem.variantImage!);
      }
      
      // Fallback về hình ảnh sản phẩm
      if (firstItem.productImage != null && firstItem.productImage!.isNotEmpty) {
        return buildImageUrl(firstItem.productImage!);
      }
    }
    
    return null;
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
  void initState() {
    super.initState();
    _loadCombinations();
  }

  Future<void> _loadCombinations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ProductCombinationService.getCombinations(
        status: selectedStatus,
        creatorType: selectedCreatorType,
        page: currentPage,
        limit: 10,
      );

      if (result['success']) {
        setState(() {
          combinations = result['combinations'] ?? [];
          totalItems = result['total'] ?? 0;
          totalPages = ((result['total'] ?? 0) / 10).ceil();
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
        errorMessage = 'Lỗi tải tổ hợp sản phẩm: $e';
        isLoading = false;
      });
    }
  }

  void _createCombination() async {
    final newCombination = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditCombinationScreen(),
      ),
    );
    if (newCombination != null) {
      _loadCombinations();
    }
  }

  void _editCombination(ProductCombination combination) async {
    final updatedCombination = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditCombinationScreen(combination: combination),
      ),
    );
    if (updatedCombination != null) {
      _loadCombinations();
    }
  }

  void _viewCombination(ProductCombination combination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombinationDetailScreen(combination: combination),
      ),
    );
  }

  void _deleteCombination(int combinationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tổ hợp sản phẩm này?'),
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
        final result = await ProductCombinationService.deleteCombination(combinationId);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Xóa tổ hợp thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCombinations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi xóa tổ hợp'),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Quản lý tổ hợp sản phẩm',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tạo tổ hợp'),
                onPressed: _createCombination,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                        DropdownMenuItem(value: 'inactive', child: Text('Không hoạt động')),
                        DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                          currentPage = 1;
                        });
                        _loadCombinations();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Creator type filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCreatorType,
                      decoration: const InputDecoration(
                        labelText: 'Loại người tạo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'agency', child: Text('Agency')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCreatorType = value!;
                          currentPage = 1;
                        });
                        _loadCombinations();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Refresh button
                  IconButton(
                    onPressed: _loadCombinations,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Làm mới',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Content
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
                    onPressed: _loadCombinations,
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            )
          else if (combinations.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có tổ hợp sản phẩm nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Statistics
                  Row(
                    children: [
                      Text(
                        'Tổng cộng: $totalItems tổ hợp',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        'Trang $currentPage / $totalPages',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Combinations list
                  Expanded(
                    child: ListView.builder(
                      itemCount: combinations.length,
                      itemBuilder: (context, index) {
                        final combination = combinations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                final imageUrl = getCombinationImageUrl(combination);
                                if (imageUrl != null) {
                                  showImageDialog(context, imageUrl, combination.name);
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
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: getCombinationImageUrl(combination) != null
                                          ? CachedNetworkImage(
                                              imageUrl: getCombinationImageUrl(combination)!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                              errorWidget: (context, url, error) => const Icon(
                                                Icons.image,
                                                size: 30,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              size: 30,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    // Icon zoom khi có hình ảnh
                                    if (getCombinationImageUrl(combination) != null)
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
                            title: Text(combination.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (combination.description != null && combination.description!.isNotEmpty)
                                  Text(
                                    combination.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(combination.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        combination.statusDisplay,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getCreatorTypeColor(combination.creatorType),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        combination.creatorTypeDisplay,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Danh mục: ${combination.categories.join(", ")}'),
                                Text('Số sản phẩm: ${combination.totalItems}'),
                                if (combination.hasDiscount) ...[
                                  Text(
                                    'Giá gốc: ${combination.originalPrice?.toStringAsFixed(0)} VNĐ',
                                    style: const TextStyle(decoration: TextDecoration.lineThrough),
                                  ),
                                  Text(
                                    'Giá ưu đãi: ${combination.discountPrice?.toStringAsFixed(0)} VNĐ',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Tiết kiệm: ${combination.savings.toStringAsFixed(0)} VNĐ (${combination.savingsPercentage.toStringAsFixed(1)}%)',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ]
                                else if (combination.originalPrice != null) ...[
                                  Text(
                                    'Giá: ${combination.originalPrice!.toStringAsFixed(0)} VNĐ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.blue),
                                  onPressed: () => _viewCombination(combination),
                                  tooltip: 'Xem chi tiết',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _editCombination(combination),
                                  tooltip: 'Sửa',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCombination(combination.id),
                                  tooltip: 'Xóa',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Pagination
                  if (totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: currentPage > 1 ? () {
                            setState(() {
                              currentPage--;
                            });
                            _loadCombinations();
                          } : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Trang $currentPage / $totalPages'),
                        IconButton(
                          onPressed: currentPage < totalPages ? () {
                            setState(() {
                              currentPage++;
                            });
                            _loadCombinations();
                          } : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                ],
              ),
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

  Color _getCreatorTypeColor(String creatorType) {
    switch (creatorType) {
      case 'admin':
        return Colors.blue;
      case 'agency':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
} 