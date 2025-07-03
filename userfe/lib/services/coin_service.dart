import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin_model.dart';

class CoinService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API/coin';

  static Future<List<CoinPackage>> getPackages() async {
    final resp = await http.get(Uri.parse('$baseUrl/get_packages.php'));
    final data = json.decode(resp.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((e) => CoinPackage.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Lỗi lấy gói coin');
  }

  static Future<int> getBalance(int userId) async {
    final resp = await http.get(Uri.parse('$baseUrl/get_balance.php?user_id=$userId'));
    final data = json.decode(resp.body);
    if (data['success'] == true) {
      return int.parse(data['balance'].toString());
    }
    throw Exception(data['message'] ?? 'Lỗi lấy số dư');
  }

  static Future<List<CoinTransaction>> getTransactions(int userId) async {
    final resp = await http.get(Uri.parse('$baseUrl/get_transactions.php?user_id=$userId'));
    final data = json.decode(resp.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((e) => CoinTransaction.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Lỗi lấy lịch sử coin');
  }

  static Future<bool> buyCoin({required int userId, required int packageId}) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/buy_coin.php'),
      body: {'user_id': userId.toString(), 'package_id': packageId.toString()},
    );
    final data = json.decode(resp.body);
    return data['success'] == true;
  }
}