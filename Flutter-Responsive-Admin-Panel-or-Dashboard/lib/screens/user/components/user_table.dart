import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../models/user_model.dart';
import '../add_edit_user_screen.dart';

class UserTable extends StatefulWidget {
  final List<User> users;
  final Function onReload;
  final Function(User)? onEdit;
  final Function(int)? onDelete;

  const UserTable({Key? key, required this.users, required this.onReload, this.onEdit, this.onDelete}) : super(key: key);

  @override
  State<UserTable> createState() => _UserTableState();
}

class _UserTableState extends State<UserTable> {
  final Map<int, bool> _showPassword = {};
  final Map<int, String> _selectedGender = {};
  final List<String> allowedGenders = ['male', 'female'];

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
          Uri.parse("http://localhost/EcommerceClothingApp/API/users/delete_user.php"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'MaND': userId}),
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Xóa người dùng thành công")),
            );
            widget.onReload();
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
        return 'admin';
      case 'user':
        return 'user';
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
          DataColumn(label: Text('Username')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Gender')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('DOB')),
          DataColumn(label: Text('Hành động')),
        ],
        rows: widget.users.map((user) {
          String gender = _selectedGender[user.id] ?? user.gender;
          if (!allowedGenders.contains(gender)) gender = 'male';
          return DataRow(cells: [
            DataCell(Text(user.id.toString())),
            DataCell(Text(user.username)),
            DataCell(Text(user.email)),
            DataCell(Text(user.phone)),
            DataCell(DropdownButton<String>(
              value: gender,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('male')),
                DropdownMenuItem(value: 'female', child: Text('female')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender[user.id] = value ?? user.gender;
                });
                // TODO: Gọi API cập nhật gender nếu muốn
              },
            )),
            DataCell(Text(user.role)),
            DataCell(Text(user.dob ?? '')),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    if (widget.onDelete != null) {
                      widget.onDelete!(user.id);
                    }
                  },
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

