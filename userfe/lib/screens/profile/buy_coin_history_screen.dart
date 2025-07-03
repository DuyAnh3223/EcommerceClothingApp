import 'package:flutter/material.dart';
import '../../models/coin_model.dart';
import '../../services/coin_service.dart';

class BuyCoinHistoryScreen extends StatefulWidget {
  final int userId;
  const BuyCoinHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<BuyCoinHistoryScreen> createState() => _BuyCoinHistoryScreenState();
}

class _BuyCoinHistoryScreenState extends State<BuyCoinHistoryScreen> {
  List<CoinTransaction> transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    transactions = await CoinService.getTransactions(widget.userId);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử nạp coin')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? const Center(child: Text('Chưa có lịch sử nạp coin.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final t = transactions[i];
                    return ListTile(
                      leading: Icon(
                        t.type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: t.type == 'deposit' ? Colors.green : Colors.red,
                      ),
                      title: Text('ID: ${t.id}  |  Số lượng: BA ${t.amount.toInt()}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Loại: ${t.type}'),
                          Text('Mô tả: ${t.description ?? ""}'),
                          Text('Thời gian: ${t.createdAt}'),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 