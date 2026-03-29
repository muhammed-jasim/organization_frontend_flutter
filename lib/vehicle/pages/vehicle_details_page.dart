import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/vehicle_models.dart';
import '../../theme/app_theme.dart';
import '../services/vehicle_service.dart';
import 'vehicle_create_page.dart';

class VehicleDetailPage extends StatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  late VehicleModel _vehicle;
  final VehicleService _service = VehicleService();
  bool _isLoading = false;
  int _currentPhotoIndex = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _refreshVehicle();
  }

  Future<void> _refreshVehicle() async {
    setState(() => _isLoading = true);
    try {
      final updatedVehicle = await _service.getVehicle(_vehicle.id);
      setState(() {
        _vehicle = updatedVehicle;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error refreshing vehicle: $e")),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      await _service.uploadPhotos(_vehicle.id, [image]);
      await _refreshVehicle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded successfully.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleCreatePage(vehicle: _vehicle))).then((_) => _refreshVehicle());
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
                    itemCount: _vehicle.photos.length + 1,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      if (index == _vehicle.photos.length) {
                        return GestureDetector(
                          onTap: _pickAndUploadPhoto,
                          child: Container(
                            color: AppColors.background,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 48, color: AppColors.accent),
                                SizedBox(height: 16),
                                Text("Add Photo", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final photo = _vehicle.photos[index];
                      return Image.network(
                        photo.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: AppColors.background,
                          child: const Icon(Icons.directions_car_rounded, size: 80, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                  if (_vehicle.photos.isNotEmpty)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_vehicle.photos.length + 1, (index) {
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
                              Text("${_vehicle.make} ${_vehicle.model}", style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Plate: ${_vehicle.licensePlate} — ${_vehicle.year ?? 'N/A'}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_vehicle.isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            (_vehicle.isActive ? "ACTIVE" : "INACTIVE").toUpperCase(), 
                            style: TextStyle(color: _vehicle.isActive ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Action Bar (if contact exists)
          if (_vehicle.contactInfo != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    _buildQuickAction(Icons.call_rounded, "Call", color: Colors.blue, value: _vehicle.contactInfo!.phoneNumber),
                    const SizedBox(width: 12),
                    _buildQuickAction(Icons.email_rounded, "Email", color: Colors.indigo, value: _vehicle.contactInfo!.email),
                    const SizedBox(width: 12),
                    _buildQuickAction(Icons.chat_bubble_rounded, "Message", isPrimary: true, value: _vehicle.contactInfo!.phoneNumber),
                  ],
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewSection(),
                if (_vehicle.contactInfo != null) _buildContactSection(),
                if (_vehicle.paymentOption != null) _buildPaymentSection(),
                _buildDocumentsSection(),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return _buildInfoCard("Vehicle Vitals", [
      _buildInfoRow(Icons.category_outlined, "Type", _vehicle.vehicleType),
      _buildInfoRow(Icons.calendar_today_outlined, "Year", _vehicle.year?.toString() ?? 'N/A'),
      _buildInfoRow(Icons.fingerprint_outlined, "VIN", _vehicle.vin ?? 'N/A'),
      _buildInfoRow(Icons.person_pin_outlined, "Assigned To", _vehicle.assignedTo ?? 'Unassigned'),
    ]);
  }

  Widget _buildContactSection() {
    final contact = _vehicle.contactInfo!;
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildInfoCard("Contact Person", [
          _buildContactRow(Icons.person_outline, contact.contactType ?? "Owner", contact.name),
          _buildContactRow(Icons.phone_outlined, "Phone", contact.phoneNumber),
          if (contact.email != null) _buildContactRow(Icons.email_outlined, "Email", contact.email!),
          _buildContactRow(Icons.location_on_outlined, "Address", contact.address),
        ]),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final payment = _vehicle.paymentOption!;
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildInfoCard("Payment Details", [
          _buildContactRow(Icons.payments_outlined, "Rate", "${payment.rate} ${payment.currency}"),
          _buildContactRow(Icons.layers_outlined, "Mode", payment.paymentType),
          _buildContactRow(Icons.description_outlined, "Terms", payment.terms),
        ]),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildInfoCard("Documents & Attachments", [
          if (_vehicle.attachments.isEmpty)
            const Text("No documents found.", style: TextStyle(color: AppColors.textMuted, fontSize: 13))
          else
            ..._vehicle.attachments.map((doc) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.description_outlined, color: AppColors.accent),
                title: Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text("${((doc.fileSize ?? 0) / 1024).toStringAsFixed(2)} KB", style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.download_rounded, color: AppColors.textMuted, size: 18),
              ),
            )),
        ]),
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

  Widget _buildQuickAction(IconData icon, String label, {bool isPrimary = false, Color? color, String? value}) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
