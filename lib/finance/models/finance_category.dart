enum FinanceCategory {
  employeePayment,
  equipmentRental,
  materialExpense,
  vehicleRent,
  siteEarning,
  otherExpense,
  receipt,
}

extension FinanceCategoryExtension on FinanceCategory {
  String get displayName {
    switch (this) {
      case FinanceCategory.employeePayment:
        return 'Employee Payment';
      case FinanceCategory.equipmentRental:
        return 'Equipment Rental';
      case FinanceCategory.materialExpense:
        return 'Material Expense';
      case FinanceCategory.vehicleRent:
        return 'Vehicle Rent';
      case FinanceCategory.siteEarning:
        return 'Site Earning';
      case FinanceCategory.otherExpense:
        return 'Other Expense';
      case FinanceCategory.receipt:
        return 'Receipt';
    }
  }

  String get jsonValue {
    return toString().split('.').last;
  }

  static FinanceCategory fromJson(String value) {
    return FinanceCategory.values.firstWhere(
      (e) => e.jsonValue == value,
      orElse: () => FinanceCategory.otherExpense,
    );
  }
}
