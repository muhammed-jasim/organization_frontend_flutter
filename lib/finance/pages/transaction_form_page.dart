import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../services/finance_service.dart';
import '../models/transaction_model.dart';
import '../models/ledger_model.dart';
import '../models/finance_category.dart';
import '../../employee/services/employee_service.dart';
import '../../site/services/site_service.dart';
import '../../material/services/material_service.dart';
// Add others if needed

class TransactionFormPage extends StatefulWidget {
  final bool isPayment;
  const TransactionFormPage({super.key, required this.isPayment});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final FinanceService _financeService = FinanceService();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  
  FinanceCategory? _selectedCategory;
  LedgerModel? _selectedLedger;
  List<LedgerModel> _ledgers = [];
  
  dynamic _selectedEntity; // Can be Employee, Site, etc.
  List<dynamic> _entities = [];
  
  bool _isLoading = true;
  bool _isLedgersLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final ledgers = await _financeService.getLedgers();
      setState(() {
        _ledgers = ledgers;
        _isLedgersLoading = false;
        if (ledgers.isNotEmpty) _selectedLedger = ledgers.first;
      });
      _isLoading = false;
    } catch (e) {
      debugPrint("Error loading ledgers: $e");
      setState(() => _isLedgersLoading = false);
    }
  }

  Future<void> _onCategoryChanged(FinanceCategory? category) async {
    setState(() {
      _selectedCategory = category;
      _selectedEntity = null;
      _entities = [];
    });
    
    if (category == null) return;

    // Load relevant entities based on category
    try {
      if (category == FinanceCategory.employeePayment) {
        final service = EmployeeService();
        final list = await service.getEmployees();
        setState(() => _entities = list);
      } else if (category == FinanceCategory.siteEarning) {
        final service = SiteService();
        final list = await service.getSites();
        setState(() => _entities = list);
      } else if (category == FinanceCategory.materialExpense) {
        final service = MaterialService();
        final list = await service.getMaterials();
        setState(() => _entities = list);
      }
    } catch (e) {
      debugPrint("Error loading entities: $e");
    }
  }

  String _getEntityName(dynamic entity) {
    if (entity == null) return "Select Entity";
    // Duck typing / reflection-like check or manual mapping
    try {
      return entity.name ?? entity.firstName ?? "Unnamed";
    } catch (_) {
      return "Entity #${entity.id}";
    }
  }

  void _submit() async {
    if (_amountController.text.isEmpty || _selectedCategory == null || _selectedLedger == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    try {
      final amount = double.parse(_amountController.text);
      final tx = TransactionModel(
        ledgerId: _selectedLedger!.id!,
        amount: amount,
        category: _selectedCategory!,
        description: _descController.text,
        date: _selectedDate,
        transactionType: widget.isPayment ? 'Credit' : 'Debit',
        entityId: _selectedEntity?.id,
        entityType: _selectedCategory!.jsonValue.toLowerCase().contains('employee') ? 'employee' 
                   : _selectedCategory!.jsonValue.toLowerCase().contains('site') ? 'site' : null,
      );

      await _financeService.createTransaction(tx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction recorded successfully")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isPayment ? AppColors.error : AppColors.success;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Record ${widget.isPayment ? 'Payment' : 'Receipt'}", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Amount Input - Large
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text("Amount (₹)", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: color),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "0.00",
                      hintStyle: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),

            /// Form Fields
            const Text("Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            /// Category
            DropdownButtonFormField<FinanceCategory>(
              value: _selectedCategory,
              decoration: AppTheme.inputDecoration(label: "Category"),
              items: FinanceCategory.values.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c.displayName),
              )).toList(),
              onChanged: _onCategoryChanged,
            ),
            const SizedBox(height: 20),

            /// Ledger
            DropdownButtonFormField<LedgerModel>(
              value: _selectedLedger,
              decoration: AppTheme.inputDecoration(label: "Account Ledger"),
              items: _ledgers.map((l) => DropdownMenuItem(
                value: l,
                child: Text(l.name),
              )).toList(),
              onChanged: (val) => setState(() => _selectedLedger = val),
            ),
            const SizedBox(height: 20),

            /// Entity Selection (Dynamic)
            if (_entities.isNotEmpty) ...[
              DropdownButtonFormField<dynamic>(
                value: _selectedEntity,
                decoration: AppTheme.inputDecoration(label: "Related To (Optional)"),
                items: _entities.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(_getEntityName(e)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedEntity = val),
              ),
              const SizedBox(height: 20),
            ],

            /// Description
            TextField(
              controller: _descController,
              decoration: AppTheme.inputDecoration(label: "Short Note", hint: "e.g. March Salary, Site A Advance"),
            ),
            const SizedBox(height: 20),

            /// Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      "Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            /// Submit Button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: color.withValues(alpha: 0.4),
                ),
                child: Text(
                  "Confirm ${widget.isPayment ? 'Payment' : 'Receipt'}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
