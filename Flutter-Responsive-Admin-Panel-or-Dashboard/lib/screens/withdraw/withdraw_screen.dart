import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  List<dynamic> requests = [];
  bool isLoading = false;
  String? filterStatus;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    if (!mounted) return;
    setState(() { isLoading = true; });
    String url = 'http://localhost/EcommerceClothingApp/API/admin/get_withdraw_requests.php';
    if (filterStatus != null && filterStatus!.isNotEmpty) {
      url += '?status=$filterStatus';
    }
    final res = await http.get(Uri.parse(url));
    if (!mounted) return;
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['success']) {
        setState(() { requests = data['data']; });
      }
    }
    if (!mounted) return;
    setState(() { isLoading = false; });
  }

  void reviewRequestDialog(Map req, String action) async {
    final noteController = TextEditingController();
    final result = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action == 'approve' ? 'Duyệt' : 'Từ chối'} yêu cầu rút tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Số tiền: ${req['amount']}'),
            Text('Agency: ${req['agency_username']}'),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: 'Ghi chú admin (tùy chọn)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, noteController.text),
            child: Text(action == 'approve' ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );
    if (result != null) {
      await reviewRequest(req['id'], action, result);
    }
  }

  Future<void> reviewRequest(int id, String action, String adminNote) async {
    if (!mounted) return;
    setState(() { isLoading = true; });
    final res = await http.post(
      Uri.parse('http://localhost/EcommerceClothingApp/API/admin/review_withdraw_request.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'request_id': id,
        'action': action,
        'admin_id': 6, // TODO: Lấy id admin thực tế khi đăng nhập
        'admin_note': adminNote,
      }),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Thao tác xong')),
      );
      fetchRequests();
    }
    if (!mounted) return;
    setState(() { isLoading = false; });
  }

  Future<void> showPlatformFeeDialog() async {
    // Lấy danh sách agency duy nhất từ requests
    final agencyIds = requests.map((e) => e['agency_id']).toSet().toList();
    double totalFee = 0;
    for (final id in agencyIds) {
      final res = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/agency/get_agency_balance.php?agency_id=$id'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['platform_fee_total'] != null) {
          totalFee += (data['platform_fee_total'] as num).toDouble();
        }
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tổng phí nền tảng đã thu từ agency'),
        content: Text(
          '${totalFee.toStringAsFixed(0)} VNĐ',
          style: const TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> showAvailableBalanceDialog() async {
    final agencyIds = requests.map((e) => e['agency_id']).toSet().toList();
    double totalAvailable = 0;
    for (final id in agencyIds) {
      final res = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/agency/get_agency_balance.php?agency_id=$id'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['available_balance'] != null) {
          totalAvailable += (data['available_balance'] as num).toDouble();
        }
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tổng số dư khả dụng của agency'),
        content: Text(
          '${totalAvailable.toStringAsFixed(0)} VNĐ',
          style: const TextStyle(fontSize: 28, color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> showTotalSalesDialog() async {
    final agencyIds = requests.map((e) => e['agency_id']).toSet().toList();
    double totalSales = 0;
    for (final id in agencyIds) {
      final res = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/agency/get_agency_balance.php?agency_id=$id'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['total_sales'] != null) {
          totalSales += (data['total_sales'] as num).toDouble();
        }
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tổng tiền bán được của agency'),
        content: Text(
          '${totalSales.toStringAsFixed(0)} VNĐ',
          style: const TextStyle(fontSize: 28, color: Colors.purple, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> showPersonalAccountDialog() async {
    final agencyIds = requests.map((e) => e['agency_id']).toSet().toList();
    double totalPersonal = 0;
    for (final id in agencyIds) {
      final res = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/agency/get_agency_balance.php?agency_id=$id'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['personal_account_balance'] != null) {
          totalPersonal += (data['personal_account_balance'] as num).toDouble();
        }
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tổng tài khoản cá nhân của agency'),
        content: Text(
          '${totalPersonal.toStringAsFixed(0)} VNĐ',
          style: const TextStyle(fontSize: 28, color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý yêu cầu rút tiền')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text('Lọc trạng thái: '),
                        DropdownButton<String>(
                          value: filterStatus,
                          hint: Text('Tất cả'),
                          items: [
                            DropdownMenuItem(value: null, child: Text('Tất cả')),
                            DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                            DropdownMenuItem(value: 'approved', child: Text('Đã duyệt')),
                            DropdownMenuItem(value: 'rejected', child: Text('Từ chối')),
                          ],
                          onChanged: (v) {
                            setState(() { filterStatus = v; });
                            fetchRequests();
                          },
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.monetization_on, color: Colors.white),
                          label: const Text('Xem phí nền tảng đã thu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: showPlatformFeeDialog,
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                          label: const Text('Xem số dư khả dụng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: showAvailableBalanceDialog,
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.attach_money, color: Colors.white),
                          label: const Text('Tổng tiền bán được'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: showTotalSalesDialog,
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.account_box, color: Colors.white),
                          label: const Text('Tài khoản cá nhân'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: showPersonalAccountDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Agency')),
                        DataColumn(label: Text('Số tiền')),
                        DataColumn(label: Text('Ghi chú')),
                        DataColumn(label: Text('Trạng thái')),
                        DataColumn(label: Text('Ngày tạo')),
                        DataColumn(label: Text('Hành động')),
                      ],
                      rows: requests.map<DataRow>((req) {
                        return DataRow(cells: [
                          DataCell(Text(req['id'].toString())),
                          DataCell(Text(req['agency_username'] ?? '')),
                          DataCell(Text(req['amount'].toString())),
                          DataCell(Text(req['note'] ?? '')),
                          DataCell(Text(req['status'] ?? '')),
                          DataCell(Text(req['created_at'] ?? '')),
                          DataCell(Row(
                            children: [
                              if (req['status'] == 'pending') ...[
                                ElevatedButton(
                                  onPressed: () => reviewRequestDialog(req, 'approve'),
                                  child: Text('Duyệt'),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => reviewRequestDialog(req, 'reject'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: Text('Từ chối'),
                                ),
                              ] else ...[
                                Text('Đã xử lý'),
                              ]
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
