import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class AllUserAddressesScreen extends StatefulWidget {
  const AllUserAddressesScreen({Key? key}) : super(key: key);

  @override
  State<AllUserAddressesScreen> createState() => _AllUserAddressesScreenState();
}

class _AllUserAddressesScreenState extends State<AllUserAddressesScreen> {
  List<UserAddress> addresses = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllAddresses();
  }

  Future<void> _loadAllAddresses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // Gọi API lấy tất cả địa chỉ (cần tạo API get_all_addresses.php trả về tất cả địa chỉ)
      final response = await UserService.getAllAddresses();
      setState(() {
        addresses = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tất cả địa chỉ người dùng')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : addresses.isEmpty
                    ? const Center(child: Text('Không có địa chỉ nào'))
                    : ListView.separated(
                        itemCount: addresses.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          return ListTile(
                            leading: addr.isDefault ? const Icon(Icons.star, color: Colors.orange) : null,
                            title: Text(addr.addressLine),
                            subtitle: Text('User ID: ${addr.userId} | ${addr.city}, ${addr.province} ${addr.postalCode ?? ''}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Xóa địa chỉ',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xác nhận'),
                                    content: const Text('Bạn có chắc chắn muốn xóa địa chỉ này?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await UserService.deleteUserAddress(addr.id);
                                  setState(() {
                                    addresses.removeAt(index);
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
} 