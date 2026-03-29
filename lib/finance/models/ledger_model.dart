class LedgerModel {
  final int? id;
  final String name;
  final String type; // Asset, Liability, Equity, Income, Expense
  final double currentBalance;
  final int? organizationId;

  LedgerModel({
    this.id,
    required this.name,
    required this.type,
    this.currentBalance = 0.0,
    this.organizationId,
  });

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'Asset',
      currentBalance: (json['current_balance'] ?? 0.0).toDouble(),
      organizationId: json['organization'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'current_balance': currentBalance,
      if (organizationId != null) 'organization': organizationId,
    };
  }
}
