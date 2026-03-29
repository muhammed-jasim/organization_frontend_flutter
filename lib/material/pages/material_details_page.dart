import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/material_models.dart';
import '../services/material_service.dart';
import 'material_create_page.dart';

class MaterialDetailPage extends StatefulWidget {
  final MaterialModel material;

  const MaterialDetailPage({super.key, required this.material});

  @override
  State<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends State<MaterialDetailPage> {
  late MaterialModel _material;
  final MaterialService _service = MaterialService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _material = widget.material;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _service.getMaterial(_material.id);
      if (mounted) {
        setState(() {
          _material = updated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error refreshing data: $e")),
        );
      }
    }
  }

  Future<void> _deleteMaterial() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Material"),
        content: Text("Are you sure you want to delete ${_material.name}?"),
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
        await _service.deleteMaterial(_material.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Material deleted successfully")));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
        }
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
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppColors.textPrimary, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => MaterialCreatePage(material: _material))
                      ).then((_) => _refreshData());
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    onPressed: _deleteMaterial,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.05),
                      AppColors.background,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.layers_rounded, color: AppColors.primary, size: 64),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title and Status Card
                Container(
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
                                  _material.name, 
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 4),
                                Text("${_material.code} • ${_material.unit}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _statusBadge(_material.isActive),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Info Sections
                _infoCard("Material Overview", [
                   _infoRow(Icons.layers_rounded, "Name", _material.name),
                   _infoRow(Icons.qr_code_rounded, "Code", _material.code),
                   _infoRow(Icons.straighten_rounded, "Unit", _material.unit),
                   _infoRow(Icons.description_outlined, "Description", _material.description.isEmpty ? "No description" : _material.description, isDescription: true),
                ]),

                const SizedBox(height: 24),

                _infoCard("Pricing & Category", [
                   _infoRow(Icons.payments_outlined, "Base Price", "${_material.basePrice.toStringAsFixed(2)}"),
                   _infoRow(Icons.category_outlined, "Category ID", _material.category?.toString() ?? "None"),
                ]),

                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isActive) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1), 
      borderRadius: BorderRadius.circular(10)
    ),
    child: Text(
      (isActive ? "ACTIVE" : "INACTIVE").toUpperCase(), 
      style: TextStyle(color: isActive ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)
    ),
  );

  Widget _infoCard(String title, List<Widget> children) {
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

  Widget _infoRow(IconData icon, String label, String value, {bool isDescription = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: isDescription 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          )
        : Row(
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
}
