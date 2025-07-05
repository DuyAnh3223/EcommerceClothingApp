import 'package:flutter/material.dart';
import '../../models/bacoin_package_model.dart';
import '../../services/bacoin_package_service.dart';
import '../../constants.dart';
import 'add_edit_package_dialog.dart';

class BacoinPackageScreen extends StatefulWidget {
  const BacoinPackageScreen({Key? key}) : super(key: key);

  @override
  State<BacoinPackageScreen> createState() => _BacoinPackageScreenState();
}

class _BacoinPackageScreenState extends State<BacoinPackageScreen> {
  List<BacoinPackage> packages = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedPackages = await BacoinPackageService.getPackages();
      setState(() {
        packages = loadedPackages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _addPackage() async {
    final result = await showDialog<BacoinPackage>(
      context: context,
      builder: (context) => const AddEditPackageDialog(),
    );

    if (result != null) {
      try {
        await BacoinPackageService.addPackage(result);
        _loadPackages();
        _showSnackBar('Gói BACoin đã được thêm thành công!', Colors.green);
      } catch (e) {
        _showSnackBar('Lỗi: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _editPackage(BacoinPackage package) async {
    final result = await showDialog<BacoinPackage>(
      context: context,
      builder: (context) => AddEditPackageDialog(package: package),
    );

    if (result != null) {
      try {
        await BacoinPackageService.updatePackage(result);
        _loadPackages();
        _showSnackBar('Gói BACoin đã được cập nhật thành công!', Colors.green);
      } catch (e) {
        _showSnackBar('Lỗi: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _deletePackage(BacoinPackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa gói "${package.packageName}"?'),
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
        await BacoinPackageService.deletePackage(package.id);
        _loadPackages();
        _showSnackBar('Gói BACoin đã được xóa thành công!', Colors.green);
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
        title: const Text('Quản lý Gói BACoin'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPackages,
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
                        onPressed: _loadPackages,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : packages.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có gói BACoin nào',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(defaultPadding),
                      itemCount: packages.length,
                      itemBuilder: (context, index) {
                        final package = packages[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: defaultPadding),
                          child: ListTile(
                            title: Text(
                              package.packageName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.attach_money, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Giá: ${package.priceVnd.toStringAsFixed(0)} VNĐ',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'BACoin: ${package.bacoinAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                if (package.description != null && package.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    package.description!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editPackage(package),
                                  tooltip: 'Sửa',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePackage(package),
                                  tooltip: 'Xóa',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPackage,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 