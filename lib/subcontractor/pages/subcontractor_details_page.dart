import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/subcontractor_model.dart';
import '../services/subcontractor_service.dart';
import 'subcontractor_create_page.dart';

class SubcontractorDetailPage extends StatefulWidget {
  final SubcontractorModel subcontractor;

  const SubcontractorDetailPage({super.key, required this.subcontractor});

  @override
  State<SubcontractorDetailPage> createState() => _SubcontractorDetailPageState();
}

class _SubcontractorDetailPageState extends State<SubcontractorDetailPage> {
  late SubcontractorModel _subcontractor;
  final SubcontractorService _service = SubcontractorService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subcontractor = widget.subcontractor;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _service.getSubcontractor(_subcontractor.id);
      if (mounted) {
        setState(() {
          _subcontractor = updated;
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

  Future<void> _deleteSubcontractor() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Subcontractor"),
        content: Text("Are you sure you want to delete ${_subcontractor.name}?"),
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
        await _service.deleteSubcontractor(_subcontractor.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subcontractor deleted successfully")));
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
                        MaterialPageRoute(builder: (context) => SubcontractorCreatePage(subcontractor: _subcontractor))
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
                    onPressed: _deleteSubcontractor,
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
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_rounded, color: AppColors.accent, size: 64),
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
                                  _subcontractor.name, 
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 4),
                                if (_subcontractor.specialization.isNotEmpty)
                                  Text(_subcontractor.specialization, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _statusBadge(_subcontractor.isActive),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                // Quick Actions
                Row(
                  children: [
                    _quickActionTile(Icons.call_rounded, "Call", color: Colors.blue, onTap: () {}),
                    const SizedBox(width: 12),
                    _quickActionTile(Icons.email_rounded, "Email", color: Colors.indigo, onTap: () {}),
                    const SizedBox(width: 12),
                    _quickActionTile(Icons.chat_bubble_rounded, "Message", isPrimary: true, onTap: () {}),
                  ],
                ),

                const SizedBox(height: 24),

                // Info Sections
                _infoCard("Company Information", [
                   _infoRow(Icons.business_rounded, "Name", _subcontractor.name),
                   _infoRow(Icons.star_outline_rounded, "Specialization", _subcontractor.specialization.isEmpty ? "N/A" : _subcontractor.specialization),
                   _infoRow(Icons.info_outline_rounded, "Status", _subcontractor.isActive ? "Active" : "Inactive"),
                ]),

                const SizedBox(height: 24),

                _infoCard("Contact Details", [
                  if (_subcontractor.mobiles.isEmpty && _subcontractor.emails.isEmpty)
                    const Text("No contact details found.", style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                  else ...[
                    ..._subcontractor.mobiles.map((m) => _contactRow(Icons.phone_android_rounded, m.contactTypeName ?? "Mobile", m.number)),
                    if (_subcontractor.mobiles.isNotEmpty && _subcontractor.emails.isNotEmpty) const Divider(height: 32, thickness: 0.5),
                    ..._subcontractor.emails.map((e) => _contactRow(Icons.email_outlined, e.contactTypeName ?? "Email", e.email)),
                  ]
                ]),

                const SizedBox(height: 24),

                _infoCard("Addresses", [
                  if (_subcontractor.addresses.isEmpty)
                    const Text("No addresses found.", style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                  else
                    ..._subcontractor.addresses.map((wa) {
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
                                  Text(d.addressTypeName ?? "Address", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                                  Text("${d.line1}${d.line2.isNotEmpty ? ', ' + d.line2 : ''}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text("${d.city}, ${d.postalCode}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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

  Widget _quickActionTile(IconData icon, String label, {bool isPrimary = false, Color? color, required VoidCallback onTap}) {
    final bgColor = isPrimary ? AppColors.primary : Colors.white;
    final iconColor = isPrimary ? Colors.white : (color ?? AppColors.accent);
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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

  Widget _infoRow(IconData icon, String label, String value) {
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

  Widget _contactRow(IconData icon, String label, String value) {
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
