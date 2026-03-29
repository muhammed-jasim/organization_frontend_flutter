import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import '../../shared/models/attachment_model.dart';
import '../../shared/models/location_models.dart';
import '../../shared/services/location_service.dart';
import '../../organization/models/organization_model.dart' show UserOrganizationRoleModel;
import '../../organization/services/organization_service.dart';

class EmployeeCreatePage extends StatefulWidget {
  final EmployeeModel? employee;

  const EmployeeCreatePage({super.key, this.employee});

  @override
  State<EmployeeCreatePage> createState() => _EmployeeCreatePageState();
}

class _EmployeeCreatePageState extends State<EmployeeCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeService _service = EmployeeService();
  final OrganizationService _orgService = OrganizationService();
  final LocationService _locationService = LocationService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _codeController;
  late TextEditingController _salaryController;

  final List<Map<String, dynamic>> _emailFields = [];
  final List<Map<String, dynamic>> _mobileFields = [];
  final List<Map<String, dynamic>> _addressFields = [];
  
  String? _selectedRoleId;
  bool _isActive = true;

  List<UserOrganizationRoleModel> _roles = [];
  List<ContactTypeModel> _contactTypes = [];
  List<CountryModel> _countries = [];
  List<AddressTypeModel> _addressTypes = [];
  
  List<XFile> _newPhotos = [];
  List<EmployeePhotoModel> _existingPhotos = [];
  List<PlatformFile> _newAttachments = [];
  List<AttachmentModel> _existingAttachments = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.employee?.firstName);
    _lastNameController = TextEditingController(text: widget.employee?.lastName);
    _codeController = TextEditingController(text: widget.employee?.employeeCode);
    _salaryController = TextEditingController(text: widget.employee?.expectedSalary.toString());

    if (widget.employee != null) {
      for (var m in widget.employee!.mobiles) {
        _addMobileField(initialValue: m.number, initialTypeId: m.contactTypeId);
      }
      for (var e in widget.employee!.emails) {
        _addEmailField(initialValue: e.email, initialTypeId: e.contactTypeId);
      }
      for (var a in widget.employee!.addresses) {
        _addAddressField(
          initialLine1: a.line1,
          initialLine2: a.line2,
          initialCity: a.city,
          initialPostalCode: a.postalCode,
          initialTypeId: a.addressTypeId,
          initialDistrictId: a.districtId,
          initialStateId: a.stateId,
          initialCountryId: a.countryId,
        );
      }
      _isActive = widget.employee!.isActive;
      _existingPhotos = widget.employee!.photos;
      _existingAttachments = widget.employee!.attachments;
    }

    if (_emailFields.isEmpty) _addEmailField();
    if (_mobileFields.isEmpty) _addMobileField();
    if (_addressFields.isEmpty) _addAddressField();

    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        _orgService.getRoles(),
        _locationService.getContactTypes(),
        _locationService.getCountries(),
        _locationService.getAddressTypes(),
        widget.employee == null ? _service.getNextCode() : Future.value(''),
      ]);

      setState(() {
        _roles = results[0] as List<UserOrganizationRoleModel>;
        _contactTypes = results[1] as List<ContactTypeModel>;
        _countries = results[2] as List<CountryModel>;
        _addressTypes = results[3] as List<AddressTypeModel>;
        if (widget.employee == null) _codeController.text = results[4] as String;
        
        if (widget.employee != null && widget.employee?.jobRoleName != null) {
          try {
            _selectedRoleId = _roles.firstWhere((r) => r.name == widget.employee!.jobRoleName).id;
          } catch (_) {}
        }

        for (var f in _emailFields) {
          f['type'] = _contactTypes.where((t) => t.id == f['typeId']).firstOrNull ?? (_contactTypes.isNotEmpty ? _contactTypes.first : null);
        }
        for (var f in _mobileFields) {
          f['type'] = _contactTypes.where((t) => t.id == f['typeId']).firstOrNull ?? (_contactTypes.isNotEmpty ? _contactTypes.first : null);
        }

        _isLoading = false;
      });

      for (var f in _addressFields) {
        f['selectedType'] = _addressTypes.where((t) => t.id == f['typeId']).firstOrNull;
        f['selectedCountry'] = _countries.where((c) => c.id == f['countryId']).firstOrNull;
        if (f['selectedCountry'] != null) {
          final states = await _locationService.getStates(f['selectedCountry'].id);
          f['states'] = states;
          f['selectedState'] = states.where((s) => s.id == f['stateId']).firstOrNull;
          if (f['selectedState'] != null) {
            final districts = await _locationService.getDistricts(f['selectedState'].id);
            f['districts'] = districts;
            f['selectedDistrict'] = districts.where((d) => d.id == f['districtId']).firstOrNull;
          }
        }
      }
      if (mounted) setState(() {});

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  void _addEmailField({String initialValue = '', String? initialTypeId}) {
    setState(() {
      _emailFields.add({
        'controller': TextEditingController(text: initialValue),
        'typeId': initialTypeId,
        'type': _contactTypes.where((t) => t.id == initialTypeId).firstOrNull,
      });
    });
  }

  void _addMobileField({String initialValue = '', String? initialTypeId}) {
    setState(() {
      _mobileFields.add({
        'controller': TextEditingController(text: initialValue),
        'typeId': initialTypeId,
        'type': _contactTypes.where((t) => t.id == initialTypeId).firstOrNull,
      });
    });
  }

  void _addAddressField({
    String initialLine1 = '',
    String initialLine2 = '',
    String initialCity = '',
    String initialPostalCode = '',
    String? initialTypeId,
    String? initialDistrictId,
    String? initialStateId,
    String? initialCountryId,
  }) {
    setState(() {
      _addressFields.add({
        'line1': TextEditingController(text: initialLine1),
        'line2': TextEditingController(text: initialLine2),
        'city': TextEditingController(text: initialCity),
        'postalCode': TextEditingController(text: initialPostalCode),
        'typeId': initialTypeId,
        'countryId': initialCountryId,
        'stateId': initialStateId,
        'districtId': initialDistrictId,
        'selectedType': null,
        'selectedCountry': null,
        'selectedState': null,
        'selectedDistrict': null,
        'states': <StateModel>[],
        'districts': <DistrictModel>[],
      });
    });
  }

  Future<void> _onAddressCountryChanged(int idx, CountryModel? country) async {
    setState(() {
      _addressFields[idx]['selectedCountry'] = country;
      _addressFields[idx]['selectedState'] = null;
      _addressFields[idx]['selectedDistrict'] = null;
      _addressFields[idx]['states'] = <StateModel>[];
      _addressFields[idx]['districts'] = <DistrictModel>[];
    });
    if (country != null) {
      final states = await _locationService.getStates(country.id);
      if (mounted) setState(() => _addressFields[idx]['states'] = states);
    }
  }

  Future<void> _onAddressStateChanged(int idx, StateModel? state) async {
    setState(() {
      _addressFields[idx]['selectedState'] = state;
      _addressFields[idx]['selectedDistrict'] = null;
      _addressFields[idx]['districts'] = <DistrictModel>[];
    });
    if (state != null) {
      final districts = await _locationService.getDistricts(state.id);
      if (mounted) setState(() => _addressFields[idx]['districts'] = districts);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a job role")));
      return;
    }
    setState(() => _isSaving = true);

    try {
      final emails = _emailFields.where((f) => f['controller'].text.isNotEmpty).map((f) => {
        'email': f['controller'].text.trim(),
        'contact_type': (f['type'] as ContactTypeModel?)?.id,
      }).toList();

      final mobiles = _mobileFields.where((f) => f['controller'].text.isNotEmpty).map((f) => {
        'number': f['controller'].text.trim(),
        'contact_type': (f['type'] as ContactTypeModel?)?.id,
      }).toList();

      final addresses = _addressFields.where((f) => f['line1'].text.isNotEmpty && f['selectedDistrict'] != null).map((f) => {
        'line_1': f['line1'].text.trim(),
        'line_2': f['line2'].text.trim(),
        'city': f['city'].text.trim(),
        'postal_code': f['postalCode'].text.trim(),
        'district': (f['selectedDistrict'] as DistrictModel).id,
        'address_type': (f['selectedType'] as AddressTypeModel?)?.id,
        'is_primary': f['is_primary'] ?? false,
      }).toList();

      final data = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'employee_code_input': _codeController.text,
        'job_role': _selectedRoleId,
        'expected_salary': _salaryController.text.isEmpty ? null : _salaryController.text,
        'is_active_input': _isActive,
        'email_input': emails,
        'mobile_input': mobiles,
        'address_input': addresses,
      };

      if (widget.employee == null) {
        final newEmp = await _service.createEmployee(data);
        if (_newPhotos.isNotEmpty) await _service.uploadPhotos(newEmp.id, _newPhotos);
        if (_newAttachments.isNotEmpty) await _service.uploadAttachments(newEmp.id, _newAttachments);
      } else {
        await _service.updateEmployee(widget.employee!.id, data);
        if (_newPhotos.isNotEmpty) await _service.uploadPhotos(widget.employee!.id, _newPhotos);
        if (_newAttachments.isNotEmpty) await _service.uploadAttachments(widget.employee!.id, _newAttachments);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Employee details saved!")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        title: Text(widget.employee == null ? "Create Employee" : "Edit Profile", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              _sectionTitle("Profile Photos"),
              _card([_buildPhotoPicker()]),

              const SizedBox(height: 32),
              _sectionTitle("Identity & Role"),
              _card([_buildIdentityFields()]),
              
              const SizedBox(height: 32),
              _sectionTitle("Contact Info"),
              _card([
                _emailSection(),
                const SizedBox(height: 24),
                _mobileSection(),
              ]),

              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _sectionTitle("Addresses"),
                TextButton.icon(onPressed: () => _addAddressField(), icon: const Icon(Icons.add_location_alt_rounded, size: 16), label: const Text("Add Address", style: TextStyle(fontSize: 12))),
              ]),
              _addressSection(),

              const SizedBox(height: 32),
              _sectionTitle("Financials"),
              _card([
                _label("EXPECTED SALARY (PER MONTH)"),
                _field(_salaryController, "0.00", keyboardType: TextInputType.number),
              ]),

              const SizedBox(height: 32),
              _sectionTitle("KYC & Documents"),
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
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(widget.employee == null ? "Create" : "Update", style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _emailSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_label("EMAILS"), TextButton.icon(onPressed: () => _addEmailField(), icon: const Icon(Icons.add, size: 16), label: const Text("Add", style: TextStyle(fontSize: 12)))]),
      ..._emailFields.asMap().entries.map((entry) {
        int idx = entry.key;
        var field = entry.value;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
          Expanded(flex: 2, child: _dropdown<ContactTypeModel>(value: field['type'], hint: "Type", items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (v) => setState(() => _emailFields[idx]['type'] = v))),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: _field(field['controller'], "email@example.com", keyboardType: TextInputType.emailAddress)),
          if (_emailFields.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _emailFields.removeAt(idx))),
        ]));
      }),
    ]);
  }

  Widget _mobileSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_label("MOBILES"), TextButton.icon(onPressed: () => _addMobileField(), icon: const Icon(Icons.add, size: 16), label: const Text("Add", style: TextStyle(fontSize: 12)))]),
      ..._mobileFields.asMap().entries.map((entry) {
        int idx = entry.key;
        var field = entry.value;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
          Expanded(flex: 2, child: _dropdown<ContactTypeModel>(value: field['type'], hint: "Type", items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (v) => setState(() => _mobileFields[idx]['type'] = v))),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: _field(field['controller'], "+91 ...", keyboardType: TextInputType.phone)),
          if (_mobileFields.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _mobileFields.removeAt(idx))),
        ]));
      }),
    ]);
  }

  Widget _addressSection() {
    return Column(children: _addressFields.asMap().entries.map((entry) {
      int idx = entry.key;
      var f = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _label("ADDRESS #${idx + 1}"),
            if (_addressFields.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _addressFields.removeAt(idx))),
          ]),
          const SizedBox(height: 8),
          _label("ADDRESS TYPE"),
          _dropdown<AddressTypeModel>(value: f['selectedType'], hint: "Select Type", items: _addressTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (v) => setState(() => f['selectedType'] = v)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("COUNTRY"), _dropdown<CountryModel>(value: f['selectedCountry'], hint: "Country", items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(), onChanged: (v) => _onAddressCountryChanged(idx, v))])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("STATE"), _dropdown<StateModel>(value: f['selectedState'], hint: "State", items: (f['states'] as List<StateModel>).map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: f['selectedCountry'] != null ? (v) => _onAddressStateChanged(idx, v) : null, enabled: f['selectedCountry'] != null)]))
          ]),
          const SizedBox(height: 16),
          _label("DISTRICT"),
          _dropdown<DistrictModel>(value: f['selectedDistrict'], hint: "District", items: (f['districts'] as List<DistrictModel>).map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(), onChanged: f['selectedState'] != null ? (v) => setState(() => f['selectedDistrict'] = v) : null, enabled: f['selectedState'] != null),
          const SizedBox(height: 16),
          _label("STREET ADDRESS (LINE 1)"),
          _field(f['line1'], "Building No., Street Name"),
          const SizedBox(height: 16),
          _label("ADDRESS LINE 2"),
          _field(f['line2'], "Suite, Floor, Landmark"),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("CITY"), _field(f['city'], "City")])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("POSTAL CODE"), _field(f['postalCode'], "Zip")])),
          ]),
        ]),
      );
    }).toList());
  }

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
    var image;
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

  Widget _buildIdentityFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("FIRST NAME *"), _field(_firstNameController, "e.g. Suresh", validator: (v) => v!.isEmpty ? "Req" : null)])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("LAST NAME"), _field(_lastNameController, "e.g. Kumar")])),
      ]),
      const SizedBox(height: 16),
      _label("JOB ROLE *"),
      _dropdown<String>(value: _selectedRoleId, hint: "Select Designation", items: _roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(), onChanged: (v) => setState(() => _selectedRoleId = v)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label("EMPLOYEE CODE *"), _field(_codeController, "EMP-000", validator: (v) => v!.isEmpty ? "Req" : null)])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label("STATUS"),
          Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_isActive ? "Active" : "Inactive", style: TextStyle(color: _isActive ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
            Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: AppColors.success),
          ])),
        ])),
      ]),
    ]);
  }

  Widget _buildAttachmentSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [
        if (_existingAttachments.isEmpty && _newAttachments.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Text("No documents uploaded yet.", style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
        ..._existingAttachments.map((att) => ListTile(
          onTap: () async => await launchUrl(Uri.parse(att.fileUrl)),
          leading: const Icon(Icons.description_outlined, color: AppColors.accent),
          title: Text(att.fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () async {
            await _service.deleteAttachment(att.id);
            setState(() => _existingAttachments.remove(att));
          }),
        )),
        ..._newAttachments.map((f) => ListTile(
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



  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.2)));

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? keyboardType, String? Function(String?)? validator}) => TextFormField(controller: ctrl, keyboardType: keyboardType, validator: validator, decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppColors.background.withValues(alpha: 0.3), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.1))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red))));

  Widget _dropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?>? onChanged, bool enabled = true}) => Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: enabled ? AppColors.background.withValues(alpha: 0.3) : AppColors.background.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1))), child: DropdownButtonHideUnderline(child: DropdownButton<T>(value: value, isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)), items: enabled ? items : null, onChanged: enabled ? onChanged : null, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary))));
}