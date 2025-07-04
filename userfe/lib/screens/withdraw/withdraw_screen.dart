import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:userfe/services/auth_service.dart';

class WithdrawScreen extends StatefulWidget {
  @override
  _WithdrawScreenState createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  double totalSales = 0;
  double personalAccountBalance = 0;
  double totalFee = 0;
  double availableBalance = 0;
  bool isLoading = false;
  bool isFetching = true;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int userId = 0;

  @override
  void initState() {
    super.initState();
    _fetchWithdrawInfo();
  }

  Future<void> _fetchWithdrawInfo() async {
    setState(() => isFetching = true);
    final user = await AuthService.getUserData();
    if (user != null && user['id'] != null) {
      userId = user['id'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lấy được thông tin người dùng!')),
      );
      setState(() => isFetching = false);
      return;
    }
    // Gọi API update trước
    final updateUrl = 'http://localhost/EcommerceClothingApp/API/agency/update_withdraw_agency.php?agency_id=$userId';
    try {
      await http.get(Uri.parse(updateUrl));
    } catch (e) {
      // Có thể log lỗi nếu cần
    }
    // Sau đó mới gọi API get
    final url = 'http://localhost/EcommerceClothingApp/API/agency/get_withdraw_agency.php?agency_id=$userId';
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);
    if (data['success']) {
      setState(() {
        totalSales = double.tryParse(data['data']['total_sales'].toString()) ?? 0;
        personalAccountBalance = double.tryParse(data['data']['personal_account_balance'].toString()) ?? 0;
        totalFee = double.tryParse(data['data']['total_fee'].toString()) ?? 0;
        availableBalance = double.tryParse(data['data']['available_balance'].toString()) ?? 0;
        isFetching = false;
      });
    } else {
      setState(() => isFetching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Có lỗi xảy ra khi lấy thông tin rút tiền!')),
      );
    }
  }

  void _onWithdrawAll() {
    _amountController.text = totalSales.toStringAsFixed(0);
  }

  Future<void> _submitWithdraw() async {
    final amountText = _amountController.text.trim();
    final note = _noteController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0 || amount > totalSales) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số tiền rút không hợp lệ!')),
      );
      return;
    }
    // Hiển thị dialog xác nhận phí
    final fee = totalFee;
    final realAmount = amount - fee;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận rút tiền'),
        content: Text(
          'Bạn sẽ bị trừ phí $fee VNĐ.\nSố tiền thực nhận là ${realAmount > 0 ? realAmount : 0} VNĐ.\nBạn có chắc chắn muốn gửi yêu cầu rút tiền không?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Xác nhận')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => isLoading = true);
    final url = 'http://localhost/EcommerceClothingApp/API/agency/request_withdraw.php';
    final res = await http.post(
      Uri.parse(url),
      body: {
        'agency_id': userId.toString(),
        'amount': amount.toString(),
        'note': note,
      },
    );
    final data = json.decode(res.body);
    setState(() => isLoading = false);
    if (data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi yêu cầu rút tiền thành công!')),
      );
      _fetchWithdrawInfo();
      _amountController.clear();
      _noteController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Có lỗi xảy ra!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rút tiền')),
      body: isFetching
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng tiền sản phẩm: ${totalSales.toStringAsFixed(2)} VNĐ', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Số dư khả dụng: ${availableBalance.toStringAsFixed(2)} VNĐ', style: TextStyle(fontSize: 16, color: Colors.green)),
                  SizedBox(height: 8),
                  Text('Tài khoản cá nhân: ${personalAccountBalance.toStringAsFixed(2)} VNĐ', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Số tiền muốn rút'),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _onWithdrawAll,
                        child: Text('Rút tất cả'),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
                  ),
                  SizedBox(height: 16),
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitWithdraw,
                          child: Text('Gửi yêu cầu rút tiền'),
                        ),
                ],
              ),
            ),
    );
  }
}