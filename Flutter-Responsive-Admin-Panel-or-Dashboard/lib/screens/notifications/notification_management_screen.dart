import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({Key? key}) : super(key: key);

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'other';
  String _selectedUser = 'all';
  List<Map<String, dynamic>> users = [];
  bool isLoading = false;
  bool isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/EcommerceClothingApp/API/users/get_users.php'),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true && result['data'] != null) {
          setState(() {
            users = List<Map<String, dynamic>>.from(result['data']);
            isLoadingUsers = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách người dùng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (_selectedUser == 'all') {
        // Send to all users
        for (var user in users) {
          await _sendToUser(user['id']);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi thông báo đến ${users.length} người dùng'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Send to specific user
        final user = users.firstWhere((u) => u['id'].toString() == _selectedUser);
        await _sendToUser(user['id']);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi thông báo đến ${user['username']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Clear form
      _titleController.clear();
      _contentController.clear();
      _selectedType = 'other';
      _selectedUser = 'all';
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi thông báo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _sendToUser(int userId) async {
    final response = await http.post(
      Uri.parse('http://localhost/EcommerceClothingApp/API/notifications/add_notification.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'type': _selectedType,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final result = json.decode(response.body);
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Unknown error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thông báo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gửi thông báo mới',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // User selection
                            DropdownButtonFormField<String>(
                              value: _selectedUser,
                              decoration: const InputDecoration(
                                labelText: 'Gửi đến',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Tất cả người dùng'),
                                ),
                                ...users.map((user) => DropdownMenuItem(
                                  value: user['id'].toString(),
                                  child: Text('${user['username']} (${user['email']})'),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedUser = value!;
                                });
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Type selection
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Loại thông báo',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'order_status', child: Text('Trạng thái đơn hàng')),
                                DropdownMenuItem(value: 'sale', child: Text('Khuyến mãi')),
                                DropdownMenuItem(value: 'voucher', child: Text('Voucher')),
                                DropdownMenuItem(value: 'other', child: Text('Khác')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Title
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Tiêu đề *',
                                border: OutlineInputBorder(),
                                hintText: 'Nhập tiêu đề thông báo',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tiêu đề';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Content
                            TextFormField(
                              controller: _contentController,
                              decoration: const InputDecoration(
                                labelText: 'Nội dung',
                                border: OutlineInputBorder(),
                                hintText: 'Nhập nội dung thông báo (tùy chọn)',
                              ),
                              maxLines: 3,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Send button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _sendNotification,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Gửi thông báo',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Statistics
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thống kê',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Tổng người dùng',
                                    users.length.toString(),
                                    Icons.people,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    'Đang chọn',
                                    _selectedUser == 'all' 
                                        ? 'Tất cả' 
                                        : users.where((u) => u['id'].toString() == _selectedUser).isNotEmpty
                                            ? users.firstWhere((u) => u['id'].toString() == _selectedUser)['username']
                                            : 'Không xác định',
                                    Icons.send,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 