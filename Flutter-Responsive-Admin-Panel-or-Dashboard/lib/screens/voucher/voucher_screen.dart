import 'package:flutter/material.dart';
import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';
import '../../constants.dart';
import 'add_edit_voucher_dialog.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({Key? key}) : super(key: key);

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  List<Voucher> vouchers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedVouchers = await VoucherService.getVouchers();
      setState(() {
        vouchers = loadedVouchers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _addVoucher() async {
    final result = await showDialog<Voucher>(
      context: context,
      builder: (context) => const AddEditVoucherDialog(),
    );

    if (result != null) {
      try {
        await VoucherService.addVoucher(result);
        _loadVouchers();
        _showSnackBar('Voucher đã được thêm thành công!', Colors.green);
      } catch (e) {
        _showSnackBar('Lỗi: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _editVoucher(Voucher voucher) async {
    final result = await showDialog<Voucher>(
      context: context,
      builder: (context) => AddEditVoucherDialog(voucher: voucher),
    );

    if (result != null) {
      try {
        await VoucherService.updateVoucher(result);
        _loadVouchers();
        _showSnackBar('Voucher đã được cập nhật thành công!', Colors.green);
      } catch (e) {
        _showSnackBar('Lỗi: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _deleteVoucher(Voucher voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa voucher "${voucher.voucherCode}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await VoucherService.deleteVoucher(voucher.id);
        _loadVouchers();
        _showSnackBar('Voucher đã được xóa thành công!', Colors.green);
      } catch (e) {
        _showSnackBar('Lỗi: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVouchers,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lỗi: $errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVouchers,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : vouchers.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có voucher nào',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(defaultPadding),
                      itemCount: vouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = vouchers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: defaultPadding),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  voucher.voucherCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: voucher.canUse ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    voucher.canUse ? 'Có hiệu lực' : 'Hết hiệu lực',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.discount, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Giảm giá: ${voucher.formattedDiscountAmount}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.inventory, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Số lượng: ${voucher.quantity}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.category, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Loại: ${voucher.formattedVoucherType}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                if (voucher.isForCategoryBased && voucher.categoryFilter != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.filter_list, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Danh mục: ${voucher.categoryFilter}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                                if (voucher.isForSpecificProducts && voucher.associatedProductIds != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.shopping_bag, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sản phẩm: ${voucher.associatedProductIds!.length} sản phẩm',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Từ: ${voucher.formattedStartDate} - Đến: ${voucher.formattedEndDate}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editVoucher(voucher),
                                  tooltip: 'Sửa',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteVoucher(voucher),
                                  tooltip: 'Xóa',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVoucher,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 