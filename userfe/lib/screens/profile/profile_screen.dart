import 'package:flutter/material.dart';
import 'package:userfe/services/auth_service.dart';
import 'package:userfe/screens/auth/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:userfe/screens/profile/payment_history_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:userfe/screens/profile/buy_coin_screen.dart';
import 'package:userfe/screens/profile/buy_coin_history_screen.dart';
import 'package:userfe/screens/withdraw/withdraw_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;
  double? personalAccountBalance;
  double? coinBalance;
  bool isCoinLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCoinBalance();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    
    final localData = await AuthService.getUserData();
    
    if (localData != null) {
      // Fetch fresh data from server
      final result = await AuthService.getUser(userId: localData['id']);
      
      if (result['success'] == true && result['data'] != null) {
        // Lưu lại user data và role mới nhất vào local
        await AuthService.saveUserData(result['data']);
        if (mounted) {
          setState(() {
            userData = result['data'];
          });
        }
      } else {
        // Fallback to local data if server fails
        if (mounted) {
          setState(() {
            userData = localData;
          });
        }
      }
      
      // Load addresses after user data is loaded
      await _loadAddresses();
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAddresses() async {
    if (userData == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }
    
    try {
      final result = await AuthService.getUserAddresses(userId: userData!['id']);
      
      if (mounted) {
        setState(() {
          if (result['success'] == true && result['data'] != null) {
            addresses = List<Map<String, dynamic>>.from(result['data']);
          } else {
            addresses = [];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          addresses = [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang đăng xuất...'),
                    backgroundColor: Colors.orange,
                  ),
                );

                try {
                  await AuthService.serverLogout();
                  await AuthService.logout();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng xuất thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  await AuthService.logout();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng xuất thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadCoinBalance() async {
    if (userData == null) return;
    setState(() { isCoinLoading = true; });
    coinBalance = await AuthService.getCoinBalance(userId: userData!["id"]);
    setState(() { isCoinLoading = false; });
  }

  void _showCoinHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyCoinHistoryScreen(userId: userData!["id"]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null || isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData!['username'] ?? 'Chưa có tên',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userData!['email'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showEditProfileDialog(),
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.monetization_on),
                          label: const Text('Nạp coin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BuyCoinScreen(userId: userData!['id'])));
                          },
                        ),
                        const SizedBox(width: 12),

                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _showCoinHistory,
                          child: const Text('Xem lịch sử giao dịch BACoin'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (userData!['role'] == 'agency')
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.account_balance_wallet),
                              label: const Text('Rút tiền'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => WithdrawScreen()),
                                );
                              },
                            ),
                          ),
                        if (userData!['role'] == 'agency')
                          const SizedBox(width: 8),
                        if (userData!['role'] == 'agency')
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.history),
                              label: const Text('Lịch sử rút tiền'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => WithdrawHistoryDialog(agencyId: userData!['id']),
                                );
                              },
                            ),
                          ),
                        if (userData!['role'] != 'agency')
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.payment),
                              label: const Text('Lịch sử thanh toán'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
                                );
                              },
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Đăng xuất'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _logout,
                          ),
                        ),
                      ],
                    ),
                    _buildInfoRow('Tên đăng nhập', userData!['username'] ?? 'Chưa có'),
                    _buildInfoRow('Email', userData!['email'] ?? 'Chưa có'),
                    _buildInfoRow('Số điện thoại', userData!['phone'] ?? 'Chưa có'),
                    _buildInfoRow('Giới tính', _getGenderText(userData!['gender'])),
                    _buildInfoRow('Ngày sinh', userData!['dob'] ?? 'Chưa có'),
                    _buildInfoRow('Vai trò', _getRoleText(userData!['role'])),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Addresses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Địa chỉ giao hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAddressDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm địa chỉ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (addresses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có địa chỉ nào',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thêm địa chỉ để có thể đặt hàng',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...addresses.map((address) => _buildAddressCard(address)),
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WithdrawScreen()),
                );
              },
              child: Text('Rút tiền'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address['address_line'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${address['city']}, ${address['province']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (address['postal_code'] != null)
                        Text(
                          'Mã bưu điện: ${address['postal_code']}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (address['is_default'] == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mặc định',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditAddressDialog(address),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteAddress(address),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGenderText(String? gender) {
    switch (gender) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return 'Chưa có';
    }
  }

  String _getRoleText(String? role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'user':
        return 'Người dùng';
      case 'agency':
        return 'Agency';
      default:
        return 'Chưa có';
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        userData: userData!,
        onProfileUpdated: () {
          _loadUserData();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditAddressDialog(
        userId: userData!['id'],
        onAddressUpdated: () {
          _loadAddresses();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditAddressDialog(Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (context) => AddEditAddressDialog(
        userId: userData!['id'],
        address: address,
        onAddressUpdated: () {
          _loadAddresses();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _deleteAddress(Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ'),
        content: Text('Bạn có chắc chắn muốn xóa địa chỉ này?\n\n${address['address_line']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final result = await AuthService.deleteAddress(
                userId: userData!['id'],
                addressId: address['id'],
              );
              
              if (result['success'] == true) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa địa chỉ thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadAddresses();
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Lỗi xóa địa chỉ'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCoinDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Nạp coin'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Mua thẻ'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showBuyCardDialog();
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Nạp thẻ'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showRedeemCardDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBuyCardDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: http.get(Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/coin/get_promotions.php')),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(content: Center(child: CircularProgressIndicator()));
            }
            final resp = snapshot.data!;
            final data = json.decode(resp.body);
            if (data['success'] == true) {
              final promotions = data['data'] as List;
              int? selectedPromotionId;
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Chọn loại ưu đãi'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: promotions.map<Widget>((promo) {
                        final promoId = promo['id'] is int ? promo['id'] : int.tryParse(promo['id'].toString()) ?? 0;
                        return RadioListTile<int>(
                          value: promoId,
                          groupValue: selectedPromotionId,
                          onChanged: (val) => setState(() => selectedPromotionId = val),
                          title: Text('${promo['name']}'),
                          subtitle: Text('Nạp ${promo['original_price']} VNĐ → nhận ${promo['crypto_coin'] ?? promo['converted_price']} coin'),
                        );
                      }).toList(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: selectedPromotionId == null
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                // Gọi API mua thẻ với promotion_id đã chọn
                                final buyResp = await http.post(
                                  Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/coin/buy_card.php'),
                                  body: {
                                    'user_id': userData!['id'].toString(),
                                    'promotion_id': selectedPromotionId.toString(),
                                  },
                                );
                                final buyData = json.decode(buyResp.body);
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    if (buyData['success'] == true) {
                                      final cards = buyData['cards'] as List;
                                      return AlertDialog(
                                        title: const Text('Danh sách thẻ chưa dùng'),
                                        content: SizedBox(
                                          width: 350,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: cards.length,
                                            itemBuilder: (context, index) {
                                              final card = cards[index];
                                              return ListTile(
                                                title: Text('Serial: ${card['serial_number']}'),
                                                subtitle: Text('Mã thẻ: ${card['card_code']}'),
                                                trailing: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text('${card['price']} VNĐ'),
                                                    Text('${card['crypto_coin']} coin', style: TextStyle(color: Colors.green)),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Đóng'),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return AlertDialog(
                                        title: const Text('Lỗi'),
                                        content: Text(buyData['message'] ?? 'Không mua được thẻ!'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Đóng'),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                );
                              },
                        child: const Text('Mua thẻ'),
                      ),
                    ],
                  );
                },
              );
            } else {
              return AlertDialog(
                title: const Text('Lỗi'),
                content: Text(data['message'] ?? 'Không lấy được danh sách ưu đãi!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  void _showRedeemCardDialog() {
    final serialController = TextEditingController();
    final codeController = TextEditingController();
    bool loading = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nạp thẻ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: serialController,
                    decoration: const InputDecoration(labelText: 'Serial thẻ'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Mã thẻ'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() => loading = true);
                          final resp = await http.post(
                            Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/coin/redeem_card.php'),
                            body: {
                              'user_id': userData!['id'].toString(),
                              'serial_number': serialController.text.trim(),
                              'card_code': codeController.text.trim(),
                            },
                          );
                          final data = json.decode(resp.body);
                          setState(() => loading = false);
                          if (data['success'] == true) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Nạp thành công: +${data['amount']} coin'), backgroundColor: Colors.green),
                              );
                              _loadUserData(); // Cập nhật lại thông tin user nếu cần
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(data['message'] ?? 'Nạp thẻ thất bại!'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Nạp'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onProfileUpdated;

  const EditProfileDialog({
    Key? key,
    required this.userData,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userData['username'] ?? '');
    _emailController = TextEditingController(text: widget.userData['email'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');
    _selectedGender = widget.userData['gender'];
    _selectedDate = widget.userData['dob'] != null ? DateTime.parse(widget.userData['dob']) : null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.updateUserProfile(
        userId: widget.userData['id'],
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender,
        dob: _selectedDate?.toIso8601String().split('T')[0],
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onProfileUpdated();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi cập nhật thông tin'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chỉnh sửa thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Giới tính',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Nam')),
                    DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Chọn ngày sinh',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Lưu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddEditAddressDialog extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? address;
  final VoidCallback onAddressUpdated;

  const AddEditAddressDialog({
    Key? key,
    required this.userId,
    this.address,
    required this.onAddressUpdated,
  }) : super(key: key);

  @override
  State<AddEditAddressDialog> createState() => _AddEditAddressDialogState();
}

class _AddEditAddressDialogState extends State<AddEditAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressLineController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _postalCodeController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressLineController = TextEditingController(text: widget.address?['address_line'] ?? '');
    _cityController = TextEditingController(text: widget.address?['city'] ?? '');
    _provinceController = TextEditingController(text: widget.address?['province'] ?? '');
    _postalCodeController = TextEditingController(text: widget.address?['postal_code'] ?? '');
    _isDefault = widget.address?['is_default'] == 1;
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = widget.address != null
          ? await AuthService.updateAddress(
              userId: widget.userId,
              addressId: widget.address!['id'],
              addressLine: _addressLineController.text.trim(),
              city: _cityController.text.trim(),
              province: _provinceController.text.trim(),
              postalCode: _postalCodeController.text.trim(),
              isDefault: _isDefault,
            )
          : await AuthService.addAddress(
              userId: widget.userId,
              addressLine: _addressLineController.text.trim(),
              city: _cityController.text.trim(),
              province: _provinceController.text.trim(),
              postalCode: _postalCodeController.text.trim(),
              isDefault: _isDefault,
            );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.address != null ? 'Cập nhật địa chỉ thành công' : 'Thêm địa chỉ thành công'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onAddressUpdated();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi thao tác địa chỉ'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.address != null ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _addressLineController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    border: OutlineInputBorder(),
                    hintText: 'Số nhà, tên đường, phường/xã',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Thành phố/Quận/Huyện',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập thành phố/quận/huyện';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _provinceController,
                  decoration: const InputDecoration(
                    labelText: 'Tỉnh/Thành phố',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tỉnh/thành phố';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã bưu điện (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                
                CheckboxListTile(
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(widget.address != null ? 'Cập nhật' : 'Thêm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AgencyWithdrawDialog extends StatefulWidget {
  final int agencyId;
  const AgencyWithdrawDialog({super.key, required this.agencyId});

  @override
  State<AgencyWithdrawDialog> createState() => _AgencyWithdrawDialogState();
}

class _AgencyWithdrawDialogState extends State<AgencyWithdrawDialog> {
  double? totalSales;
  double? availableBalance;
  
  double? platformFeeTotal;
  double? personalAccountBalance;
  double? updateBalance;
  String? error;
  bool loading = true;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    fetchBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> fetchBalance() async {
    setState(() { loading = true; error = null; });
    try {
      final uri = Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/agency/get_agency_balance.php?agency_id=${widget.agencyId}');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['success'] == true) {
          setState(() {
            totalSales = (data['total_sales'] as num?)?.toDouble() ?? 0;
            availableBalance = (data['available_balance'] as num?)?.toDouble() ?? 0;
            platformFeeTotal = (data['platform_fee_total'] as num?)?.toDouble() ?? 0;
            personalAccountBalance = (data['personal_account_balance'] as num?)?.toDouble() ?? 0;
            //updateBalance = availableBalance! - personalAccountBalance!;
            loading = false;
          });
        } else {
          setState(() { error = data['message'] ?? 'Lỗi không xác định'; loading = false; });
        }
      } else {
        setState(() { error = 'Lỗi server: ${resp.statusCode}'; loading = false; });
      }
    } catch (e) {
      setState(() { error = 'Lỗi: $e'; loading = false; });
    }
  }

  Future<void> submitWithdrawRequest() async {
    final amount = double.tryParse(_amountController.text.trim() ?? '');
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ!'), backgroundColor: Colors.red));
      return;
    }
    if (availableBalance != null && amount > availableBalance!) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số dư không đủ!'), backgroundColor: Colors.red));
      return;
    }
    setState(() { submitting = true; });
    try {
      // Gọi API gửi yêu cầu rút tiền (bạn cần tạo API thực tế, ở đây là ví dụ)
      final uri = Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/agency/request_withdraw.php');
      final resp = await http.post(uri, body: {
        'agency_id': widget.agencyId.toString(),
        'amount': amount.toString(),
        'note': _noteController.text.trim(),
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['success'] == true) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi yêu cầu rút tiền thành công!'), backgroundColor: Colors.green));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi gửi yêu cầu'), backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi server: ${resp.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thông tin rút tiền'),
      content: SizedBox(
        width: 900,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Text(error!, style: const TextStyle(color: Colors.red))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBalanceColumn('Tổng tiền bán được', totalSales, Colors.blue, width: 200, fontSize: 28),
                            _buildDivider(height: 110),
                            _buildBalanceColumn('Tài khoản cá nhân', personalAccountBalance, Colors.deepPurple, width: 200, fontSize: 28),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền muốn rút',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                        ),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú (tuỳ chọn)',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                        ),
                        minLines: 1,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        if (!loading && error == null)
          ElevatedButton(
            onPressed: submitting ? null : submitWithdrawRequest,
            child: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Gửi yêu cầu'),
          ),
      ],
    );
  }

  Widget _buildBalanceColumn(String label, double? value, Color color, {bool isNegative = false, double width = 120, double fontSize = 18}) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize - 2)),
          const SizedBox(height: 18),
          Text(
            isNegative ? '-${value?.toStringAsFixed(0) ?? '0'} VNĐ' : '${value?.toStringAsFixed(0) ?? '0'} VNĐ',
            style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w900, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider({double height = 60}) {
    return Container(width: 2.5, height: height, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 18));
  }
}

class WithdrawHistoryDialog extends StatefulWidget {
  final int agencyId;
  const WithdrawHistoryDialog({super.key, required this.agencyId});

  @override
  State<WithdrawHistoryDialog> createState() => _WithdrawHistoryDialogState();
}

class _WithdrawHistoryDialogState extends State<WithdrawHistoryDialog> {
  bool loading = true;
  String? error;
  List<dynamic> history = [];
  final ScrollController _scrollController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> fetchHistory() async {
    setState(() { loading = true; error = null; });
    try {
      final uri = Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/agency/get_withdraw_history.php?agency_id=${widget.agencyId}');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['success'] == true) {
          setState(() {
            history = data['data'] ?? [];
            loading = false;
          });
        } else {
          setState(() { error = data['message'] ?? 'Lỗi không xác định'; loading = false; });
        }
      } else {
        setState(() { error = 'Lỗi server: ${resp.statusCode}'; loading = false; });
      }
    } catch (e) {
      setState(() { error = 'Lỗi: $e'; loading = false; });
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lịch sử rút tiền'),
      content: SizedBox(
        width: 700,
        height: 400,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Text(error!, style: const TextStyle(color: Colors.red))
                : history.isEmpty
                    ? const Text('Chưa có lịch sử rút tiền')
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1000),
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                controller: _verticalController,
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Số tiền')),
                                    DataColumn(label: Text('Trạng thái')),
                                    DataColumn(label: Text('Ngày gửi')),
                                    DataColumn(label: Text('Ngày duyệt')),
                                    DataColumn(label: Text('Ghi chú')),
                                    DataColumn(label: Text('Admin duyệt')),
                                    DataColumn(label: Text('Ghi chú admin')),
                                  ],
                                  rows: history.map((item) {
                                    return DataRow(cells: [
                                      DataCell(Text('${item['amount']} VNĐ')),
                                      DataCell(Text(
                                        item['status'],
                                        style: TextStyle(color: statusColor(item['status'])),
                                      )),
                                      DataCell(Text(item['created_at'] ?? '')),
                                      DataCell(Text(item['reviewed_at'] ?? '-')),
                                      DataCell(Text(item['note'] ?? '-')),
                                      DataCell(Text(item['admin_username'] ?? '-')),
                                      DataCell(Text(item['admin_note'] ?? '-')),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
} 