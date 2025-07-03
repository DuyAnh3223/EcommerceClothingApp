import 'package:flutter/material.dart';
import '../../models/coin_model.dart';
import '../../services/coin_service.dart';

class BuyCoinScreen extends StatefulWidget {
  final int userId;
  const BuyCoinScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<BuyCoinScreen> createState() => _BuyCoinScreenState();
}

class _BuyCoinScreenState extends State<BuyCoinScreen> {
  List<CoinPackage> packages = [];
  Map<int, int> selected = {};
  bool loading = true;
  double balance = 0;

  @override
  void initState() {
    super.initState();
    loadPackages();
    loadBalance();
  }

  Future<void> loadPackages() async {
    packages = await CoinService.getPackages();
    setState(() => loading = false);
  }

  Future<void> loadBalance() async {
    balance = (await CoinService.getBalance(widget.userId)).toDouble();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double total = selected.entries.fold(0.0, (sum, e) => sum + (e.value * (packages.firstWhere((p) => p.id == e.key).price)));
    double discount = selected.entries.fold(0.0, (sum, e) {
      final pkg = packages.firstWhere((p) => p.id == e.key);
      return sum + (e.value * (pkg.amount - pkg.price));
    });

    return Scaffold(
      appBar: AppBar(title: Text('Giao diện mua BACoin')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Số dư BACoin: BA ${balance.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      color: Colors.grey[100],
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bên trái: Grid các gói BACoin
                          Expanded(
                            flex: 2,
                            child: GridView.count(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              shrinkWrap: true,
                              children: packages.map((pkg) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selected[pkg.id] = (selected[pkg.id] ?? 0) + 1;
                                    });
                                  },
                                  child: Card(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(pkg.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Container(
                                          width: 80, height: 80,
                                          color: Colors.grey[300],
                                          child: Icon(Icons.image, size: 40),
                                        ),
                                        SizedBox(height: 8),
                                        Text('${pkg.price} VNĐ', style: TextStyle(color: Colors.blue)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(width: 24),
                          // Bên phải: Danh sách đã chọn
                          Expanded(
                            flex: 3,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Danh sách chọn', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Divider(),
                                    ...selected.entries.map((e) {
                                      final pkg = packages.firstWhere((p) => p.id == e.key);
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${pkg.name} x${e.value}'),
                                          Text('BA ${pkg.price * e.value}'),
                                          IconButton(
                                            icon: Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                if (selected[e.key]! > 1) {
                                                  selected[e.key] = selected[e.key]! - 1;
                                                } else {
                                                  selected.remove(e.key);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    }),
                                    Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('BA ${total.toInt()}'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Khuyến mãi'),
                                        Text('BA ${discount.toInt()}'),
                                      ],
                                    ),
                                    SizedBox(height: 24),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: selected.isEmpty
                                            ? null
                                            : () async {
                                                for (var e in selected.entries) {
                                                  await CoinService.buyCoin(userId: widget.userId, packageId: e.key);
                                                }
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Nạp coin thành công!')),
                                                );
                                                setState(() {
                                                  selected.clear();
                                                });
                                              },
                                        child: Text('Thanh toán'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
