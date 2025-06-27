import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class AllUserAddressesScreen extends StatefulWidget {
  final int userId;
  final String username;
  const AllUserAddressesScreen({Key? key, required this.userId, required this.username}) : super(key: key);

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
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      addresses = await UserService.getUserAddresses(widget.userId);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi: $e';
        isLoading = false;
      });
    }
  }

  void _showAddressDialog({UserAddress? address}) async {
    final result = await showDialog<UserAddress>(
      context: context,
      builder: (context) => _AddressDialog(
        address: address,
        userId: widget.userId,
      ),
    );
    if (result != null) {
      await _loadAddresses();
    }
  }

  void _deleteAddress(int addressId) async {
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
      final success = await UserService.deleteUserAddress(addressId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa địa chỉ thành công')));
        await _loadAddresses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa địa chỉ thất bại')));
      }
    }
  }

  void _setDefaultAddress(UserAddress address) async {
    final success = await UserService.updateUserAddress(address.copyWith(isDefault: true));
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật địa chỉ mặc định thành công')));
      await _loadAddresses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật địa chỉ thất bại')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Địa chỉ của ${widget.username}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Danh sách địa chỉ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm địa chỉ'),
                            onPressed: () => _showAddressDialog(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: addresses.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final addr = addresses[index];
                            return ListTile(
                              leading: addr.isDefault ? const Icon(Icons.star, color: Colors.orange) : null,
                              title: Text(addr.addressLine),
                              subtitle: Text('${addr.city}, ${addr.province} ${addr.postalCode ?? ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!addr.isDefault)
                                    IconButton(
                                      icon: const Icon(Icons.star_border),
                                      tooltip: 'Đặt làm mặc định',
                                      onPressed: () => _setDefaultAddress(addr),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showAddressDialog(address: addr),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAddress(addr.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _AddressDialog extends StatefulWidget {
  final UserAddress? address;
  final int userId;
  const _AddressDialog({this.address, required this.userId});

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController addressLineController;
  late TextEditingController cityController;
  late TextEditingController provinceController;
  late TextEditingController postalCodeController;
  bool isDefault = false;

  @override
  void initState() {
    super.initState();
    addressLineController = TextEditingController(text: widget.address?.addressLine ?? '');
    cityController = TextEditingController(text: widget.address?.city ?? '');
    provinceController = TextEditingController(text: widget.address?.province ?? '');
    postalCodeController = TextEditingController(text: widget.address?.postalCode ?? '');
    isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    addressLineController.dispose();
    cityController.dispose();
    provinceController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final addr = UserAddress(
        id: widget.address?.id ?? 0,
        userId: widget.userId,
        addressLine: addressLineController.text,
        city: cityController.text,
        province: provinceController.text,
        postalCode: postalCodeController.text,
        isDefault: isDefault,
        createdAt: widget.address?.createdAt ?? '',
      );
      bool success;
      if (widget.address == null) {
        success = await UserService.addUserAddress(addr);
      } else {
        success = await UserService.updateUserAddress(addr);
      }
      if (success) {
        Navigator.pop(context, addr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.address == null ? 'Thêm địa chỉ thành công' : 'Cập nhật địa chỉ thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.address == null ? 'Thêm địa chỉ' : 'Sửa địa chỉ'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: addressLineController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
              ),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'Thành phố'),
                validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
              ),
              TextFormField(
                controller: provinceController,
                decoration: const InputDecoration(labelText: 'Tỉnh/Quận/Huyện'),
                validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
              ),
              TextFormField(
                controller: postalCodeController,
                decoration: const InputDecoration(labelText: 'Mã bưu điện'),
              ),
              CheckboxListTile(
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v ?? false),
                title: const Text('Đặt làm mặc định'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
} 