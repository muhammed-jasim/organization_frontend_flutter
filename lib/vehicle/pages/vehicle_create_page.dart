import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../models/vehicle_models.dart';
import '../services/vehicle_service.dart';
import '../../auth/services/token_manager.dart';
import '../../shared/models/attachment_model.dart';

class VehicleCreatePage extends StatefulWidget {
  final VehicleModel? vehicle;
  const VehicleCreatePage({super.key, this.vehicle});

  @override
  State<VehicleCreatePage> createState() => _VehicleCreatePageState();
}

class _VehicleCreatePageState extends State<VehicleCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vinController = TextEditingController();
  final _yearController = TextEditingController();
  final _vehicleTypeController = TextEditingController();

  // Contact info controllers
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactAddressController = TextEditingController();
  String? _selectedContactType;

  // Payment option controllers
  final _paymentRateController = TextEditingController();
  final _currencyController = TextEditingController(text: 'INR');
  final _paymentTermsController = TextEditingController();
  String? _selectedPaymentType;

  bool _isActive = true;
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _contactTypes = [];
  List<Map<String, dynamic>> _paymentTypes = [];

  List<XFile> _newPhotos = [];
  List<VehiclePhotoModel> _existingPhotos = [];
  List<PlatformFile> _newAttachments = [];
  List<AttachmentModel> _existingAttachments = [];

  final VehicleService _service = VehicleService();

  @override
  void initState() {
    super.initState();
    _fetchTypes();
    if (widget.vehicle != null) {
      _makeController.text = widget.vehicle!.make;
      _modelController.text = widget.vehicle!.model;
      _licensePlateController.text = widget.vehicle!.licensePlate;
      _vinController.text = widget.vehicle!.vin ?? '';
      _yearController.text = widget.vehicle!.year?.toString() ?? '';
      _vehicleTypeController.text = widget.vehicle!.vehicleType;
      _isActive = widget.vehicle!.isActive;
      _existingPhotos = widget.vehicle!.photos;
      _existingAttachments = widget.vehicle!.attachments;

      if (widget.vehicle!.contactInfo != null) {
        _contactNameController.text = widget.vehicle!.contactInfo!.name;
        _contactPhoneController.text = widget.vehicle!.contactInfo!.phoneNumber;
        _contactEmailController.text = widget.vehicle!.contactInfo!.email ?? '';
        _contactAddressController.text = widget.vehicle!.contactInfo!.address;
        _selectedContactType = widget.vehicle!.contactInfo!.contactType;
      }

      if (widget.vehicle!.paymentOption != null) {
        _paymentRateController.text = widget.vehicle!.paymentOption!.rate.toString();
        _currencyController.text = widget.vehicle!.paymentOption!.currency;
        _paymentTermsController.text = widget.vehicle!.paymentOption!.terms;
        _selectedPaymentType = widget.vehicle!.paymentOption!.paymentType;
      }
    }
  }

  Future<void> _fetchTypes() async {
    final orgId = await TokenManager.getOrganizationId();
    final formData = await _service.getVehicleFormData(organizationId: orgId);
    if (mounted) {
      setState(() {
        _contactTypes = List<Map<String, dynamic>>.from(formData['contact_types'] ?? []);
        _paymentTypes = List<Map<String, dynamic>>.from(formData['payment_types'] ?? []);
        
        if (_selectedContactType == null && _contactTypes.isNotEmpty) {
          _selectedContactType = _contactTypes.first['id']?.toString();
        }
        if (_selectedPaymentType == null && _paymentTypes.isNotEmpty) {
          _selectedPaymentType = _paymentTypes.first['id']?.toString();
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final orgIdRef = await TokenManager.getOrganizationId();
      final data = {
        "organization": widget.vehicle?.organization ?? orgIdRef,
        "make": _makeController.text.trim(),
        "model": _modelController.text.trim(),
        "license_plate": _licensePlateController.text.trim().toUpperCase(),
        "vin": _vinController.text.isEmpty ? null : _vinController.text.trim().toUpperCase(),
        "year": int.tryParse(_yearController.text),
        "vehicle_type": _vehicleTypeController.text.trim(),
        "is_active": _isActive,
        "contact_info": {
          "name": _contactNameController.text.trim(),
          "phone_number": _contactPhoneController.text.trim(),
          "email": _contactEmailController.text.isEmpty ? null : _contactEmailController.text.trim(),
          "address": _contactAddressController.text.trim(),
          "contact_type": _selectedContactType,
        },
        "payment_option": {
          "rate": _paymentRateController.text.trim(),
          "currency": _currencyController.text.trim(),
          "terms": _paymentTermsController.text.trim(),
          "payment_type": _selectedPaymentType,
        }
      };

      VehicleModel v;
      if (widget.vehicle != null) {
        v = await _service.updateVehicle(widget.vehicle!.id, data);
      } else {
        v = await _service.createVehicle(data);
      }

      if (_newPhotos.isNotEmpty) await _service.uploadPhotos(v.id, _newPhotos);
      if (_newAttachments.isNotEmpty) await _service.uploadAttachments(v.id, _newAttachments);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.vehicle != null ? "Vehicle updated successfully!" : "Vehicle registered successfully!")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _yearController.dispose();
    _vehicleTypeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _contactAddressController.dispose();
    _paymentRateController.dispose();
    _currencyController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    bool isEditing = widget.vehicle != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        title: Text(isEditing ? "Edit Vehicle" : "Create Vehicle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              _sectionTitle("Vehicle Photos"),
              _card([_buildPhotoPicker()]),

              const SizedBox(height: 32),
              _sectionTitle("Core Information"),
              _card([
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("MAKE *"), _field(_makeController, "e.g. Ford", validator: (v) => v!.isEmpty ? "Required" : null)])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("MODEL *"), _field(_modelController, "e.g. F-150", validator: (v) => v!.isEmpty ? "Required" : null)])),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("YEAR"), _field(_yearController, "e.g. 2024", keyboardType: TextInputType.number)])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("TYPE"), _field(_vehicleTypeController, "e.g. Truck")])),
                ]),
              ]),
              
              const SizedBox(height: 32),
              _sectionTitle("Identification"),
              _card([
                _label("LICENSE PLATE *"),
                _field(_licensePlateController, "123-ABC", validator: (v) => v!.isEmpty ? "Required" : null),
                const SizedBox(height: 16),
                _label("VIN (OPTIONAL)"),
                _field(_vinController, "17-character ID"),
                const SizedBox(height: 16),
                _label("STATUS"),
                Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_isActive ? "Active" : "Inactive", style: TextStyle(color: _isActive ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
                  Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: AppColors.success),
                ])),
              ]),

              const SizedBox(height: 32),
              _sectionTitle("Contact Info"),
              _card([
                _label("CONTACT NAME *"),
                _field(_contactNameController, "e.g. Primary Owner", validator: (v) => v!.isEmpty ? "Required" : null),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("CONTACT TYPE"), _dropdown<String>(value: _selectedContactType, hint: "Type", items: _contactTypes.map((t) => DropdownMenuItem(value: t['id']?.toString(), child: Text(t['name']))).toList(), onChanged: (v) => setState(() => _selectedContactType = v))])),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("PHONE *"), _field(_contactPhoneController, "+91...", keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? "Required" : null)])),
                ]),
                const SizedBox(height: 16),
                _label("EMAIL (OPTIONAL)"),
                _field(_contactEmailController, "owner@example.com", keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _label("ADDRESS *"),
                _field(_contactAddressController, "Full address", validator: (v) => v!.isEmpty ? "Required" : null),
              ]),

              const SizedBox(height: 32),
              _sectionTitle("Payment & Rates"),
              _card([
                Row(children: [
                    Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("CURRENCY"), _field(_currencyController, "INR")])),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("RATE *"), _field(_paymentRateController, "0.00", keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? "Required" : null)])),
                ]),
                const SizedBox(height: 16),
                _label("FREQUENCY"),
                _dropdown<String>(value: _selectedPaymentType, hint: "Select Frequency", items: _paymentTypes.map((t) => DropdownMenuItem(value: t['id']?.toString(), child: Text(t['name']))).toList(), onChanged: (v) => setState(() => _selectedPaymentType = v)),
                const SizedBox(height: 16),
                _label("TERMS"),
                _field(_paymentTermsController, "e.g. Daily rental, Net 30"),
              ]),

              const SizedBox(height: 32),
              _sectionTitle("Documents & Attachments"),
              _buildAttachmentSection(),

              const SizedBox(height: 32),
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
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(isEditing ? "Update" : "Create", style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.2)));

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? keyboardType, String? Function(String?)? validator}) => TextFormField(controller: ctrl, keyboardType: keyboardType, validator: validator, decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppColors.background.withValues(alpha: 0.3), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.1))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red))));

  Widget _dropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?>? onChanged, bool enabled = true}) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: enabled ? AppColors.background.withValues(alpha: 0.3) : AppColors.background.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))), child: DropdownButtonHideUnderline(child: DropdownButton<T>(value: value, isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)), items: enabled ? items : null, onChanged: enabled ? onChanged : null, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary))));

  Widget _buildPhotoPicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          InkWell(
            onTap: () async {
              final picker = ImagePicker();
              final selection = await picker.pickMultiImage();
              if (selection.isNotEmpty) setState(() => _newPhotos.addAll(selection));
            },
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
            setState(() => _existingPhotos.remove(photo));
          })),
          ..._newPhotos.map((file) => _mediaThumbnail(file.path, () => setState(() => _newPhotos.remove(file)))),
        ],
      ),
    );
  }

  Widget _mediaThumbnail(String path, VoidCallback onDelete) {
    Widget image;
    if (path.startsWith('http')) {
      image = Image.network(path, width: 110, height: 120, fit: BoxFit.cover);
    } else {
      image = Image.file(File(path), width: 110, height: 120, fit: BoxFit.cover);
    }
    return Container(
      width: 110, margin: const EdgeInsets.only(right: 12),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(20), child: image),
        Positioned(right: 6, top: 6, child: InkWell(onTap: onDelete, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white)))),
      ]),
    );
  }

  Widget _buildAttachmentSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [
        if (_existingAttachments.isEmpty && _newAttachments.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Text("No documents uploaded yet.", style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
        ..._existingAttachments.map((att) => ListTile(
          dense: true,
          leading: const Icon(Icons.description_outlined, color: AppColors.accent),
          title: Text(att.fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () async {
            await _service.deleteAttachment(att.id);
            setState(() => _existingAttachments.remove(att));
          }),
        )),
        ..._newAttachments.map((f) => ListTile(
          dense: true,
          leading: const Icon(Icons.upload_file, color: AppColors.accent),
          title: Text(f.name, style: const TextStyle(fontSize: 13)),
          trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => setState(() => _newAttachments.remove(f))),
        )),
        const Divider(height: 1),
        InkWell(
          onTap: () async {
            final res = await FilePicker.platform.pickFiles(allowMultiple: true);
            if (res != null) setState(() => _newAttachments.addAll(res.files));
          },
          child: const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: AppColors.accent, size: 20), SizedBox(width: 8), Text("Upload Documents", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))])),
        ),
      ]),
    );
  }
}
