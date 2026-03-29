import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/services/base_service.dart';
import '../../auth/services/token_manager.dart';
import '../models/ledger_model.dart';
import '../models/transaction_model.dart';
import '../models/finance_category.dart';

import '../../core/constants/api_constants.dart';

class FinanceService extends BaseService {
  static const String financeBaseUrl = '${ApiConstants.mainApiUrl}/finance';

  // --- Ledgers ---
  Future<List<LedgerModel>> getLedgers() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$financeBaseUrl/ledgers/'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LedgerModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load ledgers: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching ledgers: $e");
    }
  }

  Future<LedgerModel> createLedger(LedgerModel ledger) async {
    try {
      final data = ledger.toJson();
      if (!data.containsKey('organization')) {
        final orgId = await TokenManager.getOrganizationId();
        if (orgId != null) data['organization'] = orgId;
      }

      final response = await performRequest((headers) => http.post(
        Uri.parse('$financeBaseUrl/ledgers/'),
        headers: headers,
        body: jsonEncode(data),
      ));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return LedgerModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to create ledger: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating ledger: $e");
    }
  }

  // --- Transactions ---
  Future<List<TransactionModel>> getTransactions({
    FinanceCategory? category,
    String? entityType,
    int? entityId,
  }) async {
    try {
      String query = "";
      if (category != null) query += "category=${category.jsonValue}&";
      if (entityType != null) query += "entity_type=$entityType&";
      if (entityId != null) query += "entity_id=$entityId&";
      
      final url = query.isEmpty 
          ? '$financeBaseUrl/transactions/' 
          : '$financeBaseUrl/transactions/?$query';

      final response = await performRequest((headers) => http.get(
        Uri.parse(url),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load transactions: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching transactions: $e");
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    try {
      final data = transaction.toJson();
      if (!data.containsKey('organization')) {
        final orgId = await TokenManager.getOrganizationId();
        if (orgId != null) data['organization'] = orgId;
      }

      final response = await performRequest((headers) => http.post(
        Uri.parse('$financeBaseUrl/transactions/'),
        headers: headers,
        body: jsonEncode(data),
      ));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return TransactionModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to create transaction: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error creating transaction: $e");
    }
  }

  Future<Map<String, dynamic>> getFinanceSummary() async {
    try {
      final response = await performRequest((headers) => http.get(
        Uri.parse('$financeBaseUrl/summary/'),
        headers: headers,
      ));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Fallback or specific error
        return {
          'total_balance': 0.0,
          'total_earnings': 0.0,
          'total_expenses': 0.0,
          'recent_transactions': [],
        };
      }
    } catch (e) {
      print("Error fetching finance summary: $e");
      return {};
    }
  }
}
