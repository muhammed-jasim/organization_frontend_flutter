import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/employee_model.dart';
import '../../theme/app_theme.dart';
import '../services/employee_service.dart';
import '../../shared/models/location_models.dart';
import '../../shared/models/attachment_model.dart';
import 'employee_create_page.dart';

class EmployeeDetailPage extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeDetailPage({super.key, required this.employee});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  late EmployeeModel _employee;
  final EmployeeService _employeeService = EmployeeService();
  bool _isLoading = false;
  int _currentPhotoIndex = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _refreshEmployee();
  }

  Future<void> _refreshEmployee() async {
    setState(() => _isLoading = true);
    try {
      final updatedEmployee = await _employeeService.getEmployee(_employee.id);
      setState(() {
        _employee = updatedEmployee;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error refreshing employee: $e")),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      await _employeeService.uploadPhotos(_employee.id, [image]);
      await _refreshEmployee();
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeCreatePage(employee: _employee))).then((_) => _refreshEmployee());
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
                    itemCount: _employee.photos.length + 1,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      if (index == _employee.photos.length) {
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
                      
                      final photo = _employee.photos[index];
                      return Image.network(
                        photo.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: AppColors.background,
                          child: const Icon(Icons.person_rounded, size: 80, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                  if (_employee.photos.isNotEmpty)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_employee.photos.length + 1, (index) {
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

          // Employee Info Section (Styled as Card)
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
                                _employee.displayName, 
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 4),
                              Text("${_employee.jobRoleName ?? 'General Staff'} — ${_employee.employeeCode ?? 'No Code'}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_employee.isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            (_employee.isActive ? "ACTIVE" : "INACTIVE").toUpperCase(), 
                            style: TextStyle(color: _employee.isActive ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)
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

          // All Sections in One Scroll
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewSection(),
                _buildContactSection(),
                _buildAddressesSection(),
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
        _buildInfoCard("Employment Vitals", [
          _buildInfoRow(Icons.badge_outlined, "Employee Code", _employee.employeeCode ?? 'N/A'),
          _buildInfoRow(Icons.work_outline_rounded, "Job Role", _employee.jobRoleName ?? 'General Staff'),
          _buildInfoRow(Icons.payments_outlined, "Salary Expectation", "₹ ${_employee.expectedSalary}"),
          _buildInfoRow(Icons.info_outline_rounded, "Status", _employee.status.toUpperCase()),
        ]),
        const SizedBox(height: 24),
        _buildInfoCard("Attendance & Performance", [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem("22", "Present", Colors.teal),
              _StatItem("02", "Absent", AppColors.error),
              _StatItem("92%", "Rate", AppColors.accent),
            ],
          ),
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
          if (_employee.mobiles.isEmpty && _employee.emails.isEmpty)
            const Text("No contact details added.")
          else ...[
            ..._employee.mobiles.map((m) => _buildContactRow(Icons.phone_android_rounded, m.contactTypeName ?? "Mobile", m.number)),
            if (_employee.mobiles.isNotEmpty && _employee.emails.isNotEmpty) const Divider(height: 32, thickness: 0.5),
            ..._employee.emails.map((e) => _buildContactRow(Icons.email_outlined, e.contactTypeName ?? "Email", e.email)),
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
          if (_employee.addresses.isEmpty)
            const Text("No addresses found.")
          else
            ..._employee.addresses.map((addr) => Padding(
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
            )),
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
          if (_employee.attachments.isEmpty)
            const Text("No documents found.")
          else
            ..._employee.attachments.map((doc) => Container(
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

class _StatItem extends StatelessWidget {
  final String val;
  final String label;
  final Color color;

  const _StatItem(this.val, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}