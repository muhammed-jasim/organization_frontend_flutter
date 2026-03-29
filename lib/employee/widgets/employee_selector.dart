import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import '../../theme/app_theme.dart';

class EmployeeMultiSelectDialog extends StatefulWidget {
  final List<String> initialSelectedIds;

  const EmployeeMultiSelectDialog({
    super.key,
    this.initialSelectedIds = const [],
  });

  @override
  State<EmployeeMultiSelectDialog> createState() => _EmployeeMultiSelectDialogState();
}

class _EmployeeMultiSelectDialogState extends State<EmployeeMultiSelectDialog> {
  final EmployeeService _employeeService = EmployeeService();
  List<EmployeeModel> _employees = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await _employeeService.getEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching employees: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<EmployeeModel> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    return _employees.where((e) {
      final name = e.displayName.toLowerCase();
      final code = e.employeeCode?.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) || code.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Employees", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search name or code...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_filteredEmployees.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No employees found.")))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = _filteredEmployees[index];
                    final isSelected = _selectedIds.contains(employee.id);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(employee.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(employee.employeeCode ?? "No Code", style: const TextStyle(fontSize: 12)),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(employee.id);
                          } else {
                            _selectedIds.remove(employee.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty ? null : () => Navigator.pop(context, _selectedIds.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Assign (${_selectedIds.length})"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
