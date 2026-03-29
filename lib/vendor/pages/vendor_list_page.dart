import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/vendor_model.dart';
import '../services/vendor_service.dart';
import 'vendor_create_page.dart';
import 'vendor_details_page.dart';

import '../../auth/services/token_manager.dart';

class VendorListPage extends StatefulWidget {
  const VendorListPage({super.key});

  @override
  State<VendorListPage> createState() => _VendorListPageState();
}

class _VendorListPageState extends State<VendorListPage> {
  bool isGridView = false;
  final VendorService _service = VendorService();
  late Future<List<VendorModel>> _vendorsFuture;
  List<VendorModel> _allVendors = [];
  List<VendorModel> _displayVendors = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All'; // All, Active, Inactive

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    try {
      final orgId = await TokenManager.getOrganizationId();
      final vendors = await _service.getVendors(organizationId: orgId);
      if (mounted) {
        setState(() {
          _allVendors = vendors;
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

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _displayVendors = _allVendors.where((v) {
        final matchesSearch = v.name.toLowerCase().contains(query) || 
                             v.code.toLowerCase().contains(query);
        
        final matchesStatus = _filterStatus == 'All' ||
            (_filterStatus == 'Active' && v.isActive) ||
            (_filterStatus == 'Inactive' && !v.isActive);
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _deleteVendor(VendorModel vendor) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Vendor"),
        content: Text("Are you sure you want to delete ${vendor.name}?"),
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
        await _service.deleteVendor(vendor.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vendor deleted successfully")));
          _loadVendors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
        }
      }
    }
  }

  void _showVendorDetails(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorDetailsPage(vendor: vendor),
      ),
    ).then((_) => _loadVendors());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            backgroundColor: AppColors.background,
            scrolledUnderElevation: 0,
            title: Text("Vendors", style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(isGridView ? Icons.format_list_bulleted_rounded : Icons.grid_view_rounded, color: AppColors.textPrimary),
                onPressed: () => setState(() => isGridView = !isGridView),
              ),
              const SizedBox(width: 16),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                   Row(children: [
                    _buildSummaryCard("Total Vendors", _allVendors.length.toString(), AppColors.primary),
                    const SizedBox(width: 12),
                    _buildSummaryCard("Active", _allVendors.where((v) => v.isActive).length.toString(), AppColors.success),
                    const SizedBox(width: 12),
                    _buildSummaryCard("Inactive", _allVendors.where((v) => !v.isActive).length.toString(), AppColors.error),
                  ]),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20), 
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))]
                    ),
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
                ],
              ),
            ),
          ),

          if (_isLoading) 
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_displayVendors.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_center_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text("No vendors found", style: TextStyle(color: AppColors.textMuted, fontSize: 16))
                  ]
                )
              )
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: isGridView 
                ? _buildVendorGrid()
                : _buildVendorList(),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          heroTag: 'vendor_list_fab',
          onPressed: () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorCreatePage()));
            if (res == true) _loadVendors();
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.add_rounded),
          label: const Text("Create", style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _buildVendorGrid() => SliverGrid(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, 
      crossAxisSpacing: 16, 
      mainAxisSpacing: 16, 
      childAspectRatio: 0.85
    ), 
    delegate: SliverChildBuilderDelegate(
      (ctx, idx) => _buildVendorCard(_displayVendors[idx]), 
      childCount: _displayVendors.length
    )
  );

  Widget _buildVendorList() => SliverList(
    delegate: SliverChildBuilderDelegate(
      (ctx, idx) => Padding(
        padding: const EdgeInsets.only(bottom: 12), 
        child: _buildVendorListTile(_displayVendors[idx])
      ), 
      childCount: _displayVendors.length
    )
  );

  Widget _buildVendorCard(VendorModel vendor) => GestureDetector(
    onTap: () => _showVendorDetails(vendor), 
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.handshake_rounded, color: AppColors.textMuted.withValues(alpha: 0.4), size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Expanded(child: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    _statusDot(vendor.isActive),
                  ],
                ),
                const SizedBox(height: 2),
                Text(vendor.code, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]
            )
          ),
        ]
      )
    )
  );

  Widget _buildVendorListTile(VendorModel vendor) => GestureDetector(
    onTap: () => _showVendorDetails(vendor), 
    child: Container(
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]
      ), 
      child: Row(
        children: [
          Container(
            width: 50, height: 50, 
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.handshake_rounded, color: AppColors.textMuted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), 
                Text(vendor.code, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))
              ]
            )
          ),
          _statusDotBadge(vendor.isActive),
        ]
      )
    )
  );

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

  Widget _statusDot(bool active) => Container(
    width: 8, height: 8, 
    decoration: BoxDecoration(
      color: active ? AppColors.success : AppColors.error, 
      shape: BoxShape.circle, 
      border: Border.all(color: Colors.white, width: 1.5)
    )
  );

  Widget _statusDotBadge(bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (active ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: active ? AppColors.success : AppColors.error, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(active ? "Active" : "Inactive", style: TextStyle(color: active ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.w800)),
      ],
    ),
  );

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
                  const Text("Filter Vendors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Vendor Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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
}
