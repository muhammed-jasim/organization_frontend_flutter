import 'finance_category.dart';

class TransactionModel {
  final int? id;
  final int ledgerId;
  final double amount;
  final FinanceCategory category;
  final String description;
  final DateTime date;
  final int? entityId;
  final String? entityType; // employee, site, equipment, vehicle
  final String transactionType; // Debit, Credit
  final int? organizationId;

  TransactionModel({
    this.id,
    required this.ledgerId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.entityId,
    this.entityType,
    required this.transactionType,
    this.organizationId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      ledgerId: json['ledger'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      category: FinanceCategoryExtension.fromJson(json['category'] ?? 'otherExpense'),
      description: json['description'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      entityId: json['entity_id'],
      entityType: json['entity_type'],
      transactionType: json['transaction_type'] ?? 'Debit',
      organizationId: json['organization'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ledger': ledgerId,
      'amount': amount,
      'category': category.jsonValue,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      'transaction_type': transactionType,
      if (organizationId != null) 'organization': organizationId,
    };
  }
}
