import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../models/user_model.dart';
import '../add_edit_user_screen.dart';

class UserTable extends StatelessWidget {
  final List<User> users;
  final Function onReload;

  const UserTable({Key? key, required this.users, required this.onReload}) : super(key: key);

  Future<void> _deleteUser(BuildContext context, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc chắn muốn xóa người dùng này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse("http://localhost/MyProject/backendapi/users/delete_user.php"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'MaND': userId}),
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Xóa người dùng thành công")),
            );
            onReload();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: ${result['message']}")),
            );
          }
        } else {
          throw Exception("Kết nối thất bại");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi xóa: $e")),
        );
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'user':
        return 'Người dùng';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Tên')),
          DataColumn(label: Text('Mật khẩu')),
          DataColumn(label: Text('SĐT')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Vai trò')),
          DataColumn(label: Text('Hành động')),
        ],
        rows: users.map((user) {
          return DataRow(cells: [
            DataCell(Text(user.maND)),
            DataCell(Text(user.ten)),
            DataCell(Text(user.matKhau)),
            DataCell(Text(user.soDienThoai)),
            DataCell(Text(user.email)),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRoleDisplayName(user.role),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final updatedUser = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditUserScreen(user: user),
                      ),
                    );
                    if (updatedUser != null) onReload();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(context, user.maND),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
