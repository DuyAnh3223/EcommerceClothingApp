import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddEditUserScreen extends StatefulWidget {
  final User? user;

  const AddEditUserScreen({super.key, this.user});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController maNDController;
  late TextEditingController tenController;
  late TextEditingController matKhauController;
  late TextEditingController sdtController;
  late TextEditingController emailController;
  String selectedRole = 'user'; // Default role

  @override
  void initState() {
    super.initState();
    maNDController = TextEditingController(text: widget.user?.maND ?? '');
    tenController = TextEditingController(text: widget.user?.ten ?? '');
    matKhauController = TextEditingController(text: widget.user?.matKhau ?? '');
    sdtController = TextEditingController(text: widget.user?.soDienThoai ?? '');
    emailController = TextEditingController(text: widget.user?.email ?? '');
    selectedRole = widget.user?.role ?? 'user';
  }

  @override
  void dispose() {
    maNDController.dispose();
    tenController.dispose();
    matKhauController.dispose();
    sdtController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final newUser = User(
        maND: maNDController.text,
        ten: tenController.text,
        matKhau: matKhauController.text,
        soDienThoai: sdtController.text,
        email: emailController.text,
        role: selectedRole,
      );
      String url;
      Map<String, dynamic> body;
      if (widget.user == null) {
        url = 'http://localhost/MyProject/backendapi/users/add_user.php';
        body = {
          'Ten': newUser.ten,
          'MatKhau': newUser.matKhau,
          'SoDienThoai': newUser.soDienThoai,
          'Email': newUser.email,
          'Role': newUser.role,
        };
      } else {
        url = 'http://localhost/MyProject/backendapi/users/update_user.php';
        body = {
          'MaND': newUser.maND,
          'Ten': newUser.ten,
          'MatKhau': newUser.matKhau,
          'SoDienThoai': newUser.soDienThoai,
          'Email': newUser.email,
          'Role': newUser.role,
        };
      }
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Navigator.pop(context, newUser);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${data['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value!.isEmpty ? "Không được để trống" : null,
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedRole,
        decoration: const InputDecoration(labelText: 'Vai trò'),
        items: const [
          DropdownMenuItem(value: 'user', child: Text('Người dùng')),
          DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
        ],
        onChanged: (value) {
          setState(() {
            selectedRole = value!;
          });
        },
        validator: (value) => value == null ? "Vui lòng chọn vai trò" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? "Thêm người dùng" : "Sửa người dùng"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(maNDController, "Mã người dùng"),
              _buildTextField(tenController, "Tên"),
              _buildTextField(matKhauController, "Mật khẩu"),
              _buildTextField(sdtController, "Số điện thoại"),
              _buildTextField(emailController, "Email"),
              _buildRoleDropdown(),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveUser, child: const Text("Lưu")),
            ],
          ),
        ),
      ),
    );
  }
}
