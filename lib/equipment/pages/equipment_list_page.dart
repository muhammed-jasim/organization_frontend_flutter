import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/equipment_model.dart';
import '../services/equipment_service.dart';
import 'equipment_details_page.dart';
import 'equipment_create_page.dart';

class EquipmentListPage extends StatefulWidget {
  const EquipmentListPage({super.key});

  @override
  State<EquipmentListPage> createState() => _EquipmentListPageState();
}

class _EquipmentListPageState extends State<EquipmentListPage> {
  bool isGridView = true;
  final EquipmentService _service = EquipmentService();
  late Future<List<EquipmentModel>> _equipmentsFuture;
  List<EquipmentModel> _allEquipments = [];
  List<EquipmentModel> _displayEquipments = [];

  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All'; // All, Active, Inactive

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _equipmentsFuture = _fetchEquipments();
    });
  }

  Future<List<EquipmentModel>> _fetchEquipments() async {
    final list = await _service.getEquipments();
    setState(() {
      _allEquipments = list;
      _applyFilters();
    });
    return list;
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _displayEquipments = _allEquipments.where((e) {
        final matchesSearch = e.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                             e.code.toLowerCase().contains(_searchController.text.toLowerCase());
        
        bool matchesStatus = true;
        if (_filterStatus == 'Active') {
          matchesStatus = e.isActive;
        } else if (_filterStatus == 'Inactive') {
          matchesStatus = !e.isActive;
        }
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _deleteEquipment(EquipmentModel equipment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Equipment"),
        content: Text("Are you sure you want to delete ${equipment.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _service.deleteEquipment(equipment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Equipment deleted successfully")));
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
        }
      }
    }
  }

  void _showEquipmentDetails(EquipmentModel equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.construction_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(equipment.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text("Code: ${equipment.code}", style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusDot(equipment.isActive),

              ],
            ),
            const SizedBox(height: 32),
            _detailItem(Icons.category_outlined, "Category", equipment.categoryDetail?.name ?? "N/A"),
            _detailItem(Icons.info_outline, "Status", equipment.statusDetail?.name ?? "N/A"),
            _detailItem(Icons.assignment_ind_outlined, "Ownership", equipment.ownershipTypeDetail?.name ?? "N/A"),
            
            if (equipment.purchaseDate != null)
              _detailItem(Icons.calendar_today_outlined, "Purchase Date", equipment.purchaseDate!),
            if (equipment.purchaseCost != null)
              _detailItem(Icons.payments_outlined, "Purchase Cost", "${equipment.purchaseCost}"),
            
            if (equipment.rentalDetails != null) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
              const Text("Rental Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _detailItem(Icons.business_outlined, "Vendor", equipment.rentalDetails?.vendorName ?? "N/A"),
              _detailItem(Icons.today_outlined, "Start Date", equipment.rentalDetails!.rentalStartDate),
              _detailItem(Icons.payments_outlined, "Rate/Day", equipment.rentalDetails!.rentalRatePerDay),
            ],

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => EquipmentCreatePage(equipment: equipment))
                      );
                      if (result == true) _loadData();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text("Edit"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEquipment(equipment);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Delete"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
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
            title: Text("Equipments", style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
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
              _buildSummaryCard("Total Gear", _allEquipments.length.toString(), AppColors.primary),
              const SizedBox(width: 12),
              _buildSummaryCard("Active", _allEquipments.where((e) => e.isActive).length.toString(), AppColors.success),
              const SizedBox(width: 12),
              _buildSummaryCard("Inactive", _allEquipments.where((e) => !e.isActive).length.toString(), AppColors.error),
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
          FutureBuilder<List<EquipmentModel>>(
            future: _equipmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _allEquipments.isEmpty) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              } else if (snapshot.hasError && _allEquipments.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text("Error loading data", style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text("Retry"))
                      ],
                    ),
                  ),
                );
              }

              if (_displayEquipments.isEmpty) {
                return SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.construction_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)), const SizedBox(height: 16), Text("No equipments found", style: TextStyle(color: AppColors.textMuted, fontSize: 16))])));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: isGridView ? _buildEquipmentGrid() : _buildEquipmentList(),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: Padding(padding: const EdgeInsets.only(bottom: 20), child: FloatingActionButton.extended(heroTag: 'equipment_list_fab', onPressed: () async { final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EquipmentCreatePage())); if (res == true) _loadData(); }, backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), icon: const Icon(Icons.add_rounded), label: const Text("Create", style: TextStyle(fontWeight: FontWeight.w800)))),
    );
  }

  Widget _buildEquipmentGrid() => SliverGrid(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75), delegate: SliverChildBuilderDelegate((ctx, idx) => _buildEquipmentCard(_displayEquipments[idx]), childCount: _displayEquipments.length));
  Widget _buildEquipmentList() => SliverList(delegate: SliverChildBuilderDelegate((ctx, idx) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildEquipmentListTile(_displayEquipments[idx])), childCount: _displayEquipments.length));

  Widget _buildEquipmentCard(EquipmentModel equipment) => GestureDetector(onTap: () => _showEquipmentDetailsPage(equipment), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: Padding(padding: const EdgeInsets.all(5), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: equipment.photos.isNotEmpty ? Image.network(equipment.photos.first.imageUrl, width: double.infinity, fit: BoxFit.cover) : Container(width: double.infinity, color: AppColors.background, child: Icon(Icons.construction_rounded, color: AppColors.textMuted.withValues(alpha: 0.4), size: 40))))),
    Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(equipment.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (equipment.isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(equipment.isActive ? "ACT" : "INA", style: TextStyle(color: equipment.isActive ? AppColors.success : AppColors.error, fontSize: 8, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 2),
      Text("${equipment.categoryDetail?.name ?? 'Equipment'} — ${equipment.code}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
    ])),
  ])));

  Widget _buildEquipmentListTile(EquipmentModel equipment) => GestureDetector(onTap: () => _showEquipmentDetailsPage(equipment), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]), child: Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(12), child: equipment.photos.isNotEmpty ? Image.network(equipment.photos.first.imageUrl, width: 50, height: 50, fit: BoxFit.cover) : Container(width: 50, height: 50, color: AppColors.background, child: const Icon(Icons.construction_rounded, color: AppColors.textMuted))),
    const SizedBox(width: 16),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(equipment.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), Text(equipment.categoryDetail?.name ?? 'Equipment', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))])),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_statusDot(equipment.isActive), const SizedBox(height: 4), Text(equipment.code, style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold))]),
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
                  const Text("Filter Equipments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Equipment Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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

  void _showEquipmentDetailsPage(EquipmentModel equipment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentDetailPage(equipment: equipment),
      ),
    ).then((_) => _loadData());
  }

}
