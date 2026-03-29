import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import 'employee_create_page.dart';
import 'employee_details_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  bool isGridView = true;
  final EmployeeService _service = EmployeeService();
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All';
  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _filteredEmployees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await _service.getEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employees.where((emp) {
        final matchesQuery = emp.displayName.toLowerCase().contains(query) ||
            (emp.employeeCode?.toLowerCase().contains(query) ?? false) ||
            emp.emails.any((e) => e.email.toLowerCase().contains(query)) ||
            emp.mobiles.any((m) => m.number.contains(query));

        final matchesStatus = _filterStatus == 'All' ||
            (_filterStatus == 'Active' && emp.isActive) ||
            (_filterStatus == 'Inactive' && !emp.isActive);

        return matchesQuery && matchesStatus;
      }).toList();
    });
  }


@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true, toolbarHeight: 72, backgroundColor: AppColors.background, scrolledUnderElevation: 0,
            title: Text("Employees", style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(isGridView ? Icons.format_list_bulleted_rounded : Icons.grid_view_rounded, color: AppColors.textPrimary),
                onPressed: () => setState(() => isGridView = !isGridView),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: Column(children: [
            Row(children: [
              _buildSummaryCard("Total Employees", _employees.length.toString(), AppColors.primary),
              const SizedBox(width: 12),
              _buildSummaryCard("Active", _employees.where((e) => e.isActive).length.toString(), AppColors.success),
              const SizedBox(width: 12),
              _buildSummaryCard("Inactive", _employees.where((e) => !e.isActive).length.toString(), AppColors.error),
            ]),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))]),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by name or code...",
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
                    onPressed: _showFiltersBottomSheet,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]))),
          if (_isLoading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_filteredEmployees.isEmpty) SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_alt_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)), const SizedBox(height: 16), Text("No employees found", style: TextStyle(color: AppColors.textMuted, fontSize: 16))])))
          else SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 24), sliver: isGridView ? _buildEmployeeGrid() : _buildEmployeeList()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: Padding(padding: const EdgeInsets.only(bottom: 20), child: FloatingActionButton.extended(heroTag: 'employee_list_fab', onPressed: () async { final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeCreatePage())); if (res == true) _loadEmployees(); }, backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), icon: const Icon(Icons.add_rounded), label: const Text("Create", style: TextStyle(fontWeight: FontWeight.w800)))),
    );
  }

  Widget _buildEmployeeGrid() => SliverGrid(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75), delegate: SliverChildBuilderDelegate((ctx, idx) => _buildEmployeeCard(_filteredEmployees[idx]), childCount: _filteredEmployees.length));
  Widget _buildEmployeeList() => SliverList(delegate: SliverChildBuilderDelegate((ctx, idx) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildEmployeeListTile(_filteredEmployees[idx])), childCount: _filteredEmployees.length));

  Widget _buildEmployeeCard(EmployeeModel emp) => GestureDetector(onTap: () => _showEmployeeDetails(emp), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: Padding(padding: const EdgeInsets.all(5), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: emp.photos.isNotEmpty ? Image.network(emp.photos.first.imageUrl, width: double.infinity, fit: BoxFit.cover) : Container(width: double.infinity, color: AppColors.background, child: Icon(Icons.person_rounded, color: AppColors.textMuted.withValues(alpha: 0.4), size: 40))))),
    Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(emp.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (emp.isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(emp.isActive ? "ACT" : "INA", style: TextStyle(color: emp.isActive ? AppColors.success : AppColors.error, fontSize: 8, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 2),
      Text("${emp.jobRoleName ?? 'Staff'} — ${emp.employeeCode ?? ''}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
    ])),
  ])));

  Widget _buildEmployeeListTile(EmployeeModel emp) => GestureDetector(onTap: () => _showEmployeeDetails(emp), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]), child: Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(12), child: emp.photos.isNotEmpty ? Image.network(emp.photos.first.imageUrl, width: 50, height: 50, fit: BoxFit.cover) : Container(width: 50, height: 50, color: AppColors.background, child: const Icon(Icons.person_rounded, color: AppColors.textMuted))),
    const SizedBox(width: 16),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(emp.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), Text(emp.jobRoleName ?? 'Staff', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))])),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_statusDot(emp.isActive), const SizedBox(height: 4), Text(emp.employeeCode ?? '', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold))]),
  ])));

  Widget _buildSummaryCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }



  Widget _statusDot(bool active) => Container(width: 8, height: 8, decoration: BoxDecoration(color: active ? AppColors.success : AppColors.error, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)));

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filter Employees", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Employee Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['All', 'Active', 'Inactive'].map((status) {
                  final isSelected = _filterStatus == status;
                  return FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (v) {
                      setModalState(() => _filterStatus = status);
                      setState(() { _filterStatus = status; _applyFilters(); });
                    },
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmployeeDetails(EmployeeModel emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailPage(employee: emp),
      ),
    ).then((_) => _loadEmployees());
  }

  Widget _detailSection(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
    const SizedBox(height: 12),
    ...children,
  ]);

  Widget _detailRow(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    Icon(icon, size: 18, color: AppColors.textSecondary),
    const SizedBox(width: 12),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    const Spacer(),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
  ]));
}