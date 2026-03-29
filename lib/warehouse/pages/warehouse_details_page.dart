import 'package:flutter/material.dart';
import '../models/warehouse_model.dart';
import '../services/warehouse_service.dart';
import '../../theme/app_theme.dart';
import 'warehouse_create_page.dart';

class WarehouseDetailPage extends StatefulWidget {
  final WarehouseModel warehouse;

  const WarehouseDetailPage({super.key, required this.warehouse});

  @override
  State<WarehouseDetailPage> createState() => _WarehouseDetailPageState();
}

class _WarehouseDetailPageState extends State<WarehouseDetailPage> {
  late WarehouseModel _warehouse;
  final WarehouseService _service = WarehouseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _warehouse = widget.warehouse;
    _refreshWarehouse();
  }

  Future<void> _refreshWarehouse() async {
    setState(() => _isLoading = true);
    try {
      final warehouses = await _service.getWarehouses();
      final updated = warehouses.firstWhere((w) => w.id == _warehouse.id);
      if (mounted) {
        setState(() {
          _warehouse = updated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error refreshing warehouse: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Immersive Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WarehouseCreatePage(warehouse: _warehouse)),
                      ).then((_) => _refreshWarehouse());
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.warehouse_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),

          // Warehouse Info Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _warehouse.name,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Code: ${_warehouse.code} — ${_warehouse.isPrimary ? 'Primary Warehouse' : 'Standard'}",
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_warehouse.isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (_warehouse.isActive ? "ACTIVE" : "INACTIVE").toUpperCase(),
                            style: TextStyle(color: _warehouse.isActive ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Action Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  _buildQuickAction(Icons.call_rounded, "Call", color: Colors.blue),
                  const SizedBox(width: 12),
                  _buildQuickAction(Icons.email_rounded, "Email", color: Colors.indigo),
                  const SizedBox(width: 12),
                  _buildQuickAction(Icons.map_rounded, "Directions", isPrimary: true),
                ],
              ),
            ),
          ),

          // Content Sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildVitalsSection(),
                _buildContactSection(),
                _buildAddressesSection(),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {bool isPrimary = false, Color? color}) {
    final bgColor = isPrimary ? AppColors.primary : Colors.white;
    final iconColor = isPrimary ? Colors.white : (color ?? AppColors.accent);

    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isPrimary ? Colors.white : AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Warehouse Vitals", [
          _buildInfoRow(Icons.pin_outlined, "Warehouse Code", _warehouse.code),
          _buildInfoRow(Icons.star_outline_rounded, "Type", _warehouse.isPrimary ? 'Primary' : 'Standard'),
          _buildInfoRow(Icons.info_outline_rounded, "Status", _warehouse.isActive ? 'Active' : 'Inactive'),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Contact Details", [
          if (_warehouse.mobiles.isEmpty && _warehouse.emails.isEmpty)
            const Text("No contact details added.", style: TextStyle(color: AppColors.textMuted, fontSize: 13))
          else ...[
            ..._warehouse.mobiles.map((m) => _buildContactRow(Icons.phone_android_rounded, m.contactTypeName ?? "Mobile", m.number)),
            if (_warehouse.mobiles.isNotEmpty && _warehouse.emails.isNotEmpty) const Divider(height: 32, thickness: 0.5),
            ..._warehouse.emails.map((e) => _buildContactRow(Icons.email_outlined, e.contactTypeName ?? "Email", e.email)),
          ]
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAddressesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Addresses", [
          if (_warehouse.addressList.isEmpty)
            const Text("No addresses found.", style: TextStyle(color: AppColors.textMuted, fontSize: 13))
          else
            ..._warehouse.addressList.map((wa) {
              final d = wa.addressDetails;
              if (d == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wa.addressDetails?.addressTypeName ?? "Address", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                          Text("${d.line1}, ${d.city}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
