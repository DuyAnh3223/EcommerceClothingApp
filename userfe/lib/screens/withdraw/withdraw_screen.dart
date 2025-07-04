// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:userfe/services/auth_service.dart';

// class WithdrawScreen extends StatefulWidget {
//   @override
//   _WithdrawScreenState createState() => _WithdrawScreenState();
// }

// class _WithdrawScreenState extends State<WithdrawScreen> {
//   final TextEditingController _amountController = TextEditingController();
//   final TextEditingController _noteController = TextEditingController();
//   double totalSales = 0;
//   bool isLoading = false;
//   bool isFetching = true;
//   int? userId;

//   @override
//   void initState() {
//     super.initState();
//     _fetchWithdrawInfo();
//   }

//   Future<void> _fetchWithdrawInfo() async {
//     setState(() { isFetching = true; });
//     final userData = await AuthService.getUserData();
//     userId = userData?['id'];
//     if (userId == null) {
//       _showMessage('Không xác định được tài khoản.');
//       Navigator.pop(context);
//       return;
//     }
//     try {
//       final res = await http.get(Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/agency/get_withdraw_agency.php?agency_id=$userId'));
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         if (data['success'] == true) {
//           setState(() {
//             totalSales = (data['data']['total_withdrawable'] ?? 0).toDouble();
//           });
//         } else {
//           _showMessage(data['message'] ?? 'Không lấy được số dư');
//         }
//       } else {
//         _showMessage('Lỗi server khi lấy số dư');
//       }
//     } catch (e) {
//       _showMessage('Lỗi kết nối: $e');
//     }
//     setState(() { isFetching = false; });
//   }

//   Future<void> _submitWithdraw() async {
//     final amountText = _amountController.text.trim();
//     final note = _noteController.text.trim();
//     if (amountText.isEmpty) {
//       _showMessage('Vui lòng nhập số tiền muốn rút');
//       return;
//     }
//     final amount = double.tryParse(amountText);
//     if (amount == null || amount <= 0) {
//       _showMessage('Số tiền không hợp lệ');
//       return;
//     }
//     if (amount > totalSales) {
//       _showMessage('Số tiền rút vượt quá tổng tiền sản phẩm');
//       return;
//     }
//     setState(() { isLoading = true; });
//     try {
//       final res = await http.post(
//         Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/agency/request_withdraw.php'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'agency_id': userId,
//           'amount': amount,
//           'note': note,
//         }),
//       );
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         if (data['success'] == true) {
//           _showMessage('Yêu cầu rút tiền đã được gửi tới admin!');
//           Navigator.pop(context);
//         } else {
//           _showMessage(data['message'] ?? 'Có lỗi xảy ra');
//         }
//       } else {
//         _showMessage('Lỗi server khi gửi yêu cầu');
//       }
//     } catch (e) {
//       _showMessage('Lỗi kết nối: $e');
//     }
//     setState(() { isLoading = false; });
//   }

//   void _showMessage(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Rút tiền')),
//       body: isFetching
//           ? Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Tổng tiền sản phẩm:', style: TextStyle(fontSize: 16)),
//                   SizedBox(height: 4),
//                   Text(
//                     '${totalSales.toStringAsFixed(0)} VNĐ',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
//                   ),
//                   SizedBox(height: 24),
//                   TextField(
//                     controller: _amountController,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: 'Số tiền muốn rút',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _noteController,
//                     decoration: InputDecoration(
//                       labelText: 'Ghi chú (tuỳ chọn)',
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 2,
//                   ),
//                   SizedBox(height: 24),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: isLoading ? null : _submitWithdraw,
//                       child: isLoading
//                           ? CircularProgressIndicator(color: Colors.white)
//                           : Text('Gửi yêu cầu rút tiền'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// } 

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
  double totalFee = 0;
  double totalWithdrawable = 0;
  String lastUpdated = '';
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
    final url = 'http://localhost/EcommerceClothingApp/API/agency/get_withdraw_agency.php?agency_id=$userId';
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);
    if (data['success']) {
      setState(() {
        totalSales = double.tryParse(data['data']['total_sales'] ?? '0') ?? 0;
        totalFee = double.tryParse(data['data']['total_fee'] ?? '0') ?? 0;
        totalWithdrawable = double.tryParse(data['data']['total_withdrawable'] ?? '0') ?? 0;
        lastUpdated = data['data']['last_updated'] ?? '';
        isFetching = false;
      });
    } else {
      setState(() => isFetching = false);
      // Hiển thị lỗi nếu cần
    }
  }

  Future<void> _submitWithdraw() async {
    final amountText = _amountController.text.trim();
    final note = _noteController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0 || amount > totalWithdrawable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số tiền rút không hợp lệ!')),
      );
      return;
    }
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
      _fetchWithdrawInfo(); // Cập nhật lại số dư
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
                  Text('Tổng tiền bán: ${totalSales.toStringAsFixed(2)} VNĐ'),
                  Text('Tổng phí: ${totalFee.toStringAsFixed(2)} VNĐ'),
                  Text('Số tiền có thể rút: ${totalWithdrawable.toStringAsFixed(2)} VNĐ'),
                  Text('Cập nhật: $lastUpdated'),
                  SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Số tiền muốn rút'),
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