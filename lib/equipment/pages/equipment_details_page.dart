import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../models/equipment_model.dart';
import '../services/equipment_service.dart';
import 'equipment_create_page.dart';

class EquipmentDetailPage extends StatefulWidget {
  final EquipmentModel equipment;

  const EquipmentDetailPage({super.key, required this.equipment});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  late EquipmentModel _equipment;
  final EquipmentService _equipmentService = EquipmentService();
  bool _isLoading = false;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _equipment = widget.equipment;
    _refreshEquipment();
  }

  Future<void> _refreshEquipment() async {
    setState(() => _isLoading = true);
    try {
      final updatedEquipment = await _equipmentService.getEquipment(_equipment.id);
      setState(() {
        _equipment = updatedEquipment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error refreshing equipment: $e")),
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
          // Immersive Header with Image
          SliverAppBar(
            expandedHeight: 280,
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EquipmentCreatePage(equipment: _equipment))).then((_) => _refreshEquipment());
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                   PageView.builder(
                    itemCount: _equipment.photos.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final photo = _equipment.photos[index];
                      return Image.network(
                        photo.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: AppColors.background,
                          child: const Icon(Icons.construction_rounded, size: 80, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                  if (_equipment.photos.isEmpty)
                    Container(
                      color: AppColors.background,
                      child: const Icon(Icons.construction_rounded, size: 80, color: AppColors.textMuted),
                    ),
                  if (_equipment.photos.length > 1)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_equipment.photos.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: _currentPhotoIndex == index ? 20 : 6,
                            decoration: BoxDecoration(
                              color: _currentPhotoIndex == index ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Equipment Info Section (Styled as Card)
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
                                _equipment.name, 
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 4),
                              Text("${_equipment.categoryDetail?.name ?? 'Equipment'} — ${_equipment.code}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_equipment.isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            (_equipment.isActive ? "ACTIVE" : "INACTIVE").toUpperCase(), 
                            style: TextStyle(color: _equipment.isActive ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)
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
                  _buildQuickAction(Icons.report_problem_outlined, "Report", color: Colors.orange),
                  const SizedBox(width: 12),
                  _buildQuickAction(Icons.build_circle_outlined, "Service", color: Colors.blue),
                  const SizedBox(width: 12),
                  _buildQuickAction(Icons.assignment_ind_outlined, "Assign", isPrimary: true),
                ],
              ),
            ),
          ),

          // All Sections in One Scroll
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewSection(),
                if (_equipment.rentalDetails != null) _buildRentalSection(),
                if (_equipment.notes != null && _equipment.notes!.isNotEmpty) _buildNotesSection(),
                _buildDocumentsSection(),
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

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Equipment Vitals", [
          _buildInfoRow(Icons.qr_code_scanner_rounded, "Equipment Code", _equipment.code),
          _buildInfoRow(Icons.category_outlined, "Category", _equipment.categoryDetail?.name ?? 'N/A'),
          _buildInfoRow(Icons.info_outline_rounded, "Status", _equipment.statusDetail?.name ?? 'N/A'),
          _buildInfoRow(Icons.assignment_ind_outlined, "Ownership", _equipment.ownershipTypeDetail?.name ?? 'N/A'),
          if (_equipment.purchaseDate != null)
            _buildInfoRow(Icons.calendar_today_outlined, "Purchase Date", _equipment.purchaseDate!),
          if (_equipment.purchaseCost != null)
            _buildInfoRow(Icons.payments_outlined, "Purchase Cost", "₹ ${_equipment.purchaseCost}"),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRentalSection() {
    final rental = _equipment.rentalDetails!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Rental Details", [
          _buildInfoRow(Icons.business_outlined, "Vendor", rental.vendorName ?? 'N/A'),
          _buildInfoRow(Icons.today_outlined, "Start Date", rental.rentalStartDate),
          _buildInfoRow(Icons.payments_outlined, "Rate/Day", "₹ ${rental.rentalRatePerDay}"),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("General Notes", [
          Text(_equipment.notes!, style: const TextStyle(height: 1.5, color: AppColors.textPrimary, fontSize: 14)),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard("Documents & Attachments", [
          if (_equipment.attachments.isEmpty)
            const Text("No documents found.")
          else
            ..._equipment.attachments.map((doc) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                onTap: () => _openAttachment(doc.fileUrl),
                dense: true,
                leading: const Icon(Icons.description_outlined, color: AppColors.accent),
                title: Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(doc.fileSize != null ? "${(doc.fileSize! / 1024).toStringAsFixed(1)} KB" : "Document", style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.download_rounded, color: AppColors.textMuted, size: 18),
              ),
            )),
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

  Future<void> _openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
