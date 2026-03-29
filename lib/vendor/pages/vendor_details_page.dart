import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/vendor_model.dart';
import '../services/vendor_service.dart';
import 'vendor_create_page.dart';

class VendorDetailsPage extends StatefulWidget {
  final VendorModel vendor;

  const VendorDetailsPage({super.key, required this.vendor});

  @override
  State<VendorDetailsPage> createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends State<VendorDetailsPage> {
  late VendorModel _vendor;
  final VendorService _service = VendorService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
    _refreshVendor();
  }

  Future<void> _refreshVendor() async {
    setState(() => _isLoading = true);
    try {
      final updatedVendor = await _service.getVendor(_vendor.id);
      setState(() {
        _vendor = updatedVendor;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error refreshing vendor: $e")),
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
                        MaterialPageRoute(builder: (context) => VendorCreatePage(vendor: _vendor))
                      ).then((_) => _refreshVendor());
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Center(
                  child: Icon(Icons.handshake_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),

          // Vendor Info Section
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
                                _vendor.name, 
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 4),
                              Text(_vendor.code, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_vendor.isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            (_vendor.isActive ? "ACTIVE" : "INACTIVE").toUpperCase(), 
                            style: TextStyle(color: _vendor.isActive ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)
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
                  _buildQuickAction(Icons.chat_bubble_rounded, "Message", isPrimary: true),
                ],
              ),
            ),
          ),

          // Content Sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Contact Details", [
          if (_vendor.mobiles.isEmpty && _vendor.emails.isEmpty)
            const Text("No contact details added.")
          else ...[
            ..._vendor.mobiles.map((m) => _buildContactRow(Icons.phone_android_rounded, m.contactTypeName ?? "Mobile", m.number)),
            if (_vendor.mobiles.isNotEmpty && _vendor.emails.isNotEmpty) const Divider(height: 32, thickness: 0.5),
            ..._vendor.emails.map((e) => _buildContactRow(Icons.email_outlined, e.contactTypeName ?? "Email", e.email)),
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
          if (_vendor.addressList.isEmpty)
            const Text("No addresses found.")
          else
            ..._vendor.addressList.map((wa) {
              final addr = wa.addressDetails;
              if (addr == null) return const SizedBox.shrink();
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
                          Text(addr.addressTypeName ?? "Address", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                          Text("${addr.line1}, ${addr.city}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
