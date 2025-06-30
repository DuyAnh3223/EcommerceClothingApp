import 'package:flutter/material.dart';
import '../../../models/agency_product_model.dart';

class AgencyProductTable extends StatelessWidget {
  final List<AgencyProduct> products;
  final VoidCallback onReload;
  final Function(AgencyProduct) onEdit;
  final Function(int) onDelete;
  final Function(int) onSubmitForApproval;

  const AgencyProductTable({
    Key? key,
    required this.products,
    required this.onReload,
    required this.onEdit,
    required this.onDelete,
    required this.onSubmitForApproval,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Hình ảnh')),
        DataColumn(label: Text('Tên sản phẩm')),
        DataColumn(label: Text('Danh mục')),
        DataColumn(label: Text('Đối tượng')),
        DataColumn(label: Text('Số biến thể')),
        DataColumn(label: Text('Trạng thái')),
        DataColumn(label: Text('Phí nền tảng')),
        DataColumn(label: Text('Ngày tạo')),
        DataColumn(label: Text('Hành động')),
      ],
      rows: products.map((product) {
        return DataRow(
          cells: [
            DataCell(Text(product.id.toString())),
            DataCell(
              GestureDetector(
                onTap: () {
                  if (product.mainImage != null && product.mainImage!.isNotEmpty) {
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
                                title: Text('Hình ảnh: ${product.name}'),
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
                                  'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${product.mainImage!}',
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
                      (product.mainImage != null && product.mainImage!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${product.mainImage!}',
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
                      if (product.mainImage != null && product.mainImage!.isNotEmpty)
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
            DataCell(
              Tooltip(
                message: product.description ?? 'Không có mô tả',
                child: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(Text(product.category)),
            DataCell(Text(product.genderTarget)),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.variants.length.toString(),
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(product.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(product.status),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            DataCell(
              Text(
                '${product.platformFeeRate}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            DataCell(Text(product.createdAt)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút xem biến thể
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.blue),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/agency/variants',
                        arguments: product.id,
                      );
                    },
                    tooltip: 'Xem biến thể',
                  ),
                  // Nút sửa (chỉ hiển thị khi chưa gửi duyệt)
                  if (product.status == 'draft' || product.status == 'rejected')
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => onEdit(product),
                      tooltip: 'Sửa sản phẩm',
                    ),
                  // Nút gửi duyệt (chỉ hiển thị khi chưa gửi duyệt)
                  if (product.status == 'draft' || product.status == 'rejected')
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.green),
                      onPressed: () => onSubmitForApproval(product.id),
                      tooltip: 'Gửi duyệt',
                    ),
                  // Nút xóa (chỉ hiển thị khi chưa được duyệt)
                  if (product.status != 'approved' && product.status != 'active')
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDelete(product.id),
                      tooltip: 'Xóa sản phẩm',
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
} 