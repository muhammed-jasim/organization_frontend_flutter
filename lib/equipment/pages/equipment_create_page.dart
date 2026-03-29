import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../models/equipment_model.dart';
import '../services/equipment_service.dart';
import '../../shared/models/attachment_model.dart';
import '../../vendor/models/vendor_model.dart';
import '../../vendor/services/vendor_service.dart';

class EquipmentCreatePage extends StatefulWidget {
  final EquipmentModel? equipment;

  const EquipmentCreatePage({super.key, this.equipment});

  @override
  State<EquipmentCreatePage> createState() => _EquipmentCreatePageState();
}

class _EquipmentCreatePageState extends State<EquipmentCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final EquipmentService _service = EquipmentService();
  final VendorService _vendorService = VendorService();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _purchaseDateController;
  late TextEditingController _purchaseCostController;
  
  // Rental controllers
  late TextEditingController _rentalStartDateController;
  late TextEditingController _rentalEndDateController;
  late TextEditingController _rentalRateController;
  late TextEditingController _securityDepositController;
  late TextEditingController _notesController;

  String? _selectedCategoryId;
  String? _selectedStatusId;
  String? _selectedOwnershipTypeId;
  String? _selectedVendorId;
  bool _isActive = true;

  List<EquipmentCategoryModel> _categories = [];
  List<EquipmentStatusModel> _statuses = [];
  List<EquipmentOwnershipTypeModel> _ownershipTypes = [];
  List<VendorModel> _vendors = [];
  List<XFile> _newPhotos = [];
  List<EquipmentPhotoModel> _existingPhotos = [];
  List<PlatformFile> _newAttachments = [];
  List<AttachmentModel> _existingAttachments = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment?.name);
    _codeController = TextEditingController(text: widget.equipment?.code);
    _purchaseDateController = TextEditingController(text: widget.equipment?.purchaseDate);
    _purchaseCostController = TextEditingController(text: widget.equipment?.purchaseCost);
    _notesController = TextEditingController(text: widget.equipment?.notes);
    
    _rentalStartDateController = TextEditingController(text: widget.equipment?.rentalDetails?.rentalStartDate);
    _rentalEndDateController = TextEditingController(text: widget.equipment?.rentalDetails?.rentalEndDate);
    _rentalRateController = TextEditingController(text: widget.equipment?.rentalDetails?.rentalRatePerDay);
    _securityDepositController = TextEditingController(text: widget.equipment?.rentalDetails?.securityDeposit);

    _selectedCategoryId = widget.equipment?.categoryId;
    _selectedStatusId = widget.equipment?.statusId;
    _selectedOwnershipTypeId = widget.equipment?.ownershipTypeId;
    _selectedVendorId = widget.equipment?.rentalDetails?.vendorId;
    _existingPhotos = widget.equipment?.photos ?? [];
    _existingAttachments = widget.equipment?.attachments ?? [];
    _isActive = widget.equipment?.isActive ?? true;

    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait<dynamic>([
        _service.getCategories(),
        _service.getStatuses(),
        _service.getOwnershipTypes(),
        _vendorService.getVendors(),
        widget.equipment == null ? _service.getNextCode() : Future.value(''),
      ]);

      setState(() {
        _categories = List<EquipmentCategoryModel>.from(results[0]);
        _statuses = List<EquipmentStatusModel>.from(results[1]);
        _ownershipTypes = List<EquipmentOwnershipTypeModel>.from(results[2]);
        _vendors = List<VendorModel>.from(results[3]);
        if (widget.equipment == null) _codeController.text = results[4] as String;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading data: $e")));
      }
      setState(() => _isLoading = false);
    }
  }

  bool get _isOwned => _ownershipTypes.any((t) => t.id == _selectedOwnershipTypeId && t.code.toLowerCase() == 'owned');
  bool get _isRentalOrLeased => _ownershipTypes.any((t) => t.id == _selectedOwnershipTypeId && t.code.toLowerCase() != 'owned');

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _newPhotos.addAll(images));
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => _newAttachments.addAll(result.files));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text,
        'code': _codeController.text,
        'category': _selectedCategoryId,
        'status': _selectedStatusId,
        'ownership_type': _selectedOwnershipTypeId,
        'notes': _notesController.text,
        'purchase_date': _purchaseDateController.text.isEmpty ? null : _purchaseDateController.text,
        'is_active': _isActive,
      };

      if (_isOwned) {
        data['purchase_cost'] = _purchaseCostController.text.isEmpty ? null : _purchaseCostController.text;
      } else if (_isRentalOrLeased) {
        data['rental_details'] = {
          'vendor': _selectedVendorId,
          'rental_start_date': _rentalStartDateController.text,
          'rental_end_date': _rentalEndDateController.text.isEmpty ? null : _rentalEndDateController.text,
          'rental_rate_per_day': _rentalRateController.text,
          'security_deposit': _securityDepositController.text.isEmpty ? null : _securityDepositController.text,
        };
      }

      if (widget.equipment == null) {
        final newEquipment = await _service.createEquipment(data);
        if (_newPhotos.isNotEmpty) {
          await _service.uploadPhotos(newEquipment.id, _newPhotos);
        }
        if (_newAttachments.isNotEmpty) {
          await _service.uploadAttachments(newEquipment.id, _newAttachments);
        }
      } else {
        await _service.updateEquipment(widget.equipment!.id, data);
        if (_newPhotos.isNotEmpty) {
          await _service.uploadPhotos(widget.equipment!.id, _newPhotos);
        }
        if (_newAttachments.isNotEmpty) {
          await _service.uploadAttachments(widget.equipment!.id, _newAttachments);
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _openAttachment(String url) async {

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open attachment")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        title: Text(widget.equipment == null ? "Register Gear" : "Edit Equipment", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isSaving ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Photos & Media"),
              _card([_buildPhotoPicker()]),

              const SizedBox(height: 32),
              _sectionTitle("Basic Information"),
              _card([
                _label("EQUIPMENT NAME *"),
                _field(_nameController, "e.g., Concrete Mixer", validator: (v) => v == null || v.isEmpty ? "Required" : null),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("ASSET CODE *"),
                    _field(_codeController, "e.g., EQ-001", validator: (v) => v == null || v.isEmpty ? "Required" : null),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("STATUS"),
                    Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_isActive ? "Active" : "Inactive", style: TextStyle(color: _isActive ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
                      Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: AppColors.success),
                    ])),
                  ])),
                ]),
                const SizedBox(height: 16),
                _label("CATEGORY *"),
                _dropdown<String>(value: _selectedCategoryId, hint: "Select Category", items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(), onChanged: (val) => setState(() => _selectedCategoryId = val)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("EQUIPMENT STATUS *"),
                    _dropdown<String>(value: _selectedStatusId, hint: "Select Status", items: _statuses.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(), onChanged: (val) => setState(() => _selectedStatusId = val)),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("OWNERSHIP *"),
                    _dropdown<String>(value: _selectedOwnershipTypeId, hint: "Ownership", items: _ownershipTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(), onChanged: (val) => setState(() => _selectedOwnershipTypeId = val)),
                  ])),
                ]),
                const SizedBox(height: 16),
                _label("GENERAL NOTES"),
                _field(_notesController, "Describe this equipment...", maxLines: 3),
              ]),

              if (_selectedOwnershipTypeId != null) ...[
                if (_isOwned) ...[
                  const SizedBox(height: 32),
                  _sectionTitle("Purchase Details"),
                  _card([
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("PURCHASE DATE"),
                        _field(_purchaseDateController, "Select Date", readOnly: true, onTap: () => _selectDate(context, _purchaseDateController)),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("PURCHASE COST"),
                        _field(_purchaseCostController, "0.00", keyboardType: TextInputType.number),
                      ])),
                    ]),
                  ]),
                ] else if (_isRentalOrLeased) ...[
                  const SizedBox(height: 32),
                  _sectionTitle("Rental Information"),
                  _card([
                    _label("VENDOR *"),
                    _dropdown<String>(value: _selectedVendorId, hint: "Select Vendor", items: _vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(), onChanged: (val) => setState(() => _selectedVendorId = val)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("RENTAL START *"),
                        _field(_rentalStartDateController, "Select Date", readOnly: true, onTap: () => _selectDate(context, _rentalStartDateController), validator: (v) => v == null || v.isEmpty ? "Required" : null),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("DAILY RATE *"),
                        _field(_rentalRateController, "0.00", keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? "Required" : null),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("RENTAL END"),
                        _field(_rentalEndDateController, "Select Date", readOnly: true, onTap: () => _selectDate(context, _rentalEndDateController)),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label("SECURITY DEPOSIT"),
                        _field(_securityDepositController, "0.00", keyboardType: TextInputType.number),
                      ])),
                    ]),
                  ]),
                ],
              ],

              const SizedBox(height: 32),
              _sectionTitle("Documents & Attachments"),
              _buildAttachmentSection(),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(widget.equipment == null ? "Register Gear" : "Update", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 1.2)));

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _buildPhotoPicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          InkWell(
            onTap: _pickImages,
            child: Container(
              width: 110, height: 120, margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1), width: 1.5)),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined, color: AppColors.accent, size: 28),
                SizedBox(height: 8),
                Text("Add Photo", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))
              ]),
            ),
          ),
          ..._existingPhotos.map((photo) => _mediaThumbnail(photo.imageUrl, () async {
            await _service.deletePhoto(photo.id);
            setState(() => _existingPhotos.removeWhere((p) => p.id == photo.id));
          })),
          ..._newPhotos.map((file) => _mediaThumbnail(file.path, () => setState(() => _newPhotos.remove(file)))),
        ],
      ),
    );
  }

  Widget _mediaThumbnail(String path, VoidCallback onDelete) {
    return Container(
      width: 110, margin: const EdgeInsets.only(right: 12),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(path, width: 110, height: 120, fit: BoxFit.cover)),
        Positioned(right: 6, top: 6, child: InkWell(onTap: onDelete, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white)))),
      ]),
    );
  }

  Widget _buildAttachmentSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [
        if (_existingAttachments.isEmpty && _newAttachments.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Text("No documents attached yet.", style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
        ..._existingAttachments.map((att) => ListTile(
          onTap: () => _openAttachment(att.fileUrl),
          leading: const Icon(Icons.description_outlined, color: AppColors.accent),
          title: Text(att.fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () async {
            await _service.deleteAttachment(att.id);
            setState(() => _existingAttachments.removeWhere((a) => a.id == att.id));
          }),
        )),
        ..._newAttachments.map((f) => ListTile(
          leading: const Icon(Icons.upload_file, color: AppColors.accent),
          title: Text(f.name, style: const TextStyle(fontSize: 13)),
          trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => setState(() => _newAttachments.remove(f))),
        )),
        const Divider(height: 1),
        InkWell(
          onTap: _pickFiles,
          child: const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: AppColors.accent, size: 20), SizedBox(width: 8), Text("Attach Bills or Manuals", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))])),
        ),
      ]),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.2)));

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1, bool readOnly = false, VoidCallback? onTap}) => TextFormField(controller: ctrl, keyboardType: keyboardType, validator: validator, maxLines: maxLines, readOnly: readOnly, onTap: onTap, decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppColors.background.withValues(alpha: 0.3), suffixIcon: onTap != null ? const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary) : null, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.1))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red))));

  Widget _dropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?>? onChanged, bool enabled = true}) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: enabled ? AppColors.background.withValues(alpha: 0.3) : AppColors.background.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))), child: DropdownButtonHideUnderline(child: DropdownButton<T>(value: value, isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)), items: enabled ? items : null, onChanged: enabled ? onChanged : null, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary))));
}